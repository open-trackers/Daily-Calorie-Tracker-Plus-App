//
//  MainPortrait.swift
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

enum PortraitTab: String {
    case categories
    case today
    case settings
}

let tabbedViewSelectedTabKey = "main-tab-str"

struct MainPortrait: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    @SceneStorage(tabbedViewSelectedTabKey) private var selectedTab = PortraitTab.categories.rawValue

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
                          stackIdentifier: PortraitTab.categories.rawValue,
                          destination: destination)
            {
                CategoryList()
            }
            .tabItem {
                Label("Categories", systemImage: "carrot")
            }
            .tag(PortraitTab.categories.rawValue)

            DcaltNavStack(navData: $todayNavData,
                          stackIdentifier: PortraitTab.today.rawValue,
                          destination: destination)
            {
                PlusTodayDayRun(withSettings: false)
            }
            .tabItem {
                Label("Today", systemImage: "fossil.shell")
            }
            .tag(PortraitTab.today.rawValue)

            DcaltNavStack(navData: $settingsNavData,
                          stackIdentifier: PortraitTab.settings.rawValue,
                          destination: destination)
            {
                PhoneSettingsForm()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(PortraitTab.settings.rawValue)
        }
    }

    private func destination(router: DcaltRouter, route: DcaltRoute) -> some View {
        Destination(route: route)
            .environmentObject(router)
            .environment(\.managedObjectContext, viewContext)
    }
}

struct MainPortrait_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext

        _ = MCategory.create(ctx, name: "Entrees", userOrder: 0)
        _ = MCategory.create(ctx, name: "Snacks", userOrder: 1)

        try? ctx.save()
        return MainPortrait()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
