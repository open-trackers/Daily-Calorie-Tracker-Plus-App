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
    }

    @SceneStorage("main-tab") private var selectedTab = 0
    @SceneStorage("main-category-nav") private var categoryNavData: Data?
    @SceneStorage("main-history-nav") private var historyNavData: Data?
    @SceneStorage("main-settings-nav") private var settingsNavData: Data?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ContentView.self))

    var body: some View {
        TabView(selection: $selectedTab) {
            NavStack(navData: $categoryNavData, destination: destination) {
                CategoryList()
            }
            .tabItem {
                Label("Categories", systemImage: "carrot")
            }
            .tag(Tabs.categories.rawValue)

            NavStack(navData: $historyNavData,
                     destination: destination) {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "fossil.shell")
            }
            .tag(Tabs.history.rawValue)

            NavStack(navData: $settingsNavData, destination: destination) {
                PhoneSettingsForm()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tabs.settings.rawValue)
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
        if let zDayRun = ZDayRun.get(viewContext, forURIRepresentation: dayRunUri),
           let archiveStore = manager.getArchiveStore(viewContext)
        {
            ServingRunList(zDayRun: zDayRun, archiveStore: archiveStore)
        } else {
            Text("Serving Run not available.")
        }
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
