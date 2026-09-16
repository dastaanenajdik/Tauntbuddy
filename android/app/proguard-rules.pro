# TauntBuddy release rules.
# Flutter's own rules are applied through the Flutter Gradle plugin; these only
# keep the local notification plugin's serialised models intact.

-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.tauntbuddy.app.KavachService { *; }
-dontwarn com.google.errorprone.annotations.**
