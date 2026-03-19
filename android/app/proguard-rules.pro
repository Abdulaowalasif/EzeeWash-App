# ── flutter_stripe push provisioning keep rules ───────────────────────────────
# These classes are referenced by the Stripe SDK but only required for
# physical card provisioning (Apple/Google Pay card issuance).
# Since EzeeWash does not use push provisioning, we tell R8 to
# ignore the missing classes instead of failing the build.

-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-dontwarn com.reactnativestripesdk.pushprovisioning.**