//
//  KeychainWrapper.swift
//
//
//  Created by 黄磊 on 2020-07-14.
//

import Foundation
import LocalAuthentication

/// Keychain 数据存储包装器
///
/// 提供类型安全的 Keychain 存取接口，支持字符串、数值、可编解码对象以及账号密码管理。
/// 通过配置 `accessGroup` 可实现跨 App 共享数据。
///
/// ## 基本用法
///
/// ```swift
/// // 配置默认实例
/// KeychainWrapper.configDefault(with: "com.myapp", accessGroup: nil)
///
/// // 存取字符串
/// KeychainWrapper.set("secret_token", for: "accessToken")
/// let token = KeychainWrapper.string(for: "accessToken")
///
/// // 存取对象
/// KeychainWrapper.set(user, for: "currentUser")
/// let savedUser: User? = KeychainWrapper.object(for: "currentUser", as: User.self)
/// ```
public final class KeychainWrapper: Sendable {
    
    /// 服务名称，一般为 bundleIdentifier
    let serviceName: String
    /// 服务名称，一般为 bundleIdentifier
    let accountServiceName: String
    /// 授权组，用于实现多APP共享，由 teamId+GroupId 组成
    let accessGroup: String?
    let accountKey: String
    let jsonEncoder: JSONEncoder
    let jsonDecoder: JSONDecoder
    
    // MARK: - Static Default Instance
    
    /// 默认实例（线程安全存储）
    nonisolated(unsafe) static var _default: KeychainWrapper?
    
    /// 获取默认实例
    ///
    /// 使用前必须先调用 `configDefault(with:accessGroup:accountKey:)` 进行配置。
    public static var `default`: KeychainWrapper {
        DispatchQueue.syncOnKeychainQueue {
            guard let theDefault = _default else {
                fatalError("You need call configDefault(with:accessGroup:accountKey:) first")
            }
            return theDefault
        }
    }
    
    /// 配置默认钥匙串包装器，设置后可直接使用静态方法调用
    ///
    /// - Parameters:
    ///   - serviceName: 要连接的服务名，相当于数据库名，一般用 bundleId
    ///   - accessGroup: 共享组 ID，访问跨 App 共享数据必备，一般为 teamId + groupId
    ///   - accountKey: 保存账户数据用的 服务名后缀，如果不使用 account 方法可以不设置，默认是 .accounts
    ///   - jsonEncoder: JSON 编码器，默认使用 JSONEncoder()
    ///   - jsonDecoder: JSON 解码器，默认使用 JSONDecoder()
    public static func configDefault(with serviceName: String,
                                     accessGroup: String?,
                                     accountKey: String = ".accounts",
                                     jsonEncoder: JSONEncoder = JSONEncoder(),
                                     jsonDecoder: JSONDecoder = JSONDecoder()) {
        DispatchQueue.syncOnKeychainQueue {
            if _default != nil {
                print("Config default KeychainWrapper twice")
            }
            _default = .init(with: serviceName, accessGroup: accessGroup, accountKey: accountKey, jsonEncoder: jsonEncoder, jsonDecoder: jsonDecoder)
        }
    }
    
    // MARK: - Init
    
    /// 初始化一个钥匙串包装器
    ///
    /// - Parameters:
    ///   - serviceName: 要连接的服务名，相当于数据库名，一般用 bundleId
    ///   - accessGroup: 共享组 ID，访问跨 App 共享数据必备，一般为 teamId + groupId
    ///   - accountKey: 保存账户数据用的 服务名后缀，如果不使用 account 方法可以不设置，默认是 .accounts
    ///   - jsonEncoder: JSON 编码器，默认使用 JSONEncoder()
    ///   - jsonDecoder: JSON 解码器，默认使用 JSONDecoder()
    public init(with serviceName: String,
                accessGroup: String? = nil,
                accountKey: String = ".accounts",
                jsonEncoder: JSONEncoder = JSONEncoder(),
                jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.serviceName = serviceName
        self.accountServiceName = serviceName + accountKey
        self.accessGroup = accessGroup
        self.accountKey = accountKey
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }
    
