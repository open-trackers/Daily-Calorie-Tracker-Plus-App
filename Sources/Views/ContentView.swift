//
//  ContentView.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import DcaltLib
import DcaltUI
import TrackerUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    enum Tabs: String {
        case categories
        case history
        case settings
    }

    @SceneStorage("main-tab-str") private var selectedTab = Tabs.categories.rawValue
    @SceneStorage("main-category-nav") private var categoryNavData: Data?
    @SceneStorage("main-history-nav") private var historyNavData: Data?
    @SceneStorage("main-settings-nav") private var settingsNavData: Data?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ContentView.self))

    // NOTE: this proxy is duplicated in Gym Routine Tracker Plus's ContentView.
    // QUESTION: can this be moved to TrackerUI somehow?
    private var selectedProxy: Binding<String> {
        Binding(get: { selectedTab },
                set: { nuTab in
                    if nuTab != selectedTab {
                        selectedTab = nuTab
                    } else {
                        NotificationCenter.default.post(name: .trackerPopNavStack,
                                                        object: nuTab)
                    }
                })
    }

    var body: some View {
        TabView(selection: selectedProxy) {
            DcaltNavStack(navData: $categoryNavData,
                          stackIdentifier: Tabs.categories.rawValue,
                          destination: destination)
            {
                CategoryList()
            }
            .tabItem {
                Label("Categories", systemImage: "carrot")
            }
            .tag(Tabs.categories.rawValue)

            DcaltNavStack(navData: $historyNavData,
                          stackIdentifier: Tabs.history.rawValue,
                          destination: destination)
            {
                TodayDayRun()
            }
            .tabItem {
                Label("Today", systemImage: "fossil.shell")
            }
            .tag(Tabs.history.rawValue)

            DcaltNavStack(navData: $settingsNavData,
                          stackIdentifier: Tabs.settings.rawValue,
                          destination: destination)
            {
                PhoneSettingsForm()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tabs.settings.rawValue)
        }
        .task(priority: .utility, taskAction)
        .onContinueUserActivity(logCategoryActivityType) {
            selectedTab = Tabs.categories.rawValue
            handleLogCategoryUA(viewContext, $0)
        }
        .onContinueUserActivity(logServingActivityType) {
            selectedTab = Tabs.categories.rawValue
            handleLogServingUA(viewContext, $0)
        }
    }

    // handle routes for iOS-specific views here
    @ViewBuilder
    private func destination(_ router: DcaltRouter, _ route: DcaltRoute) -> some View {
        switch route {
        case .dayRunList:
            HistoryView()
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        case .dayRunToday:
            TodayDayRun()
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        case let .dayRunArchive(dayRunURI):
            pastDayRun(dayRunURI)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        default:
            DcaltDestination(route)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    @ViewBuilder
    private func pastDayRun(_ dayRunUri: URL) -> some View {
        if let zDayRun: ZDayRun = ZDayRun.get(viewContext, forURIRepresentation: dayRunUri),
           let archiveStore = manager.getArchiveStore(viewContext)
        {
            ArchivalDayRun(zDayRun: zDayRun, archiveStore: archiveStore)
        } else {
            Text("Past Day Run not available.")
        }
    }

    @Sendable
    private func taskAction() async {
        await handleTaskAction(manager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext

        _ = MCategory.create(ctx, name: "Entrees", userOrder: 0)
        _ = MCategory.create(ctx, name: "Snacks", userOrder: 1)

        try? ctx.save()
        return ContentView()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
