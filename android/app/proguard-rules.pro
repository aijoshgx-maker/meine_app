# R8-Regeln fuer den Release-Build.
#
# R8 entfernt Code, den es fuer unerreichbar haelt. Wo Bibliotheken per
# Reflexion arbeiten, sieht R8 diese Zugriffe nicht - deshalb hier explizit
# schuetzen. Fehler dieser Art zeigen sich ausschliesslich im Release-Build,
# nie im Debug.

# --- Flutter-Engine ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- flutter_local_notifications ---
# Plant Benachrichtigungen ueber Broadcast-Receiver, die das System per Name
# instanziiert, und serialisiert deren Daten ueber GSON.
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# GSON: generische Typen und Feldnamen muessen erhalten bleiben, sonst
# scheitert das Deserialisieren geplanter Benachrichtigungen still.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# --- Desugaring (Java-8-Backport, von flutter_local_notifications gefordert) ---
-dontwarn java.lang.invoke.**
-dontwarn **$$Lambda$*

# --- Hive ---
# Speichert reine Maps ohne TypeAdapter; hier ist nichts zu schuetzen. Der
# Eintrag steht bewusst da, damit beim naechsten Umbau auf TypeAdapter
# jemand daran denkt.

# --- Stacktraces lesbar halten ---
# Ohne das sind Absturzberichte aus dem Play Console unbrauchbar.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
