//
//  TabbedView.swift
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

enum TabbedTabs: String {
    case categories
    case today
    case settings
}

let tabbedViewSelectedTabKey = "main-tab-str"

struct TabbedView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    //@EnvironmentObject private var router: DcaltRouter

    @SceneStorage(tabbedViewSelectedTabKey) private var selectedTab = TabbedTabs.categories.rawValue

    @SceneStorage(mainNavDataCategoryKey) private var categoryNavData: Data?
    @SceneStorage(mainNavDataTodayKey) private var todayNavData: Data?
    @SceneStorage(mainNavDataSettingsKey) private var settingsNavData: Data?

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
                          stackIdentifier: TabbedTabs.categories.rawValue,
                          destination: destination)
            {
                CategoryList()
            }
            .tabItem {
                Label("Categories", systemImage: "carrot")
            }
            .tag(TabbedTabs.categories.rawValue)

            DcaltNavStack(navData: $todayNavData,
                          stackIdentifier: TabbedTabs.today.rawValue,
                          destination: destination)
            {
                TodayDayRun()
            }
            .tabItem {
                Label("Today", systemImage: "fossil.shell")
            }
            .tag(TabbedTabs.today.rawValue)

            DcaltNavStack(navData: $settingsNavData,
                          stackIdentifier: TabbedTabs.settings.rawValue,
                          destination: destination)
            {
                PhoneSettingsForm()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(TabbedTabs.settings.rawValue)
        }
    }

    private func destination(router: DcaltRouter, route: DcaltRoute) -> some View {
        Destination(route: route)
            .environmentObject(router)
            .environment(\.managedObjectContext, viewContext)
    }
}

struct TabbedView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext

        _ = MCategory.create(ctx, name: "Entrees", userOrder: 0)
        _ = MCategory.create(ctx, name: "Snacks", userOrder: 1)

        try? ctx.save()
        return TabbedView()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
