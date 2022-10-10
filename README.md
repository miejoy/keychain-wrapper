# KeychainWrapper

KeychainWrapper 主要是对 keychain 使用的包装器

[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-5.4-brightgreen.svg)](https://swift.org)

## 依赖

- iOS 13.0+ / macOS 10.15+
- Xcode 12.0+
- Swift 5.4+

## 简介

该模块主要是为了简化对 keychain 的使用，

## 安装

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

在项目中的 Package.swift 文件添加如下依赖:

```swift
dependencies: [
    .package(url: "https://github.com/miejoy/keychain-wrapper.git", from: "0.1.0"),
]
```

## 使用

### 默认包装器使用

1、初始化默认包装器

```swift
import KeychainWrapper

// 初始化默认包装器，必须先调用这个才能使用默认包装器
KeychainWrapper.configDefault(with: "***", accessGroup: nil)
```

2、使用默认包装器进行数据保存、读取、删除

```swift
// 保存
KeychainWrapper.set("value", for: "key")
// 读取
let value = KeychainWrapper.string(for: "key")
// 删除
KeychainWrapper.delete(valueFor: "key")
```

3、使用默认包装器进行账户添加、读取、删除

```swift
// 添加账户
KeychainWrapper.add(account: "username", with: "password", encryptKey: "encryptKey")
// 读取账户列表
let accountList = KeychainWrapper.accountList(encryptKey: "encryptKey")
// 读取账户对应密码
let password = KeychainWrapper.password(for: "username", encryptKey: "encryptKey")
// 删除账户
KeychainWrapper.delete(account: "username")
```

### 独立包装器使用

1、创建独立包装器

```swift
import KeychainWrapper

// 创建独立包装器
let keychain = KeychainWrapper(with: "***")
```

2、使用独立包装器进行数据保存、读取、删除

```swift
// 保存
keychain.set("value", for: "key")
// 读取
let value = keychain.string(for: "key")
// 删除
keychain.delete(valueFor: "key")
```

3、使用独立包装器进行账户添加、读取、删除

```swift
// 添加账户
keychain.add(account: "username", with: "password", encryptKey: "encryptKey")
// 读取账户列表
let accountList = keychain.accountList(encryptKey: "encryptKey")
// 读取账户对应密码
let password = keychain.password(for: "username", encryptKey: "encryptKey")
// 删除账户
keychain.delete(account: "username")
```

## 作者

Raymond.huang: raymond0huang@gmail.com

## License

KeychainWrapper is available under the MIT license. See the LICENSE file for more info.

