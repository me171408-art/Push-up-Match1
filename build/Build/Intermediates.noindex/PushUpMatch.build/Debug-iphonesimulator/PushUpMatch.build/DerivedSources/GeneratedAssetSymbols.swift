import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "app_logo" asset catalog image resource.
    static let appLogo = DeveloperToolsSupport.ImageResource(name: "app_logo", bundle: resourceBundle)

    /// The "onboarding_bg" asset catalog image resource.
    static let onboardingBg = DeveloperToolsSupport.ImageResource(name: "onboarding_bg", bundle: resourceBundle)

    /// The "onboarding_coach" asset catalog image resource.
    static let onboardingCoach = DeveloperToolsSupport.ImageResource(name: "onboarding_coach", bundle: resourceBundle)

    /// The "onboarding_coach2" asset catalog image resource.
    static let onboardingCoach2 = DeveloperToolsSupport.ImageResource(name: "onboarding_coach2", bundle: resourceBundle)

    /// The "onboarding_coach3" asset catalog image resource.
    static let onboardingCoach3 = DeveloperToolsSupport.ImageResource(name: "onboarding_coach3", bundle: resourceBundle)

    /// The "rank_bronze" asset catalog image resource.
    static let rankBronze = DeveloperToolsSupport.ImageResource(name: "rank_bronze", bundle: resourceBundle)

    /// The "rank_champion" asset catalog image resource.
    static let rankChampion = DeveloperToolsSupport.ImageResource(name: "rank_champion", bundle: resourceBundle)

    /// The "rank_diamond" asset catalog image resource.
    static let rankDiamond = DeveloperToolsSupport.ImageResource(name: "rank_diamond", bundle: resourceBundle)

    /// The "rank_emerald" asset catalog image resource.
    static let rankEmerald = DeveloperToolsSupport.ImageResource(name: "rank_emerald", bundle: resourceBundle)

    /// The "rank_gold" asset catalog image resource.
    static let rankGold = DeveloperToolsSupport.ImageResource(name: "rank_gold", bundle: resourceBundle)

    /// The "rank_iron" asset catalog image resource.
    static let rankIron = DeveloperToolsSupport.ImageResource(name: "rank_iron", bundle: resourceBundle)

    /// The "rank_legend" asset catalog image resource.
    static let rankLegend = DeveloperToolsSupport.ImageResource(name: "rank_legend", bundle: resourceBundle)

    /// The "rank_master" asset catalog image resource.
    static let rankMaster = DeveloperToolsSupport.ImageResource(name: "rank_master", bundle: resourceBundle)

    /// The "rank_platinum" asset catalog image resource.
    static let rankPlatinum = DeveloperToolsSupport.ImageResource(name: "rank_platinum", bundle: resourceBundle)

    /// The "rank_silver" asset catalog image resource.
    static let rankSilver = DeveloperToolsSupport.ImageResource(name: "rank_silver", bundle: resourceBundle)

    /// The "rank_steel" asset catalog image resource.
    static let rankSteel = DeveloperToolsSupport.ImageResource(name: "rank_steel", bundle: resourceBundle)

}

