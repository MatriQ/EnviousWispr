import Foundation
import Security
import Testing

@testable import EnviousWisprLLM

@Suite("Local build keychain", .serialized)
struct LocalBuildKeychainTests {
  @Test("Local builds can store, update and delete keys without a team entitlement")
  func localKeychainRoundTrip() throws {
    let service = "com.enviouswispr.tests.local-build.\(UUID().uuidString)"
    let account = "fixture"
    let original: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    var add = original
    add[kSecValueData as String] = Data("original-fixture".utf8)
    let status = SecItemAdd(add as CFDictionary, nil)
    try #require(status == errSecSuccess, "Login keychain unavailable: \(status)")
    let store = SecurityKeychainItemStore(useDataProtectionKeychain: false)
    defer {
      try? store.delete(service: service, account: account)
      _ = SecItemDelete(original as CFDictionary)
    }
    try store.store(service: service, account: account, value: "local-fixture")
    #expect(try store.retrieve(service: service, account: account) == "local-fixture")
    try store.store(service: service, account: account, value: "updated-中文-fixture")
    #expect(try store.retrieve(service: service, account: account) == "updated-中文-fixture")
    try store.delete(service: service, account: account)
    #expect(throws: KeyStoreError.self) {
      try store.retrieve(service: service, account: account)
    }
    // The local service is separate: deletion must not touch the original app's keys.
    var read = original
    read[kSecReturnData as String] = kCFBooleanTrue
    var result: CFTypeRef?
    #expect(SecItemCopyMatching(read as CFDictionary, &result) == errSecSuccess)
    #expect(result as? Data == Data("original-fixture".utf8))
  }
}
