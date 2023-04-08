//
//  ServingRunList.swift
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

import Compactor
import Tabler

import TrackerLib
import TrackerUI

import DcaltLib
import DcaltUI

// display ZServingRuns for a given ZDayRun from the specified store (main or archive).
struct ServingRunList<Header: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    typealias Sort = TablerSort<ZServingRun>
    typealias Context = TablerContext<ZServingRun>
    typealias ProjectedValue = ObservedObject<ZServingRun>.Wrapper

    // MARK: - Parameters

    private let zDayRun: ZDayRun
    private var tableHeader: () -> Header

    init(zDayRun: ZDayRun,
         inStore: NSPersistentStore,
         tableHeader: @escaping () -> Header = { EmptyView() })
    {
        self.zDayRun = zDayRun
        self.tableHeader = tableHeader

        let predicate = ZServingRun.getPredicate(zDayRun: zDayRun, userRemoved: false)
        let sortDescriptors = ZServingRun.byConsumedTime(ascending: true)
        let request = makeRequest(ZServingRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: inStore)

        _servingRuns = FetchRequest<ZServingRun>(fetchRequest: request)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ServingRunList.self))

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        // EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    @FetchRequest private var servingRuns: FetchedResults<ZServingRun>

    private var listConfig: TablerListConfig<ZServingRun> {
        TablerListConfig<ZServingRun>(
            onDelete: userRemoveAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 120), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 80), spacing: columnSpacing, alignment: .trailing),
    ] }

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   footer: footer,
                   row: listRow,
                   rowBackground: rowBackground,
                   results: servingRuns)
            .listStyle(.plain)
//            .navigationTitle(navigationTitle)
    }

    @ViewBuilder
    private func header(ctx _: Binding<Context>) -> some View {
        tableHeader()
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Time")
                .padding(columnPadding)
            Text("Name")
                .padding(columnPadding)
            Text("Calories")
        }
    }

    @ViewBuilder
    private func listRow(element: ZServingRun) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text(element.displayConsumedTime)
                .padding(columnPadding)
            Text(element.zServing?.name ?? "")
                .padding(columnPadding)
            calorieText(element.calories)
        }
    }

    @ViewBuilder
    private func footer(ctx _: Binding<Context>) -> some View {
        HStack {
            GroupBox {
                Text("\(totalCalories) cal")
                    .font(.largeTitle)
                    .lineLimit(1)
            } label: {
                Text("Total")
                    .foregroundStyle(.tint)
                    .padding(.bottom, 3)
            }
        }
    }

    private func rowBackground(_: ZServingRun) -> some View {
        EntityBackground(servingColorDarkBg)
    }

    private func calorieText(_ calories: Int16) -> some View {
        Text("\(calories) cal")
    }

    // MARK: - Properties

    private var totalCalories: Int16 {
        servingRuns.reduce(0) { $0 + $1.calories }
    }

    // MARK: - Actions

    // NOTE: 'removes' matching records, where present, from both mainStore and archiveStore.
    private func userRemoveAction(at offsets: IndexSet) {
        do {
            for index in offsets {
                let zServingRun = servingRuns[index]

                guard let servingArchiveID = zServingRun.zServing?.servingArchiveID,
                      let consumedDay = zServingRun.zDayRun?.consumedDay,
                      let consumedTime = zServingRun.consumedTime
                else { continue }

                try ZServingRun.userRemove(viewContext, servingArchiveID: servingArchiveID, consumedDay: consumedDay, consumedTime: consumedTime)
            }

            // re-total the calories in both stores (may no longer be present in main)
            if let consumedDay = zDayRun.consumedDay {
                if let mainStore = manager.getMainStore(viewContext) {
                    refreshTotalCalories(consumedDay: consumedDay, inStore: mainStore)
                }
                if let archiveStore = manager.getArchiveStore(viewContext) {
                    refreshTotalCalories(consumedDay: consumedDay, inStore: archiveStore)
                }
            }

            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    // Re-total the calories for the ZDayRun record, if present in specified store.
    private func refreshTotalCalories(consumedDay: String, inStore: NSPersistentStore) {
        logger.debug("\(#function):")

        // will need to update in both mainStore and archiveStore
        guard let zdr = try? ZDayRun.get(viewContext, consumedDay: consumedDay, inStore: inStore)
        else {
            logger.notice("\(#function): Unable to find ZDayRun record to re-total its calories.")
            return
        }

        let calories = zdr.refreshCalorieSum()

        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }

        let targetCalories: Int16 = (try? AppSetting.getOrCreate(viewContext).targetCalories) ?? defaultTargetCalories

        refreshWidget(targetCalories: targetCalories, currentCalories: calories, reload: true)
    }
}

struct ServingRunList_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let archiveStore = manager.getArchiveStore(ctx)!

        let consumedDay1 = "2023-02-01"
        let consumedTime1 = "16:05"

        let category1ArchiveID = UUID()
        let category2ArchiveID = UUID()
        let serving1ArchiveID = UUID()
        let serving2ArchiveID = UUID()

        let zc1 = ZCategory.create(ctx, categoryArchiveID: category1ArchiveID, categoryName: "Fruit", toStore: archiveStore)
        let zc2 = ZCategory.create(ctx, categoryArchiveID: category2ArchiveID, categoryName: "Meat", toStore: archiveStore)
        let zs1 = ZServing.create(ctx, zCategory: zc1, servingArchiveID: serving1ArchiveID, servingName: "Banana", toStore: archiveStore)
        let zs2 = ZServing.create(ctx, zCategory: zc2, servingArchiveID: serving2ArchiveID, servingName: "Steak", toStore: archiveStore)
        let zdr = ZDayRun.create(ctx, consumedDay: consumedDay1, calories: 2433, toStore: archiveStore)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs1, consumedTime: consumedTime1, calories: 120, toStore: archiveStore)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs2, consumedTime: consumedTime1, calories: 450, toStore: archiveStore)
        try? ctx.save()

        return NavigationStack {
            ServingRunList(zDayRun: zdr, inStore: archiveStore) {
                Text("Table Header")
            }
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
        }
    }
}
