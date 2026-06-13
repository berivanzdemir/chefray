# Edge Function & FCM Transition Notes

Bu doküman, ChefRay uygulamasının arka plan bildirim sisteminin (WorkManager tabanlı `SmartNotificationService`) Supabase Edge Function + Firebase Cloud Messaging (FCM) mimarisine geçiş sürecindeki notları içerir.

## Mevcut Durum (Aşama 3)
- `supabase/functions/send-smart-notifications/index.ts` dosyası hazırlandı.
- Bu fonksiyon, Flutter tarafındaki `SmartNotificationService` ile birebir aynı karar motoru mantığına sahiptir.
- Supabase tabloları (FCM tokenları, ayarlar, günlük hedefler, profil ve loglar) üzerinden kullanıcılara atılması gereken bildirimlere karar verir ve bunları Firebase API üzerinden push notification olarak cihaza iletir.
- **DİKKAT:** Cron Job henüz aktif edilmedi!
- **DİKKAT:** WorkManager ve yerel (local) notification altyapısı cihazlarda *henüz kaldırılmadı* ve çalışmaya devam ediyor.
- İki sistem (eski ve yeni) birbirini engellemez ancak cron aktif edildiğinde her ikisi de aynı hedeflere bakacağı için, WorkManager'ın kapatılması gerekir.

## Güvenlik ve Firebase Secrets
Edge Function'ın Firebase'e token atabilmesi için Google Cloud Service Account anahtarlarına ihtiyacı vardır. Bu anahtarlar kod içerisine asla yazılmaz!

Supabase Dashboard üzerinden `Secrets` (Environment Variables) kısmına şu değişkenler eklenmelidir:
- `FIREBASE_PROJECT_ID`: (Örn: `chefray-app-1234`)
- `FIREBASE_CLIENT_EMAIL`: (Service account e-posta adresi)
- `FIREBASE_PRIVATE_KEY`: (Service account private key. `\n` içerebilir, kod içerisinde newline formatına çevrilecektir.)

*Ayrıca, fonksiyon `SUPABASE_URL` ve `SUPABASE_SERVICE_ROLE_KEY` değişkenlerini otomatik olarak okur (bu Supabase tarafından sağlanır) ve veritabanına RLS politikalarını baypas ederek güvenli bir şekilde erişir.*

## Test ve Sonraki Adımlar
1. Supabase CLI kullanılarak fonksiyon deploy edilmeli: 
   `supabase functions deploy send-smart-notifications`
2. Supabase secrets yüklenmeli:
   `supabase secrets set FIREBASE_PROJECT_ID=... FIREBASE_CLIENT_EMAIL=... FIREBASE_PRIVATE_KEY="..."`
3. Supabase Dashboard (veya `pg_cron`) üzerinden bu fonksiyonu her 15 dakikada bir tetikleyecek bir Cron Job kurulmalıdır.
4. Testler başarılı olduktan ve push bildirimlerin sorunsuz ulaştığı doğrulandıktan sonra, Flutter projesindeki `WorkManager` paket bağımlılığı ve konfigürasyonları tamamen kaldırılacaktır.
