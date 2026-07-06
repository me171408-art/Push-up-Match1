#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.sahabettinadiyaman.pushboss";

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

/// The "rank_bronze" asset catalog image resource.
static NSString * const ACImageNameRankBronze AC_SWIFT_PRIVATE = @"rank_bronze";

/// The "rank_champion" asset catalog image resource.
static NSString * const ACImageNameRankChampion AC_SWIFT_PRIVATE = @"rank_champion";

/// The "rank_diamond" asset catalog image resource.
static NSString * const ACImageNameRankDiamond AC_SWIFT_PRIVATE = @"rank_diamond";

/// The "rank_emerald" asset catalog image resource.
static NSString * const ACImageNameRankEmerald AC_SWIFT_PRIVATE = @"rank_emerald";

/// The "rank_gold" asset catalog image resource.
static NSString * const ACImageNameRankGold AC_SWIFT_PRIVATE = @"rank_gold";

/// The "rank_iron" asset catalog image resource.
static NSString * const ACImageNameRankIron AC_SWIFT_PRIVATE = @"rank_iron";

/// The "rank_legend" asset catalog image resource.
static NSString * const ACImageNameRankLegend AC_SWIFT_PRIVATE = @"rank_legend";

/// The "rank_master" asset catalog image resource.
static NSString * const ACImageNameRankMaster AC_SWIFT_PRIVATE = @"rank_master";

/// The "rank_platinum" asset catalog image resource.
static NSString * const ACImageNameRankPlatinum AC_SWIFT_PRIVATE = @"rank_platinum";

/// The "rank_silver" asset catalog image resource.
static NSString * const ACImageNameRankSilver AC_SWIFT_PRIVATE = @"rank_silver";

/// The "rank_steel" asset catalog image resource.
static NSString * const ACImageNameRankSteel AC_SWIFT_PRIVATE = @"rank_steel";

#undef AC_SWIFT_PRIVATE
