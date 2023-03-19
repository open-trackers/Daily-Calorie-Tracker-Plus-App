//
//  PlusSettingsForm.swift
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

struct PlusSettingsForm: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Params

    // MARK: - Views

    var body: some View {
        if let appSetting = try? AppSetting.getOrCreate(viewContext),
           let mainStore = manager.getMainStore(viewContext),
           let archiveStore = manager.getArchiveStore(viewContext)
        {
            DcaltSettings(appSetting: appSetting, onRestoreToDefaults: {}) {
                ExportSettings(mainStore: mainStore,
                               archiveStore: archiveStore,
                               filePrefix: "sct-",
                               createZipArchive: dcaltCreateZipArchive)

                Button(action: {
                    router.path.append(DcaltRoute.about)
                }) {
                    Text("About \(appName)")
                }
            }
        } else {
            Text("Settings not available.")
        }
    }

    // MARK: - Properties

    private var appName: String {
        Bundle.main.appName ?? "unknown"
    }

    // MARK: - Actions
}

struct PlusSettingsForm_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let context = manager.container.viewContext
        let appSet = AppSetting(context: context)
        appSet.startOfDayEnum = StartOfDay.defaultValue
        try? context.save()
        return NavigationStack { PlusSettingsForm()
            .environment(\.managedObjectContext, manager.container.viewContext)
            .environmentObject(manager)
        }
    }
}
