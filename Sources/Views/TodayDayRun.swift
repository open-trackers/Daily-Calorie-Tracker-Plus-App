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

    // MARK: - Parameters

    private let withSettings: Bool
    private let mainStore: NSPersistentStore

    internal init(withSettings: Bool,
                  mainStore: NSPersistentStore)
    {
        self.withSettings = withSettings
        self.mainStore = mainStore

        let predicate = ZDayRun.getPredicate(userRemoved: false)
        let sortDescriptors = ZDayRun.byConsumedDay(ascending: false)
        let request = makeRequest(ZDayRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: mainStore)
        request.fetchLimit = 1
        _dayRuns = FetchRequest<ZDayRun>(fetchRequest: request)
    }

    // MARK: - Locals

    @FetchRequest private var dayRuns: FetchedResults<ZDayRun>

    private static let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    // MARK: - Views

    var body: some View {
        VStack {
            if let dayRun,
               let startOfDay = try? AppSetting.getOrCreate(viewContext).startOfDayEnum,
               let dateVal = dayRun.consumedDate(consumedTime: startOfDay.HH_mm_ss)
            {
                ServingRunList(zDayRun: dayRun, inStore: mainStore) {
                    Text(Self.df.string(from: dateVal))
                        .font(.largeTitle)
                }
            } else {
                Text("No activity for today. See ‘Full History’.") // shouldn't appear; included here defensively
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
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Properties

    private var dayRun: ZDayRun? {
        dayRuns.first
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
            TodayDayRun(withSettings: false, mainStore: mainStore)
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
        }
    }
}
