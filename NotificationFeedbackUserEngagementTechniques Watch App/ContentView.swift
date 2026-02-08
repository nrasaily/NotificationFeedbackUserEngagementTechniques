//
//  ContentView.swift
//  NotificationFeedbackUserEngagementTechniques Watch App
//
//  Created by Nar Rasaily on 2/8/26.
//

import SwiftUI

/// Main content view with tab navigation
struct ContentView: View {
    @StateObject private var manager = ActivityCoachManager()
    
    var body: some View {
        TabView {
            // Dashboard
            CoachDashboardView(manager: manager)
                .tag(0)
            
            // Settings
            SettingsView(manager: manager)
                .tag(1)
        }
        .tabViewStyle(.verticalPage)
        .task {
            await manager.requestPermissions()
        }
        .onDisappear {
            manager.stopMonitoring()
        }
    }
}

#Preview {
    ContentView()
}
