//
//  MainLandscape.swift
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

struct MainLandscape: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    @SceneStorage(mainNavDataCategoryKey) private var categoryNavData: Data?
    @SceneStorage(mainNavDataTodayKey) private var todayNavData: Data?

    var body: some View {
        HStack {
            DcaltNavStack(navData: $categoryNavData,
                          stackIdentifier: "Categories",
                          destination: destination)
            {
                CategoryList()
            }

            DcaltNavStack(navData: $todayNavData,
                          stackIdentifier: "Today",
                          destination: destination)
            {
                TodayDayRun(withSettings: true)
            }
        }
    }

    private func destination(router: DcaltRouter, route: DcaltRoute) -> some View {
        Destination(route: route)
            .environmentObject(router)
            .environment(\.managedObjectContext, viewContext)
    }
}

struct MainLandscape_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext

        _ = MCategory.create(ctx, name: "Entrees", userOrder: 0)
        _ = MCategory.create(ctx, name: "Snacks", userOrder: 1)

        try? ctx.save()
        return MainLandscape()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
