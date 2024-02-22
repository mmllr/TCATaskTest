//
//  TaskTestApp.swift
//  TaskTest
//
//  Created by Markus Müller on 22.02.24.
//

import SwiftUI

@main
struct TaskTestApp: App {
    var body: some Scene {
        WindowGroup {
            ListFeatureView(store: .init(initialState: ListFeature.State()) {
                ListFeature()
            })
        }
    }
}
