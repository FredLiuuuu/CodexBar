import Foundation
import SweetCookieKit
import Testing
@testable import CodexBarCore

struct BrowserCookieOrderStatusStringTests {
    #if os(macOS)
    @Test
    func `codex cookie import order keeps firefox ahead of extra chromium browsers`() {
        let order = ProviderDefaults.metadata[.codex]?.browserCookieOrder ?? Browser.defaultImportOrder
        #expect(Array(order.prefix(3)) == [.safari, .chrome, .firefox])
        #expect(!order.contains(.comet))
    }

    @Test
    func `full cookie import order retains newly supported chromium browsers`() throws {
        #expect(Browser.defaultImportOrder.contains(.comet))
        #expect(Browser.defaultImportOrder.contains(.yandex))
        let fullOrder = try #require(ProviderBrowserCookieDefaults.fullImportOrder)
        #expect(fullOrder.contains(.comet))
        #expect(fullOrder.contains(.yandex))
    }

    @Test
    func `automatic cookie import defaults exclude broad chromium browsers`() throws {
        let order = try #require(ProviderBrowserCookieDefaults.defaultImportOrder)
        #expect(order == [.safari, .chrome, .firefox])
        #expect(!order.contains(.comet))
        #expect(!order.contains(.yandex))
    }

    @Test
    func `browser cookie import allowlist defaults to privacy first browsers`() {
        let suite = UserDefaults(suiteName: "BrowserCookieOrderLabelTests-default-allowlist")!
        suite.removeObject(forKey: BrowserCookieImportAllowlist.defaultsKey)
        #expect(BrowserCookieImportAllowlist.allowedBrowsers(userDefaults: suite) == [.safari, .chrome, .firefox])

        let filtered = BrowserCookieImportAllowlist.filter(
            [.safari, .chrome, .firefox, .comet, .yandex],
            userDefaults: suite)
        #expect(filtered == [.safari, .chrome, .firefox])
    }

    @Test
    func `browser cookie import allowlist can explicitly opt into comet`() {
        let suite = UserDefaults(suiteName: "BrowserCookieOrderLabelTests-comet-opt-in")!
        suite.set([Browser.chrome.rawValue, Browser.comet.rawValue], forKey: BrowserCookieImportAllowlist.defaultsKey)
        defer { suite.removeObject(forKey: BrowserCookieImportAllowlist.defaultsKey) }

        let filtered = BrowserCookieImportAllowlist.filter(
            [.safari, .chrome, .firefox, .comet, .yandex],
            userDefaults: suite)
        #expect(filtered == [.chrome, .comet])
    }

    @Test
    func `claude automatic cookies use privacy first default browser order`() throws {
        let order = try #require(ProviderDefaults.metadata[.claude]?.browserCookieOrder)
        #expect(order == ProviderBrowserCookieDefaults.defaultImportOrder)
        #expect(!order.contains(.comet))
    }

    @Test
    func `cursor no session includes browser login hint`() {
        let order = ProviderDefaults.metadata[.cursor]?.browserCookieOrder ?? Browser.defaultImportOrder
        let message = CursorStatusProbeError.noSessionCookie.errorDescription ?? ""
        #expect(message.contains(order.loginHint))
    }

    @Test
    func `cursor no session shows full disk access hint before browser list`() throws {
        let order = ProviderDefaults.metadata[.cursor]?.browserCookieOrder ?? Browser.defaultImportOrder
        let message = try #require(CursorStatusProbeError.noSessionCookie.errorDescription)
        let fullDiskAccessRange = try #require(message.range(of: CursorStatusProbeError.safariFullDiskAccessHint))
        let browserListRange = try #require(message.range(of: order.loginHint))

        #expect(fullDiskAccessRange.lowerBound < browserListRange.lowerBound)
    }

    @Test
    func `factory no session includes browser login hint`() {
        let order = ProviderDefaults.metadata[.factory]?.browserCookieOrder ?? Browser.defaultImportOrder
        let message = FactoryStatusProbeError.noSessionCookie.errorDescription ?? ""
        #expect(message.contains(order.loginHint))
    }

    @Test
    func `opencode go automatic cookies use privacy first provider browser order`() {
        let order = OpenCodeWebCookieSupport.automaticImportOrder(provider: .opencodego)
        #expect(order == ProviderDefaults.metadata[.opencodego]?.browserCookieOrder)
        #expect(order.contains(.firefox))
        #expect(!order.contains(.comet))
    }

    @Test
    func `opencode automatic cookies keep chrome only default`() {
        #expect(OpenCodeWebCookieSupport.automaticImportOrder(provider: .opencode) == [.chrome])
    }

    @Test
    func `mimo cookie import order supports safari firefox and edge`() {
        let order = ProviderDefaults.metadata[.mimo]?.browserCookieOrder ?? Browser.defaultImportOrder
        #expect(order == ProviderBrowserCookieDefaults.mimoCookieImportOrder)
        #expect(order == [.safari, .chrome, .chromeBeta, .chromeCanary, .firefox, .edge])
        #expect(order.first == .safari)
        #expect(order.contains(.firefox))
        #expect(order.contains(.edge))
        #expect(!order.contains(.arc))
    }

    @Test
    func `copilot cookie imports default to chrome only`() {
        #expect(ProviderDefaults.metadata[.copilot]?.browserCookieOrder == [.chrome])
        #expect(ProviderBrowserCookieDefaults.copilotCookieImportOrder == [.chrome])
    }
    #endif
}
