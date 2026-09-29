# Reglas R8/ProGuard para el build release de Plantamoss.
# Flutter ya agrega sus reglas; aqui solo lo minimo extra.

# Flutter embedding y plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_secure_storage (usa el Android Keystore)
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Play Core (deferred components de Flutter); no se usa
-dontwarn com.google.android.play.core.**

# Quitar logs de Android en release
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
