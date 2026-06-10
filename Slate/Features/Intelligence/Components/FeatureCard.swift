//
//  FeatureCard.swift
//  Slate
//

import SwiftUI

struct FeatureCard: View {
    var title: String
    var iconName: String
    var iconColor: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    // Minimalist icon with vibrant color
                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(iconColor)
                    
                    Spacer()
                    
                    // Sleek, clean action arrow
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Crisp title text
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color(red: 30/255, green: 30/255, blue: 30/255))
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PremiumCardButtonStyle())
    }
}

// Custom button style for tactile spring feedback
struct PremiumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
