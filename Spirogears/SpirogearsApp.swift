//
//  SpirogearsApp.swift
//  Spirogears
//
//  Created by Sigrid Mortensen on 4/16/26.
//

import SwiftUI

@main
struct SpirogearsApp: App {
    @State private var subscriptionStore = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(subscriptionStore)
        }
    }
}
