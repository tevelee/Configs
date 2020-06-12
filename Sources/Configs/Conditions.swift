import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

public struct ConfigCondition {
    public var isEnabled: () -> Bool
    public init(isEnabled: @escaping () -> Bool) {
        self.isEnabled = isEnabled
    }
}

private struct ConfigFilter<ValueToReturn: Configurable> {
    let condition: ConfigCondition
    let valueToReturn: () -> ValueToReturn
}

extension ConfigFilter: ValueProvider {
    typealias Value = ValueToReturn
    public func value() -> ValueOverride<Value>? {
        if condition.isEnabled() {
            return .override(valueToReturn())
        } else {
            return .noOverride
        }
    }
    var objectWillChange: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }
}

public extension ConfigDefinition {
    func when(_ condition: ConfigCondition, return value: @autoclosure @escaping () -> Value) -> ConfigDefinition {
        let filter = ConfigFilter(condition: condition, valueToReturn: value)
        return ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(filter)])
    }
    
    func when(_ condition: @escaping () -> Bool, return value: @autoclosure @escaping () -> Value) -> ConfigDefinition {
        let filter = ConfigFilter(condition: ConfigCondition(isEnabled: condition), valueToReturn: value)
        return ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(filter)])
    }
}

public extension ConfigCondition {
    struct DeviceType: OptionSet {
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public let rawValue: Int
        public static let iPhone = DeviceType(rawValue: 1 << 0)
        public static let iPad = DeviceType(rawValue: 1 << 1)
        public static let tv = DeviceType(rawValue: 1 << 2)
    }
    
    static func deviceType(is type: DeviceType, device: UIDevice = .current) -> ConfigCondition {
        ConfigCondition {
            switch device.userInterfaceIdiom {
                case .pad: return type.contains(.iPad)
                case .phone: return type.contains(.iPhone)
                case .tv: return type.contains(.tv)
                default: return false
            }
        }
    }
}
