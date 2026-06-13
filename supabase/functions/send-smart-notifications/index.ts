import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import { create } from "https://deno.land/x/djwt@v3.0.1/mod.ts";

console.log("send-smart-notifications function is initialized!");

// Yardımcı: Google Service Account ile FCM v1 API için access token üretimi
async function getAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  const tokenUrl = 'https://oauth2.googleapis.com/token';
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: tokenUrl,
    exp: Math.floor(Date.now() / 1000) + 3600,
    iat: Math.floor(Date.now() / 1000),
  };
  
  // Private Key formatı düzeltme
  const formattedKey = privateKey.replace(/\\n/g, '\n');
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = formattedKey.substring(
    formattedKey.indexOf(pemHeader) + pemHeader.length,
    formattedKey.indexOf(pemFooter)
  ).replace(/\s/g, '');

  const binaryDerString = atob(pemContents);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const jwt = await create(header, payload, key);

  const response = await fetch(tokenUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Failed to generate access token: ${data.error_description}`);
  }
  return data.access_token;
}

serve(async (req: Request) => {
  // Sadece POST desteklenir (cron job genelde POST atar)
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  try {
    // 1. Supabase Client başlat
    // Service Role Key kullanmalıyız çünkü FCM tokenlarını ve diğer kullanıcı verilerini güvenlik kurallarını atlayarak okumalı
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Supabase ortam değişkenleri eksik. (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. Aktif FCM tokenı olan kullanıcıları bul
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('user_fcm_tokens')
      .select('user_id, token, platform')
      .eq('is_active', true);

    if (fcmError) throw fcmError;
    if (!fcmTokens || fcmTokens.length === 0) {
      return new Response(JSON.stringify({ message: "Aktif FCM token bulunamadı." }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Tokenları user_id bazında grupla (bir kullanıcının birden fazla cihazı olabilir)
    const usersMap = new Map<string, any[]>();
    for (const item of fcmTokens) {
      const arr = usersMap.get(item.user_id) || [];
      arr.push(item);
      usersMap.set(item.user_id, arr);
    }

    const todayStr = new Date().toISOString().split('T')[0];
    const now = new Date();
    const currentHour = now.getHours();

    const results = [];

    // Firebase Secrets (Supabase Dashboard üzerinden tanımlanmalı)
    const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID') || '';
    const firebaseClientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL') || '';
    const firebasePrivateKey = Deno.env.get('FIREBASE_PRIVATE_KEY') || '';
    
    let fcmAccessToken = '';
    if (firebaseProjectId && firebaseClientEmail && firebasePrivateKey) {
      try {
        fcmAccessToken = await getAccessToken(firebaseClientEmail, firebasePrivateKey);
      } catch (err) {
        console.error("FCM access token alınamadı. Firebase Secrets hatalı olabilir.", err);
      }
    } else {
      console.warn("Firebase Secrets eksik. (FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY)");
    }

    // 3. Her kullanıcı için karar motoru
    for (const [userId, tokens] of usersMap.entries()) {
      try {
        // Ayarları oku
        const { data: settings } = await supabase
          .from('user_notification_settings')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

        const quietStart = settings?.quiet_start_hour ?? 22;
        const quietEnd = settings?.quiet_end_hour ?? 9;

        // Sessiz saat kontrolü (Varsayılan: 22:00 - 09:00 arası bildirim atma)
        const inQuietHour = (currentHour >= quietStart || currentHour < quietEnd);
        if (inQuietHour) {
          console.log(`Kullanıcı atlandı (${userId}): Sessiz saatler içerisindeyiz.`);
          continue;
        }

        // Günlük hedefleri oku
        const { data: goals } = await supabase
          .from('user_daily_goals')
          .select('*')
          .eq('user_id', userId)
          .eq('goal_date', todayStr)
          .maybeSingle();

        // Kalori ve protein güncel tüketim toplamını hesapla (daily_nutrition_logs tablosundan)
        const { data: nutritionLogs } = await supabase
          .from('daily_nutrition_logs')
          .select('calories_kcal, protein_g')
          .eq('user_id', userId)
          .eq('log_date', todayStr);

        let calcCalories = 0;
        let calcProtein = 0;
        if (nutritionLogs) {
          for (const row of nutritionLogs) {
            calcCalories += Number(row.calories_kcal) || 0;
            calcProtein += Number(row.protein_g) || 0;
          }
        }

        // Profili oku (Son tartı tarihi için)
        const { data: profile } = await supabase
          .from('user_profiles')
          .select('updated_at')
          .eq('id', userId)
          .maybeSingle();

        // Son gönderilen bildirim loglarını oku (Cooldown kontrolü için)
        const { data: logs } = await supabase
          .from('notification_send_logs')
          .select('notification_type, sent_at')
          .eq('user_id', userId)
          .order('sent_at', { ascending: false });

        // Belirtilen türde bir bildirimin üzerinden kaç saat geçmiş?
        const getHoursSince = (type: string) => {
          const log = logs?.find(l => l.notification_type === type);
          if (!log) return 999;
          const diffMs = now.getTime() - new Date(log.sent_at).getTime();
          return diffMs / (1000 * 60 * 60);
        };

        // Belirtilen türde bugün bildirim atılmış mı?
        const hasSentToday = (type: string) => {
          const log = logs?.find(l => l.notification_type === type);
          if (!log) return false;
          return new Date(log.sent_at).toISOString().split('T')[0] === todayStr;
        };

        // Karar Değişkenleri
        let selectedNotif = null;

        const waterGoal = goals?.water_goal_l ?? 2.0; // Varsayılan 2 litre
        const waterConsumed = goals?.water_consumed_l ?? 0;
        const calGoal = goals?.calorie_goal ?? 2000;
        const calConsumed = calcCalories;
        const protGoal = goals?.protein_goal_g ?? 100;
        const protConsumed = calcProtein;
        const actGoal = goals?.activity_goal_min ?? 60;
        const actConsumed = goals?.activity_completed_min ?? 0;

        // 4. Öncelik Sırasıyla Kontroller

        // Öncelik 1: Su
        if (settings?.water_reminder_enabled !== false && goals) {
          if ((waterConsumed / waterGoal) < 0.50 && getHoursSince('water') >= 2) {
            selectedNotif = { type: 'water', title: "Su Hatırlatması 💧", body: "Bugün su hedefinin gerisindesin. Bir bardak su iyi gelebilir." };
          }
        }
        
        // Öncelik 2: Kalori Aşımı
        if (!selectedNotif && settings?.calorie_reminder_enabled !== false && goals) {
          if (calConsumed > calGoal && !hasSentToday('calorie_high')) {
            selectedNotif = { type: 'calorie_high', title: "Kalori Hedefini Aştın 🔥", body: "Bugünkü kalori hedefini aştın. Kalan öğünlerde daha hafif seçimler yapabilirsin." };
          }
        }
        
        // Öncelik 3: Protein Düşük
        if (!selectedNotif && settings?.protein_reminder_enabled !== false && goals) {
          if ((protConsumed / protGoal) < 0.40 && getHoursSince('protein_low') >= 3) {
            selectedNotif = { type: 'protein_low', title: "Protein Düşük Görünüyor 🌿", body: "Bugünkü protein hedefinin gerisindesin. Protein ağırlıklı hafif bir tarif seçebilirsin." };
          }
        }
        
        // Öncelik 4: Protein Ulaşıldı
        if (!selectedNotif && settings?.protein_reminder_enabled !== false && goals) {
          if (protConsumed >= protGoal && !hasSentToday('protein_high')) {
            selectedNotif = { type: 'protein_high', title: "Protein Hedefin Tamamlandı 💪", body: "Bugünkü protein hedefini tamamladın. Dengeli devam ediyorsun." };
          }
        }
        
        // Öncelik 5: Kalori Düşük
        if (!selectedNotif && settings?.calorie_reminder_enabled !== false && goals) {
          if ((calConsumed / calGoal) < 0.35 && getHoursSince('calorie_low') >= 4) {
            selectedNotif = { type: 'calorie_low', title: "Dengeli Öğün Zamanı 🍽️", body: "Bugünkü kalorinin düşük görünüyor. Dengeli bir öğün ekleyebilirsin." };
          }
        }
        
        // Öncelik 6: Hareket
        if (!selectedNotif && settings?.activity_reminder_enabled !== false && goals) {
          if ((actConsumed / actGoal) < 0.40 && getHoursSince('activity') >= 5) {
            selectedNotif = { type: 'activity', title: "Hareket Zamanı 🚶‍♀️", body: "Bugün biraz hareketsiz kaldın. Kısa bir yürüyüş iyi gelebilir." };
          }
        }
        
        // Öncelik 7: Tartı
        if (!selectedNotif && settings?.weight_reminder_enabled !== false) {
          const lastUpdate = profile?.updated_at ? new Date(profile.updated_at) : null;
          const daysSinceWeight = lastUpdate ? (now.getTime() - lastUpdate.getTime()) / (1000 * 3600 * 24) : 999;
          if (daysSinceWeight >= 7 && !hasSentToday('weight')) {
            selectedNotif = { type: 'weight', title: "Tartı Zamanı ⚖️", body: "Bu haftaki tartı kaydını eklemeyi unutma." };
          }
        }

        // 5. Seçilen bildirim varsa FCM ile gönder
        if (selectedNotif) {
          let sentSuccessfully = false;

          if (fcmAccessToken && firebaseProjectId) {
            for (const t of tokens) {
              const fcmUrl = `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`;
              const fcmBody = {
                message: {
                  token: t.token,
                  notification: {
                    title: selectedNotif.title,
                    body: selectedNotif.body,
                  },
                  data: {
                    type: selectedNotif.type
                  }
                }
              };
              
              const pushResp = await fetch(fcmUrl, {
                method: 'POST',
                headers: {
                  'Authorization': `Bearer ${fcmAccessToken}`,
                  'Content-Type': 'application/json'
                },
                body: JSON.stringify(fcmBody)
              });

              if (pushResp.ok) {
                sentSuccessfully = true;
              } else {
                const errData = await pushResp.json();
                console.error(`FCM gönderim hatası (token: ${t.token}):`, errData);
                
                // UNREGISTERED hatası alınırsa token geçersiz demektir, veritabanında pasif yap
                if (errData.error?.details?.[0]?.errorCode === 'UNREGISTERED') {
                  await supabase.from('user_fcm_tokens').update({ is_active: false }).eq('token', t.token);
                }
              }
            }
          }

          // 6. Loglara kaydet
          if (sentSuccessfully) {
            await supabase.from('notification_send_logs').insert({
              user_id: userId,
              notification_type: selectedNotif.type,
              title: selectedNotif.title,
              body: selectedNotif.body,
              source: 'edge_function',
              sent_at: new Date().toISOString()
            });
            results.push({ userId, type: selectedNotif.type, status: 'sent' });
          } else {
            results.push({ userId, type: selectedNotif.type, status: 'fcm_failed' });
          }
        } else {
          results.push({ userId, status: 'no_candidate' });
        }
      } catch (err) {
        console.error(`Kullanıcı işlenirken hata oluştu (${userId}):`, err);
        results.push({ userId, status: 'error', error: String(err) });
      }
    }

    return new Response(JSON.stringify({ message: "İşlem tamamlandı", results }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Fonksiyon genel hatası:", error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
