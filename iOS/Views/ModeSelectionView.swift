//
//  ModeSelectionView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI

/// View for selecting the iPad operation mode (Solo or Paired)
struct ModeSelectionView: View {
    /// The mode manager
    @ObservedObject var modeManager: ModeManager
    
    /// Whether to remember the mode selection
    @AppStorage("rememberLastMode") private var rememberLastMode = true
    
    /// Animation namespace for transitions
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding(.bottom)
                    
                    Text("LED Messenger")
                        .titleStyle()
                    
                    Text("Select Operation Mode")
                        .subheadingStyle()
                }
                .padding(.top, 40)
                
                // Mode options
                VStack(spacing: 20) {
                    // Solo mode card
                    ModeSelectionCard(
                        mode: .solo,
                        isSelected: modeManager.currentMode == .solo,
                        action: { modeManager.setMode(.solo) }
                    )
                    .matchedGeometryEffect(id: "soloMode", in: animation)
                    
                    // Paired mode card
                    ModeSelectionCard(
                        mode: .paired,
                        isSelected: modeManager.currentMode == .paired,
                        action: { modeManager.setMode(.paired) }
                    )
                    .matchedGeometryEffect(id: "pairedMode", in: animation)
                }
                .padding(.horizontal)
                
                // Remember mode toggle
                Toggle("Remember my selection", isOn: $rememberLastMode)
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.Colors.primary))
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .onChange(of: rememberLastMode) { newValue in
                        modeManager.setRememberLastMode(newValue)
                    }
                
                Spacer()
                
                // App info
                VStack(spacing: 4) {
                    Text("LED Messenger")
                        .font(.footnote)
                        .fontWeight(.medium)
                    
                    Text("Version \(AppConstants.App.fullVersion)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

/// Card view for each operation mode option
struct ModeSelectionCard: View {
    /// The operation mode this card represents
    let mode: OperationMode
    
    /// Whether this mode is currently selected
    let isSelected: Bool
    
    /// Action to perform when tapped
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Mode icon
                ZStack {
                    Circle()
                        .fill(mode.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: mode.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(mode.color)
                }
                
                // Mode details
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.surface)
                    .shadow(
                        color: isSelected ? mode.color.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? mode.color : Color.clear,
                        lineWidth: 3
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModeSelectionView(modeManager: ModeManager())
    }
}
