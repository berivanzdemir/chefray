# ChefRay 🍽️🤖

ChefRay, kullanıcıların sağlık profili, diyet listesi, kan tahlili verileri ve beslenme tercihlerini dikkate alarak kişiselleştirilmiş tarif önerileri sunan Flutter tabanlı mobil beslenme asistanıdır.

Uygulama; OCR tabanlı belge okuma, Supabase veri yönetimi, Gemini destekli öneri sistemi, barkod ile ürün analizi, günlük hedef takibi ve Ray adlı dijital asistan bileşenlerini bir araya getirir.

---

## 🚀 Proje Özeti

ChefRay, klasik tarif uygulamalarından farklı olarak yalnızca tarif listelemez. Kullanıcının yaş, boy, kilo, hedef, sağlık durumu, alerji bilgileri, diyet listesi ve kan tahlili verilerini birlikte değerlendirerek daha kişiselleştirilmiş bir beslenme deneyimi sunmayı amaçlar.

Uygulamada kullanıcılar diyet listesi veya kan tahlili belgelerini yükleyebilir. Bu belgeler OCR ile metne dönüştürülür ve kural tabanlı doğrulama yapılarıyla analiz edilir. Yapay zekâ modeli belge okuma sürecinde değil; kişiselleştirilmiş tarif önerileri ve Ray asistan etkileşimlerinde destekleyici bileşen olarak kullanılmaktadır.

---

## 🎬 Tanıtım Videosu

ChefRay uygulamasının genel arayüzünü, temel özelliklerini ve kullanıcı deneyimini gösteren tanıtım videosuna aşağıdaki bağlantıdan ulaşabilirsiniz.

🔗 ChefRay Tanıtım Videosunu İzle = https://drive.google.com/file/d/1kIivEQyGvFfcUIj0WuYkPfcqVfZk4nNL/view?usp=sharing
---

## ✨ Temel Özellikler

* Kullanıcı kayıt, giriş ve e-posta doğrulama
* Kişisel sağlık profili oluşturma
* Diyet listesi ve kan tahlili yükleme
* OCR ile belge okuma
* Kural tabanlı belge doğrulama
* Supabase tabanlı tarif veri yönetimi
* Kullanıcı profiline göre tarif önerileri
* Gemini destekli Ray asistan
* Barkod ile paketli ürün analizi
* Günlük kalori, protein, su ve aktivite takibi
* Adım adım pişirme modu
* Sesli yönlendirme desteği
* Favori tarifler ve bildirim altyapısı

---

## 🧩 Sistem Mimarisi

ChefRay; mobil uygulama, kimlik doğrulama, kullanıcı profili, belge yükleme, OCR doğrulama, yapay zekâ destekli öneri, Supabase veri tabanı ve takip katmanlarından oluşmaktadır.

<img width="1535" height="1024" alt="sistem mimarisi" src="https://github.com/user-attachments/assets/cd368364-c4fc-4e17-8554-19fc1128998c" />


---

## 🗄️ Veri Tabanı Yapısı

Uygulamada kullanıcı bilgileri, sağlık profilleri, tarifler, favoriler, günlük hedefler, bildirim kayıtları ve analiz süreçleri Supabase üzerinde yönetilmektedir.

Tarif verileri harici bir tarif API’sinden anlık olarak çekilmemekte, proje kapsamında düzenlenen tarif verileri Supabase üzerindeki `recipes` tablosu üzerinden kullanılmaktadır.

<img width="1535" height="1024" alt="Veri Tabanı Yapısı" src="https://github.com/user-attachments/assets/8587785d-5a61-4c9d-b4be-1b125a2f7c27" />


---

## 🎨 Tasarım Yaklaşımı

ChefRay’in tasarım dili sade, modern, yeşil-beyaz renk paletine sahip ve sağlıklı yaşam temasına uygun şekilde hazırlanmıştır. Kart tabanlı arayüz, sade ikonografi ve Ray maskotu kullanıcı deneyimini destekleyen temel tasarım unsurlarıdır.

<img width="1448" height="1086" alt="kullanıcı deneyimi" src="https://github.com/user-attachments/assets/5b6c8bfd-cc36-4e27-9f91-75d7e2cb8fda" />


---

## 🛠️ Kullanılan Teknolojiler

ChefRay uygulamasında mobil arayüz, veri yönetimi, OCR, yapay zekâ destekli öneri, bildirim, barkod analizi ve sesli yönlendirme gibi farklı işlevler için aşağıdaki teknolojilerden yararlanılmıştır.

