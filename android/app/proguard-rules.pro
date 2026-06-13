# ===========================================
# ChefRay ProGuard / R8 Rules
# ===========================================

# --- ML Kit: Optional language modules ---
# google_mlkit_text_recognition paketi tüm dil modüllerini
# referans gösterir ancak bunların hepsi bağımlılık olarak
# eklenmemiş olabilir. Eksik sınıflar için uyarıları bastır.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# --- Firebase / GMS / Diğer Paketlerin Uyarılarını Bastırma ---
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-dontwarn io.flutter.**
-dontwarn androidx.work.**
-dontwarn com.dexterous.**
-dontwarn javax.annotation.**
-dontwarn com.google.common.**

# --- Crashlytics / Debugging ---
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# --- Serialization & Reflection koruması ---
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations

# --- Enum'ları koru (R8 strip etmesin) ---
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# --- Parcelable implementasyonlarını koru ---
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# --- Serializable implementasyonlarını koru ---
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# --- LOG TEMİZLİĞİ (MobSF CWE-532 Optimizasyonu) ---
# Uygulama Release modda iken MobSF log uyarılarını tamamen kaldırmak için
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void println(**);
}
