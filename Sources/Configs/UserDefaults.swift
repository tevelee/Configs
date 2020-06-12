import Foundation
import Combine

public protocol StorableInUserDefaults {
    init?(userDefaults: UserDefaults, key: String)
    func store(in userDefaults: UserDefaults, key: String)
}

public struct UserDefaultsKey<T: StorableInUserDefaults>: Hashable {
    let value: String
    public init(_ value: String) {
        self.value = value
    }
}

extension UserDefaultsKey: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

public extension UserDefaults {
    subscript<T: StorableInUserDefaults>(_ key: UserDefaultsKey<T>) -> T? {
        get {
            T(userDefaults: self, key: key.value)
        }
        set(value) {
            value?.store(in: self, key: key.value)
        }
    }
}

struct StaticValueProvider<StoredValue>: ValueProvider {
    let staticValue: StoredValue
    func value() -> ValueOverride<StoredValue>? {
        .override(self.staticValue)
    }
    var objectWillChange: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }
}

struct DynamicValueProvider<StoredValue>: ValueProvider {
    let provider: () -> StoredValue?
    func value() -> ValueOverride<StoredValue>? {
        if let value = provider() {
            return .override(value)
        } else {
            return .noOverride
        }
    }
    var objectWillChange: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }
}

struct UserDefaultsStoreProvider<StoredValue: StorableInUserDefaults> {
    let key: UserDefaultsKey<StoredValue>
    var userDefaults: UserDefaults = .standard
    let storageMechanism: StorageMechanism<StoredValue>
    var subject = PassthroughSubject<Void, Never>()
}

extension UserDefaultsStoreProvider: ValueProvider {
    typealias Value = StoredValue
    func value() -> ValueOverride<Value>? {
        if let data = userDefaults[key, using: storageMechanism] {
            return .override(data)
        }
        return .noOverride
    }
    var objectWillChange: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }
}

public struct StorageMechanism<Value> {
    public let store: (UserDefaults, String, Value?) throws -> Void
    public let retrieve: (UserDefaults, String) throws -> Value?

    public func pullback<Other>(transform: @escaping (Value) throws -> Other,
                         back: @escaping (Other) throws -> Value) -> StorageMechanism<Other> {
        StorageMechanism<Other>(store: { userDefaults, key, value in
            try self.store(userDefaults, key, value.map(back))
        }, retrieve: { userDefaults, key in
            try self.retrieve(userDefaults, key).map(transform)
        })
    }
}

extension StorageMechanism where Value == Data {
    public func json<V: Codable>() -> StorageMechanism<V> {
        pullback(transform: { try JSONDecoder().decode(V.self, from: $0) },
                 back: { try JSONEncoder().encode($0) })
    }
}

extension StorageMechanism where Value: StorableInUserDefaults {
    public static func `default`() -> StorageMechanism<Value> {
        StorageMechanism<Value>(store: { userDefaults, key, value in
            value.store(in: userDefaults, key: key)
        }, retrieve: { userDefaults, key in
            Value(userDefaults: userDefaults, key: key)
        })
    }
}

extension UserDefaults {
    subscript<V>(key: UserDefaultsKey<V>, using store: StorageMechanism<V>) -> V? {
        get {
            try? store.retrieve(self, key.value)
        }
        set(value) {
            try? store.store(self, key.value, value)
        }
    }
}

var globalCancellables: [AnyCancellable] = []

public extension ConfigDefinition {
    func `static`(value: Value) -> ConfigDefinition {
        ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(StaticValueProvider(staticValue: value))])
    }
    func dynamic(provider: @escaping () -> Value?) -> ConfigDefinition {
        ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(DynamicValueProvider(provider: provider))])
    }
}

