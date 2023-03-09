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

    enum Tabs: Int {
        case categories = 0
        case history = 1
        case settings = 2

        static let categoriesNavUUID = UUID()
        static let historyNavUUID = UUID()
        static let settingsNavUUID = UUID()

        var uuid: UUID {
            switch self {
            case .categories:
                return Self.categoriesNavUUID
            case .history:
                return Self.historyNavUUID
            case .settings:
                return Self.settingsNavUUID
            }
        }
    }

    @SceneStorage("main-tab") private var selectedTab = 0
    @SceneStorage("main-category-nav") private var categoryNavData: Data?
    @SceneStorage("main-history-nav") private var historyNavData: Data?
    @SceneStorage("main-settings-nav") private var settingsNavData: Data?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ContentView.self))

    // NOTE: this proxy is duplicated in Gym Routine Tracker Plus's ContentView.
    private var selectedProxy: Binding<Int> {
        Binding(get: { selectedTab },
                set: { nuTab in
                    if nuTab != selectedTab {
                        selectedTab = nuTab
                    } else {
                        guard let _nuTab = Tabs(rawValue: nuTab) else { return }
                        logger.debug("ContentView: detected tap on already-selected tab")
                        NotificationCenter.default.post(name: .trackerPopNavStack,
                                                        object: _nuTab.uuid)
                    }
                })
    }

    var body: some View {
        TabView(selection: selectedProxy) {
            DcaltNavStack(navData: $categoryNavData,
                          stackIdentifier: Tabs.categoriesNavUUID,
                          destination: destination)
            {
                CategoryList()
            }
            .tabItem {
                Label("Categories", systemImage: "carrot")
            }
            .tag(Tabs.categories.rawValue)

            DcaltNavStack(navData: $historyNavData,
                          stackIdentifier: Tabs.historyNavUUID,
                          destination: destination)
            {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "fossil.shell")
            }
            .tag(Tabs.history.rawValue)

            DcaltNavStack(navData: $settingsNavData,
                          stackIdentifier: Tabs.settingsNavUUID,
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
        case let .dayRunDetail(dayRunURI):
            servingRunList(dayRunURI)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        default:
            DcaltDestination(route)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // NOTE that this is to access servingRun in Archive Store (not Main Store!)
    @ViewBuilder
    private func servingRunList(_ dayRunUri: URL) -> some View {
        if let zDayRun: ZDayRun = ZDayRun.get(viewContext, forURIRepresentation: dayRunUri),
           let archiveStore = manager.getArchiveStore(viewContext)
        {
            ServingRunList(zDayRun: zDayRun, archiveStore: archiveStore)
        } else {
            Text("Serving Run not available.")
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
