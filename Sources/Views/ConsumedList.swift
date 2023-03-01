//
//  CategoryRunList.swift
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

struct ConsumedList: View {
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
        let sortDescriptors = [NSSortDescriptor(keyPath: \ZDayRun.consumedDay, ascending: false)]
        let request = makeRequest(ZDayRun.self,
                                  sortDescriptors: sortDescriptors,
                                  inStore: archiveStore)
        _days = FetchRequest<ZDayRun>(fetchRequest: request)
    }

    // MARK: - Locals

    @FetchRequest private var days: FetchedResults<ZDayRun>

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ConsumedList.self))

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        // EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    private let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()

    private var listConfig: TablerListConfig<ZDayRun> {
        TablerListConfig<ZDayRun>(
            onDelete: deleteAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 180), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
    ] }

    // private let tc = NumberCompactor(ifZero: "", roundSmallToWhole: false)

    // support for app review prompt
//    @SceneStorage("has-been-prompted-for-app-review") private var hasBeenPromptedForAppReview = false
//    private let minimumRunsForAppReviewAlert = 15

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   rowBackground: rowBackground,
                   results: days)
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
                Text(element.wrappedConsumedDay)
                    .lineLimit(1)
                    .padding(columnPadding)
                Text("\(element.calories) cals")
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func rowBackground(_: ZDayRun) -> some View {
        EntityBackground(categoryColor)
    }

    private func startedAtText(_ date: Date?) -> some View {
        guard let date else { return Text("") }
        return Text(df.string(from: date))
    }

    // MARK: - Properties

    // MARK: - Actions

    private func detailAction(_ zDayRun: ZDayRun) {
        router.path.append(DcaltRoute.dayRunDetail(zDayRun.uriRepresentation))
    }

    private func deleteAction(at offsets: IndexSet) {
        // NOTE: removing specified zDayRun records, where present, from both mainStore and archiveStore.

        do {
            for index in offsets {
                let element = days[index]

                guard let consumedDay = element.consumedDay
                else { continue }

                try ZDayRun.delete(viewContext, consumedDay: consumedDay, inStore: nil)
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

        let consumedDay1 = "2023-02-01"
        let consumedTime1 = "16:05"

        let categoryArchiveID = UUID()
        let serving1ArchiveID = UUID()

        let zc = ZCategory.create(ctx, categoryArchiveID: categoryArchiveID, categoryName: "Fruit", toStore: archiveStore)
        let zs = ZServing.create(ctx, zCategory: zc, servingArchiveID: serving1ArchiveID, servingName: "Banana", toStore: archiveStore)
        let zdr = ZDayRun.create(ctx, consumedDay: consumedDay1, calories: 2433, toStore: archiveStore)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs, consumedTime: consumedTime1, calories: 120, toStore: archiveStore)
        try? ctx.save()

        return NavigationStack {
            ConsumedList(archiveStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
        }
    }
}
