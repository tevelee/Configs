//
//  ContentView.swift
//  Configs-Example
//
//  Created by László Teveli on 2020. 06. 04..
//  Copyright © 2020. Laszlo Teveli. All rights reserved.
//

import SwiftUI
import Tweaks
import Configs
import Combine

struct ContentView: View {
    @ObservedObject var configRepo = ConfigRepository.shared
    @State var showTweaks = false
    
    var body: some View {
        VStack {
            Spacer()
            Text("Hello!")
            Text("The value is: ") + Text(String(configRepo[.numberOfFreeItems]))
            Spacer()
            Button(action: { self.showTweaks = true }) {
                Text("Open Tweaks")
            }
            Spacer()
        }
        .sheet(isPresented: $showTweaks) {
            TweaksView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
