//
//  TodayDayRun.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

import DcaltLib
import DcaltUI
import TrackerLib
import TrackerUI

struct TodayDayRun: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: DcaltRouter

    var withSettings = false

    private static let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    var body: some View {
        VStack {
            if let mainStore = manager.getMainStore(viewContext),
               let appSetting = try? AppSetting.getOrCreate(viewContext),
               case let startOfDay = appSetting.startOfDayEnum,
               let (consumedDay, _) = Date.now.getSubjectiveDate(dayStartHour: startOfDay.hour,
                                                                 dayStartMinute: startOfDay.minute),
               let zDayRun = try? ZDayRun.get(viewContext, consumedDay: consumedDay, inStore: mainStore)
            {
                ServingRunList(zDayRun: zDayRun, inStore: mainStore)
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    Haptics.play()
                    router.path.append(DcaltRoute.dayRunList)
                }) {
                    Text("Full History")
                }
            }
            if withSettings {
                ToolbarItem {
                    Button(action: {
                        router.path.append(DcaltRoute.settings)
                    }) {
                        Text("Settings")
                    }
                }
            }
        }
        .navigationTitle("Today") // , \(formattedConsumedDate(zDayRun))
    }

    private func formattedConsumedDate(_ zDayRun: ZDayRun) -> String {
        guard let startOfDay = try? AppSetting.getOrCreate(viewContext).startOfDayEnum,
              let dateVal = zDayRun.consumedDate(consumedTime: startOfDay.HH_mm_ss)
        else { return "unknown" }
        return Self.df.string(from: dateVal)
    }
}

struct TodayDayRun_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let mainStore = manager.getMainStore(ctx)!

        let consumedToday = Date.now

        let (consumedDay1, consumedTime1) = consumedToday.splitToLocal()!

        let category1ArchiveID = UUID()
        let category2ArchiveID = UUID()
        let serving1ArchiveID = UUID()
        let serving2ArchiveID = UUID()

        let zc1 = ZCategory.create(ctx, categoryArchiveID: category1ArchiveID, categoryName: "Fruit", toStore: mainStore)
        let zc2 = ZCategory.create(ctx, categoryArchiveID: category2ArchiveID, categoryName: "Meat", toStore: mainStore)
        let zs1 = ZServing.create(ctx, zCategory: zc1, servingArchiveID: serving1ArchiveID, servingName: "Banana", toStore: mainStore)
        let zs2 = ZServing.create(ctx, zCategory: zc2, servingArchiveID: serving2ArchiveID, servingName: "Steak", toStore: mainStore)
        let zdr = ZDayRun.create(ctx, consumedDay: consumedDay1, calories: 2433, toStore: mainStore)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs1, consumedTime: consumedTime1, calories: 120, toStore: mainStore)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs2, consumedTime: consumedTime1, calories: 450, toStore: mainStore)
        try? ctx.save()

        return NavigationStack {
            TodayDayRun()
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
        }
    }
}
