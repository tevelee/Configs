import Foundation
import Tweaks
import Combine

public protocol ConfigRepositoryProtocol {
    subscript<Value: Configurable>(_ config: ConfigDefinition<Value>) -> Value { get }
    func add<Value>(_ config: ConfigDefinition<Value>) where Value: Configurable
    func add(_ config: ConfigDefinitionBase)
    func add(_ configs: [ConfigDefinitionBase])
    func listen<Value: Configurable>(to config: ConfigDefinition<Value>, valueChanged: @escaping (Value) -> Void) where Value: Equatable
}

public extension ConfigRepositoryProtocol {
    func isOn(_ config: ConfigDefinition<Bool>) -> Bool {
        self[config]
    }
    
    func isOff(_ config: ConfigDefinition<Bool>) -> Bool {
        !isOn(config)
    }
}

public class ConfigRepository: ConfigRepositoryProtocol, ObservableObject {
    public static let shared = ConfigRepository()
    var cancellables: [AnyCancellable] = []
    
    init() {}
    
    var definitions: [ConfigDefinitionBase] = []
    
    public func add(_ config: ConfigDefinitionBase) {
        definitions.append(config)
        
        config.objectWillChange
            .sink { _ in self.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    public func add<Value>(_ config: ConfigDefinition<Value>) where Value: Configurable {
        add(config)
    }
    
    public func add(_ configs: [ConfigDefinitionBase]) {
        for config in configs {
            add(config)
        }
    }
    
    public subscript<Value>(config: ConfigDefinition<Value>) -> Value where Value: Configurable {
        get {
//            print("Resolving config \(config.id)")
            for provider in config.providers.reversed() {
                if case let .override(value) = provider.value() {
//                    print("- provider \(provider.name) finds value \(value)")
                    return value
                } else {
//                    print("- provider \(provider.name) returns no value")
                }
            }
//            print("- falling back to default value \(config.defaultValue)")
            return config.defaultValue
        }
    }
    
    public func listen<Value: Configurable & Equatable>(to config: ConfigDefinition<Value>, valueChanged: @escaping (Value) -> Void) {
        config.objectWillChange
            .map { self[config] }
            .removeDuplicates()
            .sink(receiveValue: valueChanged)
            .store(in: &cancellables)
    }
}