    /// 构建基础查询字典
    private func makeBaseQuery() -> [String: Any] {
        var dic: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.serviceName
        ]
        if let accessGroup = self.accessGroup {
            dic[kSecAttrAccessGroup as String] = accessGroup
        }
        return dic
    }
    
    /// 构建基础查询字典
    private func makeAccountQuery() -> [String: Any] {
        var dic: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.accountServiceName
        ]
        if let accessGroup = self.accessGroup {
            dic[kSecAttrAccessGroup as String] = accessGroup
        }
        return dic
    }
    
    // MARK: - Public
    
    // MARK: -Set
    /// 保存对应 key 的字符串数据，如果对应数据已存在，将会被覆盖
    ///
    /// - Parameters:
    ///   - value: 要保存的数据
    ///   - key: 保存数据对应的 key
    /// - Returns: 如果保存成功返回 true
    @discardableResult
    @inlinable
    public static func set(_ value: String, for key: String) -> Bool {
        return self.default.set(value, for: key)
    }
    
    /// 保存对应 key 的数字数据，如果对应数据已存在，将会被覆盖
    ///
    /// - Parameters:
    ///   - value: 要保存的数据
    ///   - key: 保存数据对应的 key
    /// - Returns: 如果保存成功返回 true
    @discardableResult
    @inlinable
    public static func set<T: Numeric & Codable>(_ value: T, for key: String) -> Bool {
        return self.default.set(value, for: key)
    }
    
    /// 保存对应 key 的可编解码数据，如果对应数据已存在，将会被覆盖
    ///
    /// - Parameters:
    ///   - value: 要保存的数据
    ///   - key: 保存数据对应的 key
    /// - Returns: 如果保存成功返回 true
    @discardableResult
    @inlinable
    public static func set<T: Codable>(_ value: T, for key: String) -> Bool {
        return self.default.set(value, for: key)
    }
    
    /// 保存对应 key 的数据，如果对应数据已存在，将会被覆盖
    ///
    /// - Parameters:
    ///   - value: 要保存的数据
    ///   - key: 保存数据对应的 key
    /// - Returns: 如果保存成功返回 true
    @discardableResult
    @inlinable
    public static func set(_ value: Data, for key: String) -> Bool {
        return self.default.set(value, for: key)
    }
    
    // MARK: -Get
    
    /// 获取对于 key 的字符串数据
    ///
    /// - Parameter key: 获取数据对应的 key
    /// - Returns: 如果存在返回对应字符串数据
    @inlinable
    public static func string(for key:String) -> String? {
        return self.default.string(for: key)
    }
    
    /// 获取对于 key 的数值数据
    ///
    /// - Parameter key: 获取数据对应的 key
    /// - Returns: 如果存在返回对应数值数据
    @inlinable
    public static func number<T:Numeric & Codable>(for key:String, as type: T.Type) -> T? {
        return self.default.number(for: key, as: T.self)
    }
    
    /// 获取对于 key 的可编解码数据
    ///
    /// - Parameter key: 获取数据对应的 key
    /// - Returns: 如果存在返回对应可编解码数据
    @inlinable
    public static func object<T:Codable>(for key:String, as type: T.Type) -> T? {
        return self.default.object(for: key, as: T.self)
    }
    
    /// 获取对于 key 的可编解码数据
    ///
    /// - Parameter key: 获取数据对应的 key
    /// - Returns: 如果存在返回对应可编解码数据
    @inlinable
    public static func data(for key:String) -> Data? {
        return self.default.data(for: key)
    }
    
    // MARK: -Delete
    /// 删除对应 key 的数据
    ///
    /// - Parameter key: 要删除数据对应的 key
    /// - Returns: 如果删除成功返回 true
    @discardableResult
    @inlinable
    public static func delete(valueFor key: String) -> Bool {
        return self.default.delete(valueFor: key)
    }
    
    /// 清空所有 keychain 保存数据
    ///
    /// - Warning: 该方法会清空当前 serviceName 和  accountServiceName下所有保存数据，包括 账号数据
    /// - Returns: 如果成功返回 true
    @discardableResult
    @inlinable
    public static func wipeAll() -> Bool {
        return self.default.wipeAll()
    }
    
    /// 清空 keychain 保存所有数据
    ///
    /// - Warning: 该方法会清空当前 serviceName 下所有保存数据
    /// - Returns: 如果成功返回 true
    @discardableResult
    @inlinable
    public static func wipeDatas() -> Bool {
        return self.default.wipeDatas()
    }
    
    // MARK: - Public Account
    
    /// 添加新账号到 keychain 保存，如果已存在会覆盖
    ///
    /// - Parameters:
    ///   - account: 添加的账号
    ///   - password: 账号对应的密码
    ///   - encryptKey: 密码加密字符串
    /// - Returns: 如果成功返回 true
    @discardableResult
    @inlinable
    public static func add(account: String, with password: String, encryptKey: String?) -> Bool {
        return self.default.add(account: account, with: password, encryptKey: encryptKey)
    }
    
    /// 获取账号列表
    ///
    /// - Parameter encryptKey: 密码加密字符串
    /// - Returns: 返回包含账号的列表
    @inlinable
    public static func accountList(encryptKey: String?) -> [String] {
        return self.default.accountList(encryptKey: encryptKey)
    }
    
    /// 获取对于账号的密码
    ///
    /// - Parameters:
    ///   - account: 要获取密码的账号
    ///   - encryptKey: 密码加密字符串
    /// - Returns: 如果存在，返回对应密码
    @inlinable
    public static func password(for account: String, encryptKey: String?) -> String? {
        return self.default.password(for: account, encryptKey: encryptKey)
    }
    
    /// 删除对应账号
    ///
    /// - Parameter account: 要删除的账号
    /// - Returns: 如果成功返回 true
    @discardableResult
    @inlinable
    public static func delete(account: String) -> Bool {
        return self.default.delete(account: account)
    }
    
    /// 清空所有账号
    ///
    /// - Returns: 如果成功返回 true
    @discardableResult
    @inlinable
    public static func wipeAccounts() -> Bool {
        return self.default.wipeAccounts()
    }
    
    // MARK: - Instance Func
    
    // MARK: -Set
    /// 保存对应 key 的字符串数据，如果对应数据已存在，将会被覆盖
    ///
    /// - Parameters:
    ///   - value: 要保存的数据
    ///   - key: 保存数据对应的 key
    /// - Returns: 如果保存成功返回 true
    @discardableResult
    public func set(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return set(data, for: key)
    }
    
    /// 保存对应 key 的数字数据，如果对应数据已存在，将会被覆盖
    ///
    /// - Parameters:
    ///   - value: 要保存的数据
    ///   - key: 保存数据对应的 key
    /// - Returns: 如果保存成功返回 true
    @discardableResult
    public func set<T: Numeric & Codable>(_ value: T, for key: String) -> Bool {
        guard let data = try? jsonEncoder.encode([value]) else { return false }
        return set(data, for: key)
    }
    
    /// 保存对应 key 的可编解码数据，如果对应数据已存在，将会被覆盖
    ///
    /// - Parameters:
    ///   - value: 要保存的数据
    ///   - key: 保存数据对应的 key
    /// - Returns: 如果保存成功返回 true
    @discardableResult
    public func set<T: Codable>(_ value: T, for key: String) -> Bool {
        guard let data = try? jsonEncoder.encode(value) else { return false }
        return set(data, for: key)
    }
    
    /// 设置
    @discardableResult
    public func set(_ value: Data, for key: String) -> Bool {
        // 先要检查是否存在
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeBaseQuery()
            dicQuery[kSecAttrAccount as String] = key
            
            var dicAdd = dicQuery
            dicAdd[kSecValueData as String] = value
            var status = SecItemAdd(dicAdd as CFDictionary, nil)
            if status == errSecDuplicateItem {
                // 更新
                let update = [kSecValueData as String : value]
                status = SecItemUpdate(dicQuery as CFDictionary, update as CFDictionary)
            }
            return status == errSecSuccess
        }
    }
    
    // MARK: -Get
    
    /// 获取对于 key 的字符串数据
    ///
    /// - Parameter key: 获取数据对应的 key
    /// - Returns: 如果存在返回对应字符串数据
    public func string(for key:String) -> String? {
        if let data = self.data(for: key) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    /// 获取对于 key 的数值数据
    ///
    /// - Parameter key: 获取数据对应的 key
    /// - Returns: 如果存在返回对应数值数据
    public func number<T:Numeric & Codable>(for key:String, as type: T.Type) -> T? {
        if let data = self.data(for: key) {
            let number = try? jsonDecoder.decode([T].self, from: data)
            return number?.first
        }
        return nil
    }
    
    /// 获取对于 key 的可编解码数据
    ///
    /// - Parameter key: 获取数据对应的 key
    /// - Returns: 如果存在返回对应可编解码数据
    public func object<T:Codable>(for key:String, as type: T.Type) -> T? {
        if let data = self.data(for: key) {
            return try? jsonDecoder.decode(T.self, from: data)
        }
        return nil
    }
    
    
    /// 获取对于 key 的数据
    public func data(for key: String) -> Data? {
        // 先要检查是否存在
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeBaseQuery()
            dicQuery[kSecAttrAccount as String] = key
            dicQuery[kSecReturnData as String] = kCFBooleanTrue
            dicQuery[kSecMatchLimit as String] = kSecMatchLimitOne
            
            var reslut : AnyObject?
            let status = SecItemCopyMatching(dicQuery as CFDictionary, &reslut)
            
            return status == errSecSuccess ? reslut as? Data : nil
        }
    }
    
    /// 获取对于 key 的数据的引用
    public func dataRef(for key: String) -> Data? {
        // 先要检查是否存在
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeBaseQuery()
            dicQuery[kSecAttrAccount as String] = key
            dicQuery[kSecReturnPersistentRef as String] = kCFBooleanTrue
            dicQuery[kSecMatchLimit as String] = kSecMatchLimitOne
            
            var reslut : AnyObject?
            let status = SecItemCopyMatching(dicQuery as CFDictionary, &reslut)
            
            return status == errSecSuccess ? reslut as? Data : nil
        }
    }
    
    // MARK: -Delete
    /// 删除对应 key 的数据
    ///
    /// - Parameter key: 要删除数据对应的 key
    /// - Returns: 如果删除成功返回 true
    public func delete(valueFor key: String) -> Bool {
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeBaseQuery()
            dicQuery[kSecAttrAccount as String] = key
            
            let status = SecItemDelete(dicQuery as CFDictionary)
            
            return (status == errSecSuccess)
        }
    }
    
    /// 清空所有数据
    @discardableResult
    public func wipeAll() -> Bool {
        return wipeDatas() && wipeAccounts()
    }
    
    /// 清空数据
    @discardableResult
    public func wipeDatas() -> Bool {
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeBaseQuery()
            dicQuery[kSecMatchLimit as String] = kSecMatchLimitAll
            let status = SecItemDelete(dicQuery as CFDictionary)
            return (status == errSecSuccess || status == errSecItemNotFound)
        }
    }
    
    
    // MARK: - Accout
    
    /// 添加新账号到 keychain 保存，如果已存在会覆盖
    ///
    /// - Parameters:
    ///   - account: 添加的账号
    ///   - password: 账号对应的密码
    ///   - encryptKey: 密码加密字符串
    /// - Returns: 如果成功返回 true
    public func add(account: String, with password: String, encryptKey: String?) -> Bool {
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeAccountQuery()
            dicQuery[kSecAttrAccount as String] = account
            
            self.assemble(query: &dicQuery, with: encryptKey)
            
            // 判断是否存在
            let value = password.data(using: .utf8)
            var dicAdd = dicQuery
            dicAdd[kSecValueData as String] = value
            var status = SecItemAdd(dicAdd as CFDictionary, nil)
            if status == errSecDuplicateItem {
                // 更新
                let update = [kSecValueData as String : value]
                status = SecItemUpdate(dicQuery as CFDictionary, update as CFDictionary)
            }
            return status == errSecSuccess
        }
    }
    
    /// 获取账号列表
    ///
    /// - Parameter encryptKey: 密码加密字符串
    /// - Returns: 返回包含账号的列表
    public func accountList(encryptKey: String?) -> [String] {
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeAccountQuery()
            dicQuery[kSecReturnAttributes as String] = kCFBooleanTrue
            dicQuery[kSecMatchLimit as String] = kSecMatchLimitAll
            
            self.assemble(query: &dicQuery, with: encryptKey)
            
            var results: AnyObject?
            let status = SecItemCopyMatching(dicQuery as CFDictionary, &results)
            
            guard status == errSecSuccess else { return [] }
            
            var arr = [String]()
            
            if let results = results as? [[String: AnyObject]] {
                arr = results.reduce(into: [String]()) { (result, attr) in
                    if let account = attr[kSecAttrAccount as String] as? String{
                        result.append(account)
                    }
                }
            }
            
            return arr
        }
    }

    /// 获取保存的账号密码
    public func password(for account: String, encryptKey: String?) -> String? {
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeAccountQuery()
            dicQuery[kSecAttrAccount as String] = account
            dicQuery[kSecReturnData as String] = kCFBooleanTrue
            dicQuery[kSecMatchLimit as String] = kSecMatchLimitOne
            
            self.assemble(query: &dicQuery, with: encryptKey)
            
            // 判断是否存在
            var reslut : AnyObject?
            let status = SecItemCopyMatching(dicQuery as CFDictionary, &reslut)
            if status == errSecSuccess, let data = reslut as? Data {
                return String(data: data, encoding: .utf8)
            }
            return nil
        }
    }
    
    /// 删除对应账号
    public func delete(account: String) -> Bool {
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeAccountQuery()
            dicQuery[kSecAttrAccount as String] = account
            
            let status = SecItemDelete(dicQuery as CFDictionary)
            
            return (status == errSecSuccess || status == errSecItemNotFound)
        }
    }
    
    /// 清空所有账号
    @discardableResult
    public func wipeAccounts() -> Bool {
        return DispatchQueue.syncOnKeychainQueue {
            var dicQuery = self.makeAccountQuery()
            dicQuery[kSecMatchLimit as String] = kSecMatchLimitAll
            let status = SecItemDelete(dicQuery as CFDictionary)
            
            return (status == errSecSuccess || status == errSecItemNotFound)
        }
    }
    
    /// 用加密字符串组装请求
    func assemble(query: inout [String:Any], with encryptKey: String?) {
        
        if let encryptKey = encryptKey {
            var err : Unmanaged<CFError>? = nil
            let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlocked, .applicationPassword, &err)
            if err != nil {
                return
            }
            let context = LAContext()
            context.setCredential(encryptKey.data(using: .utf8), type: .applicationPassword)
            query[kSecAttrAccessControl as String] = access
            query[kSecUseAuthenticationContext as String] = context
        }
        
    }
}

