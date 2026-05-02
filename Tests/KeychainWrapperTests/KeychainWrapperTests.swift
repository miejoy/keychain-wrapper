import Foundation
import Testing
@testable import KeychainWrapper

struct TestUser: Codable, Equatable {
    let id: Int
    let name: String
}

@Suite(.serialized)
struct KeychainWrapperTests {

    private let serviceName = "com.miejoy.app"

    init() {
        DispatchQueue.syncOnKeychainQueue {
            if KeychainWrapper._default == nil {
                KeychainWrapper.configDefault(with: serviceName, accessGroup: nil)
            }
            KeychainWrapper.wipeAll()
        }
    }

    private func cleanup(_ keychain: KeychainWrapper = KeychainWrapper.default) {
        keychain.wipeAll()
    }

    // MARK: - String Tests

    @Test
    mutating func testSetAndGetString() {
        defer { cleanup() }
        #expect(KeychainWrapper.string(for: "testString") == nil)
        #expect(KeychainWrapper.set("Hello World", for: "testString"))
        #expect(KeychainWrapper.string(for: "testString") == "Hello World")
    }

    @Test
    mutating func testUpdateString() {
        defer { cleanup() }
        #expect(KeychainWrapper.string(for: "testStringUpdate") == nil)
        #expect(KeychainWrapper.set("First", for: "testStringUpdate"))
        #expect(KeychainWrapper.string(for: "testStringUpdate") == "First")

        #expect(KeychainWrapper.set("Second", for: "testStringUpdate"))
        #expect(KeychainWrapper.string(for: "testStringUpdate") == "Second")
    }

    @Test
    mutating func testDeleteString() {
        defer { cleanup() }
        #expect(KeychainWrapper.string(for: "testStringDelete") == nil)
        #expect(KeychainWrapper.set("value", for: "testStringDelete"))
        #expect(KeychainWrapper.string(for: "testStringDelete") == "value")

        #expect(KeychainWrapper.delete(valueFor: "testStringDelete"))
        #expect(KeychainWrapper.string(for: "testStringDelete") == nil)
    }

    @Test
    mutating func testStringForNonexistentKey() {
        defer { cleanup() }
        #expect(KeychainWrapper.string(for: "nonexistent") == nil)
    }

    // MARK: - Numeric Tests

    @Test
    mutating func testSetAndGetInt() {
        defer { cleanup() }
        #expect(KeychainWrapper.number(for: "testInt", as: Int.self) == nil)
        #expect(KeychainWrapper.set(42, for: "testInt"))
        #expect(KeychainWrapper.number(for: "testInt", as: Int.self) == 42)
    }

    @Test
    mutating func testSetAndGetDouble() {
        defer { cleanup() }
        #expect(KeychainWrapper.number(for: "testDouble", as: Double.self) == nil)
        #expect(KeychainWrapper.set(3.14159, for: "testDouble"))
        #expect(KeychainWrapper.number(for: "testDouble", as: Double.self) == 3.14159)
    }

    // MARK: - Data Tests

    @Test
    mutating func testSetAndGetData() {
        defer { cleanup() }
        #expect(KeychainWrapper.data(for: "testData") == nil)

        let value = "Test Data".data(using: .utf8)!
        #expect(KeychainWrapper.set(value, for: "testData"))
        #expect(KeychainWrapper.data(for: "testData") == value)
    }

    // MARK: - Codable Tests

    @Test
    mutating func testSetAndGetCodable() {
        defer { cleanup() }
        #expect(KeychainWrapper.object(for: "testCodable", as: TestUser.self) == nil)

        let user = TestUser(id: 1, name: "Test")
        #expect(KeychainWrapper.set(user, for: "testCodable"))
        #expect(KeychainWrapper.object(for: "testCodable", as: TestUser.self) == user)
    }

    // MARK: - Account Tests

    @Test
    mutating func testAddAndGetAccount() {
        defer { cleanup() }
        #expect(KeychainWrapper.password(for: "testuser", encryptKey: nil) == nil)

        #expect(KeychainWrapper.add(account: "testuser", with: "testpassword", encryptKey: nil))
        #expect(KeychainWrapper.password(for: "testuser", encryptKey: nil) == "testpassword")
        #expect(KeychainWrapper.accountList(encryptKey: nil).contains("testuser"))
    }

    @Test
    mutating func testUpdateAccount() {
        defer { cleanup() }
        #expect(KeychainWrapper.password(for: "testuserupdate", encryptKey: nil) == nil)

        #expect(KeychainWrapper.add(account: "testuserupdate", with: "password1", encryptKey: nil))
        #expect(KeychainWrapper.password(for: "testuserupdate", encryptKey: nil) == "password1")

        #expect(KeychainWrapper.add(account: "testuserupdate", with: "password2", encryptKey: nil))
        #expect(KeychainWrapper.password(for: "testuserupdate", encryptKey: nil) == "password2")
    }

