# KeychainWrapper

KeychainWrapper 是一个类型安全的 Keychain 存取包装器，支持字符串、数值、可编解码对象以及账号密码管理。

[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-6.2-brightgreen.svg)](https://swift.org)

## 依赖

- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+
- Swift 6.2+

## 功能特性

- 类型安全的 Keychain 存取接口
- 支持字符串、数值、可编解码对象
- 账号密码管理，支持加密存储
- 通过 `accessGroup` 实现跨 App 共享数据
- 全面的线程安全保护，所有读写操作通过串行队列串行化
- 符合 `Sendable` 协议，可安全跨 Actor 传递

## 安装

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

在项目中的 Package.swift 文件添加如下依赖:

```swift
dependencies: [
    .package(url: "https://gogs.miejoy.com:4443/Swift/keychain-wrapper.git", branch: "master"),
]
```

## 使用

### 默认包装器使用

1、配置默认包装器

```swift
import KeychainWrapper

// 配置默认包装器，必须先调用这个才能使用静态方法
KeychainWrapper.configDefault(with: "com.myapp", accessGroup: nil)
```

2、数据存取

```swift
// 保存字符串
KeychainWrapper.set("secret_token", for: "accessToken")

// 读取字符串
let token = KeychainWrapper.string(for: "accessToken")

// 保存对象（需实现 Codable 和 Sendable）
struct User: Codable, Sendable {
    let id: String
    let name: String
}
KeychainWrapper.set(User(id: "1", name: "Test"), for: "currentUser")

// 读取对象
let user: User? = KeychainWrapper.object(for: "currentUser", as: User.self)

// 删除
KeychainWrapper.delete(valueFor: "accessToken")

// 清空所有普通数据（不包含账号数据）
KeychainWrapper.wipeDatas()

// 清空所有数据（包含账号数据）
KeychainWrapper.wipeAll()
```

3、账号密码管理

```swift
// 添加账号（encryptKey 可选，用于加密存储）
KeychainWrapper.add(account: "username", with: "password", encryptKey: nil)

// 获取账号列表
let accounts = KeychainWrapper.accountList(encryptKey: nil)

// 获取账号密码
let password = KeychainWrapper.password(for: "username", encryptKey: nil)

// 删除账号
KeychainWrapper.delete(account: "username")

// 清空所有账号
KeychainWrapper.wipeAccounts()
```

### 独立包装器使用

```swift
import KeychainWrapper

// 创建独立包装器
let keychain = KeychainWrapper(with: "com.myapp", accessGroup: nil)

// 数据存取
keychain.set("value", for: "key")
let value = keychain.string(for: "key")
keychain.delete(valueFor: "key")

// 账号管理
keychain.add(account: "username", with: "password", encryptKey: nil)
let password = keychain.password(for: "username", encryptKey: nil)
```

### 自定义 JSON 编解码器

```swift
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

// 配置默认包装器时指定
KeychainWrapper.configDefault(
    with: "com.myapp",
    accessGroup: nil,
    jsonEncoder: encoder,
    jsonDecoder: decoder
)

// 或创建独立包装器时指定
let keychain = KeychainWrapper(
    with: "com.myapp",
    accessGroup: nil,
    jsonEncoder: encoder,
    jsonDecoder: decoder
)
```

## 注意事项

### macOS App Sandbox

KeychainWrapper 内部使用 `kSecAttrGeneric` 作为数据标识键（而非标准的 `kSecAttrAccount`）。在 macOS App Sandbox 环境下，这种方式写入 Keychain 会失败（`SecItemAdd` 返回非 0 错误码，`set` 方法返回 `false`）。

**解决方案**（二选一）：

1. 关闭 App Sandbox：在 Xcode Build Settings 中设置 `ENABLE_APP_SANDBOX = NO`（对 iOS 无影响，iOS 天然沙盒）
2. 配置 Keychain Sharing entitlement：在 entitlements 文件中声明 `keychain-access-groups`

> 注意：iOS 不受此问题影响，仅影响 macOS 目标和 macOS Catalyst。

### 初始化顺序

使用静态方法前**必须**先调用 `configDefault`，否则会触发 `fatalError`。建议在 App 启动时（如 `application(_:didFinishLaunchingWithOptions:)` 或 SwiftUI 的 init 阶段）完成配置。

```swift
// AppDelegate 或 LaunchManager 中
KeychainWrapper.configDefault(with: Bundle.main.bundleIdentifier ?? "com.myapp", accessGroup: nil)
```

## 作者

黄磊, raymond0huang@gmail.com

## License

KeychainWrapper is available under the MIT license. See the LICENSE file for more info.
