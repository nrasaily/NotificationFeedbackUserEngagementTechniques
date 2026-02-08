//
//  SettingsView.swift
//  NotificationFeedbackUserEngagementTechniques
//
//  Created by Nar Rasaily on 2/8/26.
//

import SwiftUI

/// Settings view for goals and notifications
struct SettingsView: View {
    @ObservedObject var manager: ActivityCoachManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Step Goal
                GoalSettingCard(
                    title: "Daily Step Goal",
                    value: $manager.stepGoal,
                    range: 1000...20000,
                    step: 1000,
                    icon: "figure.walk",
                    color: .green
                )
                
                // Inactivity Alert
                InactivitySettingCard(
                    minutes: $manager.inactivityAlertMinutes
                )
                
                // Notification Status
                NotificationStatusCard(enabled: manager.notificationsEnabled)
                
                // Reset Button
                Button(action: { manager.resetDaily() }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Today")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Settings")
    }
}

/// Step goal setting card
struct GoalSettingCard: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Button(action: {
                    if value > range.lowerBound {
                        value -= step
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
                
                Spacer()
                
                Button(action: {
                    if value < range.upperBound {
                        value += step
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Inactivity alert setting
struct InactivitySettingCard: View {
    @Binding var minutes: Int
    
    let options = [15, 30, 45, 60]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.orange)
                Text("Inactivity Alert")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button(action: { minutes = option }) {
                        Text("\(option)m")
                            .font(.caption2)
                            .fontWeight(minutes == option ? .bold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(minutes == option ? Color.orange : Color.gray.opacity(0.2))
                            .foregroundStyle(minutes == option ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Notification status indicator
struct NotificationStatusCard: View {
    let enabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: enabled ? "bell.fill" : "bell.slash.fill")
                .foregroundStyle(enabled ? .green : .red)
            
            Text("Notifications")
                .font(.caption)
            
            Spacer()
            
            Text(enabled ? "Enabled" : "Disabled")
                .font(.caption)
                .foregroundStyle(enabled ? .green : .red)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SettingsView(manager: ActivityCoachManager())
}
