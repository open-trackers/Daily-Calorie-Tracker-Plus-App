//
//  DayRunList.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import StoreKit
import SwiftUI

import Tabler

import DcaltLib
import DcaltUI

import TrackerLib
import TrackerUI

struct DayRunList: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    typealias Sort = TablerSort<ZDayRun>
    typealias Context = TablerContext<ZDayRun>
    typealias ProjectedValue = ObservedObject<ZDayRun>.Wrapper

    // MARK: - Parameters

    internal init(archiveStore: NSPersistentStore) {
        let predicate = ZDayRun.getPredicate(userRemoved: false)
        let sortDescriptors = ZDayRun.byConsumedDay(ascending: false)
        let request = makeRequest(ZDayRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: archiveStore)
        _dayRuns = FetchRequest<ZDayRun>(fetchRequest: request)
    }

    // MARK: - Locals

    @FetchRequest private var dayRuns: FetchedResults<ZDayRun>

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: DayRunList.self))

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        // EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    private static let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()

    private var listConfig: TablerListConfig<ZDayRun> {
        TablerListConfig<ZDayRun>(
            onDelete: userRemoveAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 180), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
    ] }

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   rowBackground: rowBackground,
                   results: dayRuns)
            .listStyle(.plain)
    }

    private func header(ctx _: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Date")
                .padding(columnPadding)
            Text("Calories")
        }
    }

    @ViewBuilder
    private func listRow(element: ZDayRun) -> some View {
        Button(action: { detailAction(element) }) {
            LazyVGrid(columns: gridItems, alignment: .leading) {
                Text(formattedConsumedDate(element))
                    .lineLimit(1)
                    .padding(columnPadding)
                Text("\(element.calories) cal")
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func rowBackground(_: ZDayRun) -> some View {
        EntityBackground(categoryColor)
    }

    private func formattedConsumedDate(_ zDayRun: ZDayRun) -> String {
        guard let startOfDay = try? AppSetting.getOrCreate(viewContext).startOfDayEnum,
              let dateVal = zDayRun.consumedDate(consumedTime: startOfDay.HH_mm_ss)
        else { return "unknown" }
        return Self.df.string(from: dateVal)
    }

    // MARK: - Properties

    // MARK: - Actions

    private func detailAction(_ zDayRun: ZDayRun) {
        router.path.append(DcaltRoute.dayRunArchive(zDayRun.uriRepresentation))
    }

    // NOTE: 'removes' matching records, where present, from both mainStore and archiveStore.
    private func userRemoveAction(at offsets: IndexSet) {
        do {
            for index in offsets {
                let zDayRun = dayRuns[index]
                guard let consumedDay = zDayRun.consumedDay
                else { continue }

                try ZDayRun.userRemove(viewContext, consumedDay: consumedDay)
            }

            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct ConsumedList_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let archiveStore = manager.getArchiveStore(ctx)!

        let consumedDay1 = "2023-02-02"
        let consumedTime1 = "03:05"

        let categoryArchiveID = UUID()
        let serving1ArchiveID = UUID()

        let zc = ZCategory.create(ctx, categoryArchiveID: categoryArchiveID, categoryName: "Fruit", toStore: archiveStore)
        let zs = ZServing.create(ctx, zCategory: zc, servingArchiveID: serving1ArchiveID, servingName: "Banana", toStore: archiveStore)
        let zdr = ZDayRun.create(ctx, consumedDay: consumedDay1, calories: 2433, toStore: archiveStore)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs, consumedTime: consumedTime1, calories: 120, toStore: archiveStore)
        try? ctx.save()

        return NavigationStack {
            DayRunList(archiveStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
        }
    }
}
