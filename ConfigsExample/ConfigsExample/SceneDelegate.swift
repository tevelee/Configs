import UIKit
import SwiftUI
import Combine
import Tweaks
import Configs

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var cancellables: [AnyCancellable] = []

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = ContentView()
        
        let configRepo = ConfigRepository.shared
        configRepo.add(.secretNewInProgressFeatureFlag)
        configRepo.add(.backendBaseUrl)
        configRepo.add(.numberOfFreeItems)
        configRepo.add(.chartOffset)
        configRepo.add(.valuesForChart)
        configRepo.add(.myExperiment)
        TweakRepository.shared.add(.resetAction)
        TweakRepository.shared.add(.restartAction)
        
        let tweak = TweakDefinition(name: "Number of items", initialValue: 1, valueRenderer: InputAndStepperRenderer())
        TweakRepository.shared.add(tweak: tweak, category: "Product Settings", section: "Feature Settings")
        
        print(configRepo.isOn(.secretNewInProgressFeatureFlag))
        print(configRepo[.backendBaseUrl])
        
        configRepo.listen(to: .numberOfFreeItems) { value in
            print("Value changed: \(value)")
        }
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

