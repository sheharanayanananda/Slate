//
//  SettingsView.swift
//  Slate
//
//  Created by Antigravity on 2026-06-14.
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Properties
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var viewModel: SettingsViewModel
    var onDismiss: (() -> Void)? = nil

    @State private var showKey: Bool = false

    // MARK: - UI Code
    var body: some View {
        List {
            // Ollama API Key Row
            Section { 
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white : Color.black)
                        )
                    
                    if showKey {
                        TextField("Ollama API Key", text: $viewModel.apiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("Ollama API Key", text: $viewModel.apiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    Button(action: { showKey.toggle() }) {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                if viewModel.validationStatus != .empty {
                    HStack(spacing: 8) {
                        if viewModel.validationStatus == .checking {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: viewModel.validationStatus.iconName)
                                .foregroundColor(viewModel.validationStatus.color)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        Text(viewModel.validationStatus.message)
                            .font(.subheadline)
                            .foregroundColor(viewModel.validationStatus.color)
                    }
                }
            }
            
            // How to obtain API Key
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1. Create or sign in to your account at ollama.com")
                    Text("2. Navigate to your Account Settings to generate a key")
                    Text("3. Copy and paste your key into the field above")
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
                
                Link(destination: URL(string: "https://ollama.com")!) {
                    HStack {
                        Text("Get Ollama API Key")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Future settings sections/rows can be placed right here natively
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismissView()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
        .onDisappear {
            viewModel.savePendingChanges()
        }
        .onChange(of: viewModel.apiKey) {
            viewModel.handleApiKeyChange()
        }
    }
}

// MARK: - Main Functions
extension SettingsView {
    private func dismissView() {
        HapticManager.trigger(.light)
        
        viewModel.savePendingChanges()
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}

// MARK: - Previews
#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
}