// MARK: - Keychain Queue

extension DispatchQueue {
    static let keychainQueueDispatchSpecificKey: DispatchSpecificKey<String> = .init()
    
    /// keychain 队列使用的锁
    static let keychainQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.miejoy.keychain_queue")
        queue.setSpecific(key: keychainQueueDispatchSpecificKey, value: queue.label)
        return queue
    }()
    
    /// 在 keychain 队列中执行
    static func syncOnKeychainQueue<T>(execute work: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: Self.keychainQueueDispatchSpecificKey) == Self.keychainQueue.label {
            return try work()
        }
        return try Self.keychainQueue.sync(execute: work)
    }
}

/*
 
 kSecClass              相当于确定表结构，当前使用 kSecClassGenericPassword
 kSecAttrService        相当于连接了哪个数据库，一般使用包名
 kSecAttrAccessGroup    相当于连接了哪个共享数据库，设置这个应该会忽略 kSecAttrService
 
 kSecAttrAccount        账号属性，这里我们在保存数据key或账号
 kSecValueData          保存的值，这里在保存账号时作为 Password ，其他情况作为 Value
 kSecAttrAccessible     访问权限，默认使用 kSecAttrAccessibleWhenUnlocked
 kSecUseAuthenticationContext   用于账号密码保存的授权设置 LAContext().setCredential(data, type: .applicationPassword)
 
 kSecReturnData         查询需要返回 kSecValueData 则设置为 true
 kSecReturnAttributes   查询需要返回所有属性 则设置为 true
 kSecMatchLimit         查询个数，可设置 kSecMatchLimitOne 或 kSecMatchLimitAll
 
 */
