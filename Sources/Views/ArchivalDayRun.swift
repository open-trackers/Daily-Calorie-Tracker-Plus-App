//
//  ArchivalDayRun.swift
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

struct ArchivalDayRun: View {
    var zDayRun: ZDayRun
    var archiveStore: NSPersistentStore

    var body: some View {
        ServingRunList(zDayRun: zDayRun, inStore: archiveStore)
            .navigationTitle(zDayRun.wrappedConsumedDay)
    }
}
