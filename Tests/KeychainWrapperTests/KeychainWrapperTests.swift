import XCTest
@testable import KeychainWrapper

final class KeychainWrapperTests: XCTestCase {
    func testExample() throws {
        // 暂时不好做测试
        KeychainWrapper.configDefault(with: "***", accessGroup: nil)
        KeychainWrapper.set("value", for: "key")
        let value = KeychainWrapper.string(for: "key")
        KeychainWrapper.delete(valueFor: "key")
        
        KeychainWrapper.add(account: "username", with: "password", encryptKey: "encryptKey")
        let accountList = KeychainWrapper.accountList(encryptKey: "encryptKey")
        let password = KeychainWrapper.password(for: "username", encryptKey: "encryptKey")
        KeychainWrapper.delete(account: "username")
        
        let keychain = KeychainWrapper(with: "***")
    }
}
