import Foundation

#if os(macOS)
import SweetCookieKit

public typealias BrowserCookieImportOrder = [Browser]
#else
public struct Browser: Sendable, Hashable {
    public init() {}
}

public typealias BrowserCookieImportOrder = [Browser]
#endif

extension [Browser] {
    /// Filters a browser list to sources worth attempting for cookie imports.
    ///
    /// This is intentionally stricter than "app installed": it aims to avoid unnecessary Keychain prompts.
    public func cookieImportCandidates(using detection: BrowserDetection) -> [Browser] {
        let candidates = BrowserCookieImportAllowlist.filter(self).filter { browser in
            if KeychainAccessGate.isDisabled, browser.usesKeychainForCookieDecryption {
                return false
            }
            return detection.isCookieSourceAvailable(browser)
        }
        return candidates.filter { BrowserCookieAccessGate.shouldAttempt($0) }
    }

    /// Filters a browser list to sources with usable profile data on disk.
    public func browsersWithProfileData(using detection: BrowserDetection) -> [Browser] {
        self.filter { detection.hasUsableProfileData($0) }
    }
}

#if os(macOS)
public enum BrowserCookieImportAllowlist {
    public static let defaultsKey = "allowedBrowserCookieImports"
    public static let defaultBrowsers: [Browser] = [.safari, .chrome, .firefox]

    public static func allowedBrowsers(userDefaults: UserDefaults = .standard) -> [Browser] {
        guard let rawValues = userDefaults.stringArray(forKey: Self.defaultsKey) else {
            return Self.defaultBrowsers
        }
        return rawValues.compactMap(Browser.init(rawValue:))
    }

    public static func filter(
        _ browsers: [Browser],
        userDefaults: UserDefaults = .standard) -> [Browser]
    {
        let allowed = Set(Self.allowedBrowsers(userDefaults: userDefaults))
        return browsers.filter { allowed.contains($0) }
    }
}

extension Browser {
    var usesKeychainForCookieDecryption: Bool {
        switch self {
        case .safari, .firefox, .zen:
            return false
        case .chrome, .chromeBeta, .chromeCanary,
             .arc, .arcBeta, .arcCanary,
             .chatgptAtlas,
             .chromium,
             .brave, .braveBeta, .braveNightly,
             .edge, .edgeBeta, .edgeCanary,
             .helium,
             .vivaldi,
             .dia,
             .yandex,
             .comet:
            return true
        @unknown default:
            return true
        }
    }
}
#else
public enum BrowserCookieImportAllowlist {
    public static let defaultsKey = "allowedBrowserCookieImports"
    public static let defaultBrowsers: [Browser] = []

    public static func allowedBrowsers(userDefaults _: UserDefaults = .standard) -> [Browser] {
        Self.defaultBrowsers
    }

    public static func filter(
        _ browsers: [Browser],
        userDefaults _: UserDefaults = .standard) -> [Browser]
    {
        browsers
    }
}

extension Browser {
    var usesKeychainForCookieDecryption: Bool {
        false
    }
}
#endif
