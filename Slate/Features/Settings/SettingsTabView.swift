//
//  SettingsTabView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI

struct SettingsTabView: View {
    @Environment(\.colorScheme) private var colorScheme

    //----------------- Start of UI Code -----------------//
    var body: some View {
        VStack {
            VStack {
                if colorScheme == .light {
                    Image("AppIconDark") // replace with your asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                        .shadow(radius: 6)
                } else {
                    Image("AppIconLight") // replace with your asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                        .shadow(radius: 6)
                }
                Text("Slate")
                    .font(.headline)
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(version)")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
        } .padding()
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    SettingsTabView()
}
