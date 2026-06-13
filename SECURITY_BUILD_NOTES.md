# ChefRay — Release Build Güvenlik Notları

MobSF’de 80+ için APK kesinlikle release keystore ile imzalanmalıdır.
Bu dosya, MobSF güvenlik skorunu yükseltmek için gereken release build adımlarını içerir.

---

## 1. Release Keystore Oluşturma

```bash
# keystore dizinini oluştur (eğer yoksa)
mkdir -p android/keystore

# Release keystore oluştur
keytool -genkey -v \
  -keystore android/keystore/chefray-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias chefray
```

> ⚠️ Keystore dosyasını (`*.jks`) ve şifreleri **güvenli bir yerde saklayın**.
> Bu dosya kaybolursa Play Store'a güncelleme yükleyemezsiniz.
> `.gitignore` zaten `*.jks`, `*.keystore` ve `key.properties` dosyalarını hariç tutar.

---

## 2. key.properties Dosyası Oluşturma

`android/key.properties` dosyasını oluşturun:

```properties
storePassword=GERCEK_KEYSTORE_SIFRESI
keyPassword=GERCEK_KEY_SIFRESI
keyAlias=chefray
storeFile=../keystore/chefray-release-key.jks
```

> ⚠️ Bu dosyayı **asla** repoya commit etmeyin. `.gitignore` tarafından korunmaktadır.

---

## 3. Release APK Oluşturma

```bash
flutter clean
flutter pub get
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

Oluşan APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## 4. Release App Bundle Oluşturma (Play Store için)

```bash
flutter clean
flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Oluşan AAB: `build/app/outputs/bundle/release/app-release.aab`

---

## 5. MobSF Doğrulama Kontrolleri

Release APK'yı MobSF'ye yükledikten sonra şunları kontrol edin:

- [ ] Certificate alanında `CN=Android Debug` **görünmemeli**
- [ ] `USE_FINGERPRINT` izni **listelenmemeli**
- [ ] `SCHEDULE_EXACT_ALARM` izni **listelenmemeli**
- [ ] `android:allowBackup` → `false` olmalı
- [ ] `android:usesCleartextTraffic` → `false` olmalı
- [ ] Network security config mevcut olmalı
- [ ] Exported component sayısı azalmış olmalı

---

## 6. Certificate Pinning Notu

Şu an certificate pinning uygulanmamıştır. Nedenler:

- Supabase, Firebase ve Google Sign-In servisleri sertifikalarını dönemsel olarak yeniler
- Pinning yapıldığında sertifika değişirse uygulama tamamen çalışmaz hale gelir
- Bu servislerin tümü zaten HTTPS kullanmaktadır
- Network security config ile sadece system certificates'a güvenilmektedir

Eğer ileride özel API endpoint'leri eklenirse, sadece o endpoint'ler için domain-specific pinning değerlendirilebilir.

---

## 7. Güvenlik Yapılandırma Özeti

| Ayar | Değer | Dosya |
|------|-------|-------|
| allowBackup | false | AndroidManifest.xml |
| fullBackupContent | @xml/backup_rules | AndroidManifest.xml |
| dataExtractionRules | @xml/data_extraction_rules | AndroidManifest.xml |
| usesCleartextTraffic | false | AndroidManifest.xml |
| networkSecurityConfig | @xml/network_security_config | AndroidManifest.xml |
| minifyEnabled | true | build.gradle.kts |
| shrinkResources | true | build.gradle.kts |
| proguard | proguard-android-optimize.txt + proguard-rules.pro | build.gradle.kts |
| obfuscation | --obfuscate flag | Build komutu |
| minSdk | 29 | build.gradle.kts |
