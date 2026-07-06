#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.sahabettinadiyaman.pushupmatch";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "app_logo" asset catalog image resource.
static NSString * const ACImageNameAppLogo AC_SWIFT_PRIVATE = @"app_logo";

/// The "onboarding_bg" asset catalog image resource.
static NSString * const ACImageNameOnboardingBg AC_SWIFT_PRIVATE = @"onboarding_bg";

/// The "onboarding_coach" asset catalog image resource.
static NSString * const ACImageNameOnboardingCoach AC_SWIFT_PRIVATE = @"onboarding_coach";

/// The "onboarding_coach2" asset catalog image resource.
static NSString * const ACImageNameOnboardingCoach2 AC_SWIFT_PRIVATE = @"onboarding_coach2";

/// The "onboarding_coach3" asset catalog image resource.
static NSString * const ACImageNameOnboardingCoach3 AC_SWIFT_PRIVATE = @"onboarding_coach3";

#undef AC_SWIFT_PRIVATE
