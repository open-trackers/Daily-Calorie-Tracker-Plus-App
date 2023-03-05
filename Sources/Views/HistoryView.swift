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
                .confirmationDialog("",
                                    isPresented: $showClearDialog,
                                    actions: {
                                        Button("Clear", role: .destructive, action: clearHistoryAction)
                                    },
                                    message: {
                                        Text("This will remove all historical data, including today.")
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
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let archiveStore = manager.getArchiveStore(ctx)!

        let category1ArchiveID = UUID()
        let category2ArchiveID = UUID()
        let category3ArchiveID = UUID()

        _ = ZCategory.create(ctx, categoryArchiveID: category1ArchiveID, categoryName: "blah", toStore: archiveStore)
        _ = ZCategory.create(ctx, categoryArchiveID: category2ArchiveID, categoryName: "bleh", toStore: archiveStore)
        _ = ZCategory.create(ctx, categoryArchiveID: category3ArchiveID, categoryName: "bloop", toStore: archiveStore)
        // try! ctx.save()

        return NavigationStack { HistoryView()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
        }
    }
}
