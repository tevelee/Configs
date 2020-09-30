import Foundation
import Combine
import SwiftUI

public enum ValueOverride<Value>: ExpressibleByNilLiteral {
    case noOverride
    case override(Value)
    
    public init(nilLiteral: ()) {
        self = .noOverride
    }
}

public protocol ValueProvider {
    associatedtype Value
    func value() -> ValueOverride<Value>?
    var objectWillChange: AnyPublisher<Void, Never> { get }
}

public struct AnyProvider<Value>: ValueProvider {
    let provider: () -> ValueOverride<Value>?
    var name: String
    public var objectWillChange: AnyPublisher<Void, Never>
    public func value() -> ValueOverride<Value>? {
        provider()
    }
}

public extension AnyProvider {
    init<Provider: ValueProvider>(_ p: Provider) where Provider.Value == Value {
        provider = p.value
        name = String(String(describing: type(of: p)).prefix { $0 != "<" })
        objectWillChange = p.objectWillChange
    }
}

public protocol Configurable {}

extension Bool: Configurable {}
extension String: Configurable {}
extension Int: Configurable {}
extension Double: Configurable {}
extension Optional: Configurable where Wrapped: Configurable {}
extension Array: Configurable where Element: Configurable {}
extension Color: Configurable {}

public protocol ConfigDefinitionBase {
    var objectWillChange: AnyPublisher<Void, Never> { get }
}

public struct ConfigDefinition<Value: Configurable>: ConfigDefinitionBase, Identifiable {
    public let id: String
    public let defaultValue: Value
    public let providers: [AnyProvider<Value>]
    
    public var objectWillChange: AnyPublisher<Void, Never> {
        Publishers.MergeMany(providers.map(\.objectWillChange)).eraseToAnyPublisher()
    }
    
    public init(id: String = UUID().uuidString, defaultValue: Value, providers: [AnyProvider<Value>] = []) {
        self.id = id
        self.defaultValue = defaultValue
        self.providers = providers
    }
}
