//
//  Destination.swift
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

// handle routes for iOS-specific views here
struct Destination: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter
    @EnvironmentObject private var manager: CoreDataStack

    var route: DcaltRoute

    var body: some View {
        switch route {
        case .dayRunList:
            HistoryView()
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        case .dayRunToday:
            PlusTodayDayRun(withSettings: false)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        case let .dayRunArchive(dayRunURI):
            pastDayRun(dayRunURI)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        default:
            DcaltDestination(route)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    @ViewBuilder
    private func pastDayRun(_ dayRunUri: URL) -> some View {
        if let zDayRun: ZDayRun = ZDayRun.get(viewContext, forURIRepresentation: dayRunUri),
           let archiveStore = manager.getArchiveStore(viewContext)
        {
            ArchivalDayRun(zDayRun: zDayRun, archiveStore: archiveStore)
        } else {
            Text("Past Day Run not available.")
        }
    }
}

struct Destination_Previews: PreviewProvider {
    static var previews: some View {
        Destination(route: .about)
    }
}