public extension ConfigDefinition where Value: StorableInUserDefaults {
    func userDefaults(userDefaults: UserDefaults = .standard, key: UserDefaultsKey<Value>, storageMechanism: StorageMechanism<Value> = .default()) -> ConfigDefinition {
        let userDefaultsProvider = UserDefaultsStoreProvider<Value>(key: key, userDefaults: userDefaults, storageMechanism: storageMechanism)
        let subscription = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .subscribe(userDefaultsProvider.subject)
        globalCancellables += [subscription]
        return ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(userDefaultsProvider)])
    }
}

extension Optional: StorableInUserDefaults where Wrapped: StorableInUserDefaults {
    public init?(userDefaults: UserDefaults, key: String) {
        self = Wrapped(userDefaults: userDefaults, key: key)
    }
    public func store(in userDefaults: UserDefaults, key: String) {
        switch self {
        case .none:
            userDefaults.removeObject(forKey: key)
        case let .some(value):
            value.store(in: userDefaults, key: key)
        }
    }
}

extension Bool: StorableInUserDefaults {
    public init?(userDefaults: UserDefaults, key: String) {
        guard userDefaults.object(forKey: key) != nil else { return nil }
        self = userDefaults.bool(forKey: key)
    }
    public func store(in userDefaults: UserDefaults, key: String) {
        userDefaults.set(self, forKey: key)
    }
}

extension String: StorableInUserDefaults {
    public init?(userDefaults: UserDefaults, key: String) {
        guard let value = userDefaults.string(forKey: key) else { return nil }
        self = value
    }
    public func store(in userDefaults: UserDefaults, key: String) {
        userDefaults.setValue(self, forKey: key)
    }
}

extension Data: StorableInUserDefaults {
    public init?(userDefaults: UserDefaults, key: String) {
        guard let value = userDefaults.data(forKey: key) else { return nil }
        self = value
    }
    public func store(in userDefaults: UserDefaults, key: String) {
        userDefaults.setValue(self, forKey: key)
    }
}

extension Int: StorableInUserDefaults {
    public init?(userDefaults: UserDefaults, key: String) {
        guard userDefaults.object(forKey: key) != nil else { return nil }
        self = userDefaults.integer(forKey: key)
    }
    public func store(in userDefaults: UserDefaults, key: String) {
        userDefaults.set(self, forKey: key)
    }
}

extension Double: StorableInUserDefaults {
    public init?(userDefaults: UserDefaults, key: String) {
        guard userDefaults.object(forKey: key) != nil else { return nil }
        self = userDefaults.double(forKey: key)
    }
    public func store(in userDefaults: UserDefaults, key: String) {
        userDefaults.set(self, forKey: key)
    }
}

extension URL: StorableInUserDefaults {
    public init?(userDefaults: UserDefaults, key: String) {
        guard let url = userDefaults.url(forKey: key) else { return nil }
        self = url
    }
    public func store(in userDefaults: UserDefaults, key: String) {
        userDefaults.set(self, forKey: key)
    }
}

public extension StorableInUserDefaults where Self: Codable {
    init?(userDefaults: UserDefaults, key: String) {
        guard let data = userDefaults.data(forKey: key), let value = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = value
    }
    func store(in userDefaults: UserDefaults, key: String) {
        if let value = try? JSONEncoder().encode(self) {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}

public extension StorableInUserDefaults where Self: RawRepresentable, RawValue: StorableInUserDefaults {
    init?(userDefaults: UserDefaults, key: String) {
        guard let rawValue = RawValue(userDefaults: userDefaults, key: key) else { return nil }
        self.init(rawValue: rawValue)
    }
    func store(in userDefaults: UserDefaults, key: String) {
        rawValue.store(in: userDefaults, key: key)
    }
}

public extension StorableInUserDefaults where Self: LosslessStringConvertible {
    init?(userDefaults: UserDefaults, key: String) {
        guard let description = userDefaults.string(forKey: key) else { return nil }
        self.init(description)
    }
    func store(in userDefaults: UserDefaults, key: String) {
        description.store(in: userDefaults, key: key)
    }
}
