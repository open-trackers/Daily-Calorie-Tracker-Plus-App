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

let mainNavDataCategoryKey = "main-category-nav"
let mainNavDataTodayKey = "main-today-nav"
let mainNavDataSettingsKey = "main-settings-nav"

struct ContentView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ContentView.self))

    @SceneStorage(tabbedViewSelectedTabKey) private var selectedTab = PortraitTab.categories.rawValue

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let isPad = horizontalSizeClass == .regular && verticalSizeClass == .regular
            VStack {
                if isPad, isLandscape {
                    // enough vertical to show number pad, etc.
                    MainLandscape()
                } else {
                    MainPortrait()
                }
            }
        }
        .task(priority: .utility, taskAction)
        .onContinueUserActivity(logCategoryActivityType) {
            selectedTab = PortraitTab.categories.rawValue
            handleLogCategoryUA(viewContext, $0)
        }
        .onContinueUserActivity(logServingActivityType) {
            selectedTab = PortraitTab.categories.rawValue
            handleLogServingUA(viewContext, $0)
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
