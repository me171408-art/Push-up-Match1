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

}

