//
//  NotesApp.swift
//  Notes
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI
import SwiftData

@main
struct NotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [NotesModel.self])
    }
}
