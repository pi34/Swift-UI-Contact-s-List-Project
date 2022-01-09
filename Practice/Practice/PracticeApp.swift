//
//  PracticeApp.swift
//  Practice
//
//  Created by Riya Manchanda on 03/06/21.
//

import SwiftUI

@main
struct PracticeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