    @Test
    mutating func testDeleteAccount() {
        defer { cleanup() }
        #expect(KeychainWrapper.password(for: "testuserdelete", encryptKey: nil) == nil)

        #expect(KeychainWrapper.add(account: "testuserdelete", with: "password", encryptKey: nil))
        #expect(KeychainWrapper.password(for: "testuserdelete", encryptKey: nil) == "password")

        #expect(KeychainWrapper.delete(account: "testuserdelete"))
        #expect(KeychainWrapper.password(for: "testuserdelete", encryptKey: nil) == nil)
        #expect(!KeychainWrapper.accountList(encryptKey: nil).contains("testuserdelete"))
    }

    @Test
    mutating func testWipeAccounts() {
        defer { cleanup() }
        #expect(KeychainWrapper.accountList(encryptKey: nil).isEmpty)

        #expect(KeychainWrapper.add(account: "user1", with: "pass1", encryptKey: nil))
        #expect(KeychainWrapper.accountList(encryptKey: nil).contains("user1"))

        #expect(KeychainWrapper.add(account: "user2", with: "pass2", encryptKey: nil))
        #expect(KeychainWrapper.accountList(encryptKey: nil).contains("user2"))
        
        #expect(KeychainWrapper.add(account: "user3", with: "pass3", encryptKey: nil))
        #expect(KeychainWrapper.accountList(encryptKey: nil).contains("user3"))

        KeychainWrapper.wipeAccounts()
        #expect(KeychainWrapper.accountList(encryptKey: nil).isEmpty)
    }

    // MARK: - WipeAll Tests

    @Test
    mutating func testWipeDatas() {
        defer { cleanup() }
        #expect(KeychainWrapper.string(for: "key1") == nil)
        #expect(KeychainWrapper.string(for: "key2") == nil)
        #expect(KeychainWrapper.number(for: "key3", as: Int.self) == nil)

        #expect(KeychainWrapper.set("value1", for: "key1"))
        #expect(KeychainWrapper.string(for: "key1") == "value1")

        #expect(KeychainWrapper.set("value2", for: "key2"))
        #expect(KeychainWrapper.string(for: "key2") == "value2")

        #expect(KeychainWrapper.set(123, for: "key3"))
        #expect(KeychainWrapper.number(for: "key3", as: Int.self) == 123)

        #expect(KeychainWrapper.wipeDatas())
        #expect(KeychainWrapper.string(for: "key1") == nil)
        #expect(KeychainWrapper.string(for: "key2") == nil)
        #expect(KeychainWrapper.number(for: "key3", as: Int.self) == nil)
    }

    // MARK: - Concurrent Tests

    @Test
    mutating func testConcurrentReadWrite() async {
        defer { cleanup() }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for i in 0..<100 {
                    _ = KeychainWrapper.set("value_\(i)", for: "concurrentKey")
                }
            }
            group.addTask {
                for _ in 0..<100 {
                    _ = KeychainWrapper.string(for: "concurrentKey")
                }
            }
            group.addTask {
                for i in 0..<100 {
                    _ = KeychainWrapper.delete(valueFor: "key_\(i)")
                }
            }
        }

        let result = KeychainWrapper.string(for: "concurrentKey")
        #expect(result != nil)
        if let result = result {
            #expect(result.hasPrefix("value_"))
        }
    }

    @Test
    mutating func testConcurrentAccountAccess() async {
        defer { cleanup() }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for i in 0..<50 {
                    _ = KeychainWrapper.add(account: "user_\(i)", with: "pass_\(i)", encryptKey: nil)
                }
            }
            group.addTask {
                for _ in 0..<50 {
                    _ = KeychainWrapper.accountList(encryptKey: nil)
                }
            }
            group.addTask {
                for i in 0..<50 {
                    _ = KeychainWrapper.delete(account: "user_\(i)")
                }
            }
        }
    }

    // MARK: - Instance Method Tests

    @Test
    mutating func testInstanceSetAndGet() {
        let keychain = KeychainWrapper(with: serviceName + #function)
        defer { cleanup(keychain) }

        #expect(keychain.string(for: "instanceKey") == nil)
        #expect(keychain.set("instanceValue", for: "instanceKey"))
        #expect(keychain.string(for: "instanceKey") == "instanceValue")
    }

    @Test
    mutating func testInstanceDelete() {
        let keychain = KeychainWrapper(with: serviceName + #function)
        defer { cleanup(keychain) }

        #expect(keychain.string(for: "instanceDeleteKey") == nil)

        #expect(keychain.set("value", for: "instanceDeleteKey"))
        #expect(keychain.string(for: "instanceDeleteKey") == "value")

        #expect(keychain.delete(valueFor: "instanceDeleteKey"))
        #expect(keychain.string(for: "instanceDeleteKey") == nil)
    }

    // MARK: - Sendable Tests

    @Test
    func testKeychainWrapperIsSendable() {
        let keychain = KeychainWrapper(with: "com.test.sendable")

        func assertSendable<T: Sendable>(_ value: T) {}
        assertSendable(keychain)
    }
}