| Teknoloji / Paket              |        Sürüm | Kullanım Alanı                                                                      |
| ------------------------------ | -----------: | ----------------------------------------------------------------------------------- |
| Flutter / Dart                 | Dart 3.11.4+ | Mobil uygulama arayüzü, servis katmanı, veri modelleri ve yönlendirme yapısı        |
| Android SDK                    |    minSdk 29 | Android 10 ve üzeri cihaz desteği                                                   |
| Android Gradle Plugin          |       8.11.1 | Android tarafındaki derleme ve yapılandırma süreçleri                               |
| Kotlin                         |       2.2.20 | Android yapılandırma ve eklenti uyumluluğu                                          |
| Supabase Flutter               |        2.9.0 | Kullanıcı profilleri, sağlık verileri, tarifler, favoriler ve günlük kayıt yönetimi |
| Firebase Core                  |       3.13.0 | Firebase servislerinin uygulama içinde başlatılması                                 |
| Firebase Messaging             |       15.2.5 | FCM token yönetimi ve uzak bildirimler                                              |
| Flutter Local Notifications    |       21.0.0 | Cihaz üzerinde yerel bildirimlerin gösterilmesi                                     |
| Google Generative AI           |        0.4.7 | Gemini destekli tarif önerileri ve Ray asistan özellikleri                          |
| Google ML Kit Text Recognition |       0.14.0 | Diyet listesi ve kan tahlili belgelerinden OCR ile metin çıkarma                    |
| Mobile Scanner                 |        6.0.2 | Barkod ve paketli ürün analizi                                                      |
| Flutter TTS                    |        4.2.5 | Tarif adımlarının ve asistan yanıtlarının sesli aktarımı                            |
| Flutter Dotenv                 |        5.2.1 | API anahtarları ve ortam değişkenlerinin yönetimi                                   |
| Go Router                      |       17.2.3 | Uygulama içi rota ve sayfa yönlendirme yönetimi                                     |
| Shared Preferences             |        2.3.0 | Yerel önbellekleme ve kullanıcı tercihleri                                          |
| Image Picker                   |        1.2.2 | Kamera ve galeri üzerinden belge/görsel seçimi                                      |

---

## 📱 Uygulama Modülleri

ChefRay içerisinde yer alan temel uygulama modülleri:

* Splash screen
* Login / Register
* Email verification
* Seni Tanıyalım onboarding ekranı
* Ana sayfa
* Diyet listesi yükleme ekranı
* Kan tahlili yükleme ekranı
* Analiz sonucu ekranı
* Tarif önerileri ekranı
* Tarif detay ekranı
* Adım adım pişirme modu
* Profil ekranı
* Günlük hedefler ve su takibi
* Barkod / ürün analizi
* Ray chatbot ekranı

---

## ⚙️ Kurulum

Projeyi klonlayın:

```bash
git clone https://github.com/kullanici-adiniz/ChefRay.git
cd ChefRay
```

Bağımlılıkları yükleyin:

```bash
flutter pub get
```

`.env.example` dosyasını temel alarak `.env` dosyası oluşturun:

```bash
cp .env.example .env
```

`.env` dosyasını kendi bilgilerinizle doldurun:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

Firebase kullanımı için kendi `google-services.json` dosyanızı şu konuma ekleyin:

```text
android/app/google-services.json
```

Uygulamayı çalıştırın:

```bash
flutter run
```

---

## 🔐 Güvenlik Notu

Bu repoda gerçek API anahtarları, Firebase yapılandırma dosyaları, imza dosyaları ve gizli ortam değişkenleri paylaşılmamaktadır.

Projeyi çalıştırmak isteyen geliştiriciler `.env.example` dosyasını temel alarak kendi `.env` dosyalarını oluşturmalı ve kendi Firebase yapılandırma dosyalarını projeye eklemelidir.

Repoya dahil edilmeyen bazı dosyalar:

* `.env`
* `google-services.json`
* `GoogleService-Info.plist`
* `key.properties`
* `.jks`
* `.keystore`
* `build/`
* `.dart_tool/`

---

## 📊 Veri Kaynağı

ChefRay projesinde kullanılan tarif verileri, yemek.com kaynaklı tarifleri içeren açık kaynaklı Turkish Food Recipes veri setinden yararlanılarak düzenlenmiştir.

Kaynak:
https://github.com/ilyasozkurt/turkish-food-recipes

Bu veriler proje kapsamında temizlenmiş, düzenlenmiş ve Supabase üzerindeki tarif veri yapısına aktarılmıştır.

---

## 🤖 Ray Asistan

Ray, ChefRay uygulamasında kullanıcıya destek sağlayan dijital asistan karakteridir. Kullanıcıya tarif önerileri, analiz yorumları, pişirme modu notları ve beslenme süreciyle ilgili destekleyici yanıtlar sunar.

Ray asistan etkileşimlerinde Gemini API desteğinden yararlanılmaktadır.

---

## 📌 Gelecek Geliştirmeler

* Tarif öneri sisteminin daha güçlü hale getirilmesi
* OCR doğruluğunun artırılması
* Barkod ve paketli ürün analizinin geliştirilmesi
* Ray asistanın daha bağlamsal yanıtlar verebilmesi
* Günlük ve haftalık kişiselleştirilmiş beslenme planlarının oluşturulması
* Tarif veri setinin genişletilmesi
* Güvenlik analizlerinin güncel release sürümü üzerinden yeniden yapılması

---

## 🎓 Akademik Kullanım Notu

Bu proje, mobil uygulama geliştirme, OCR tabanlı belge analizi, yapay zekâ destekli öneri sistemi ve kişiselleştirilmiş beslenme takibi konularını bir araya getiren akademik/demo amaçlı bir çalışmadır.

ChefRay herhangi bir tıbbi teşhis koymaz. Uygulamada sunulan öneriler genel bilgilendirme ve kişisel beslenme takibini destekleme amacı taşır.

---

## 📄 Lisans

Bu proje akademik/demo amaçlı geliştirilmiştir. Kullanım ve dağıtım koşulları proje sahibinin belirleyeceği lisans yapısına göre düzenlenebilir.
