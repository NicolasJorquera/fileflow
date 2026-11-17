# Release builds crashed at startup (1.0.0 from Play): R8 removed classes that
# are only created by reflection.

# WorkManager (used by Google Mobile Ads) builds its Room database by name.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# ML Kit and Play services discover their components by reflection.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
-keep class com.google.mlkit.common.internal.CommonComponentRegistrar { <init>(); }
-keep class com.google.mlkit.vision.documentscanner.** { *; }
