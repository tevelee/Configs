import Foundation
import Combine

public struct FirebaseConfigKey<T: ConfigurableInFirebase> {
    let value: String
    public init(_ value: String) {
        self.value = value
    }
}

extension FirebaseConfigKey: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

public protocol ConfigurableInFirebase {}
extension Int: ConfigurableInFirebase {}
extension Bool: ConfigurableInFirebase {}
extension String: ConfigurableInFirebase {}

struct FirebaseConfigProvider<StoredValue: ConfigurableInFirebase> {
    let key: FirebaseConfigKey<StoredValue>
}

extension FirebaseConfigProvider: ValueProvider {
    typealias Value = StoredValue
    func value() -> ValueOverride<Value>? {
        return .noOverride
    }
    var objectWillChange: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }
}

public extension ConfigDefinition where Value: ConfigurableInFirebase {
    func firebaseRemoteConfig(key: FirebaseConfigKey<Value>) -> ConfigDefinition {
        let firebaseProvider = FirebaseConfigProvider<Value>(key: key)
        return ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(firebaseProvider)])
    }
}
