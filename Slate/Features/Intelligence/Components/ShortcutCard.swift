//
//  ShortcutCard.swift
//  Slate
//

import SwiftUI

struct ShortcutCard: View {
    var title: String
    var iconName: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image(systemName: iconName)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(width: 220, height: 130)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ShortcutCard(
        title: "Start Pomodoro",
        iconName: "timer",
        color: Color(red: 247/255, green: 106/255, blue: 115/255),
        action: {}
    )
}
