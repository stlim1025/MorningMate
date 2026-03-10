# Firebase App Check - SafetyNet exclusion rules
# We explicitly excluded play-services-safetynet to comply with Google Play Store deprecation.
# These rules prevent R8 from failing due to missing SafetyNet classes which are not used.

-dontwarn com.google.android.gms.safetynet.**
-dontwarn com.google.firebase.appcheck.safetynet.**
