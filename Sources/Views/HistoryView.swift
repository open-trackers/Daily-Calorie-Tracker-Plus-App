//
//  HistoryView.swift
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
import TrackerLib
import TrackerUI

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    // MARK: - Locals

    @State private var showClearDialog = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: HistoryView.self))

    // MARK: - Views

    var body: some View {
        if let archiveStore = manager.getArchiveStore(viewContext) {
            DayRunList(archiveStore: archiveStore)
                .toolbar {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(action: {
                            Haptics.play(.warning)
                            showClearDialog = true
                        }) {
                            Text("Clear")
                        }
                    }
                }
                // NOTE: using an alert, as confirmationDialog may be clipped at top of view on iPad
                // .confirmationDialog(
                .alert("",
                       isPresented: $showClearDialog,
                       actions: {
                           Button("Clear", role: .destructive, action: clearHistoryAction)
                       },
                       message: {
                           Text("This will remove all historical data, including today’s.")
                       })
                .navigationTitle(navigationTitle)
                .task(priority: .userInitiated, taskAction)
        } else {
            Text("History not available.")
        }
    }

    // MARK: - Properties

    private var navigationTitle: String {
        "History"
    }

    // MARK: - Actions

    private func clearHistoryAction() {
        do {
            // clear all 'z' records from both mainStore and archiveStore
            try manager.clearZEntities(viewContext)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    @Sendable
    private func taskAction() async {
        logger.notice("\(#function) START")

        // transfer any 'Z' records from the 'Main' store to the 'Archive' store.

        await manager.container.performBackgroundTask { backgroundContext in
            guard let mainStore = manager.getMainStore(backgroundContext),
                  let archiveStore = manager.getArchiveStore(backgroundContext),
                  let startOfDay = try? AppSetting.getOrCreate(backgroundContext).startOfDayEnum
            else {
                logger.error("\(#function): unable to acquire configuration to transfer log records.")
                return
            }
            do {
                try transferToArchive(backgroundContext,
                                      mainStore: mainStore,
                                      archiveStore: archiveStore,
                                      startOfDay: startOfDay)
                try backgroundContext.save()
            } catch {
                logger.error("\(#function): TRANSFER \(error.localizedDescription)")
            }
        }
        logger.notice("\(#function) END")
    }
}

struct HistoryView_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var navData: Data?
        @State var isNew = false
        var body: some View {
            DcaltNavStack(navData: $navData) {
                HistoryView()
            }
        }
    }

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

        return
            TestHolder()
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
    }
}
