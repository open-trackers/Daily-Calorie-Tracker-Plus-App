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

    private static let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    var body: some View {
        if let mainStore = manager.getMainStore(viewContext),
           let appSetting = try? AppSetting.getOrCreate(viewContext),
           case let startOfDay = appSetting.startOfDayEnum,
           let (consumedDay, _) = getSubjectiveDate(dayStartHour: startOfDay.hour,
                                                    dayStartMinute: startOfDay.minute),
           let zDayRun = try? ZDayRun.get(viewContext, consumedDay: consumedDay, inStore: mainStore)
        {
            ServingRunList(zDayRun: zDayRun, inStore: mainStore)
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            Haptics.play()
                            router.path.append(DcaltRoute.dayRunList)
                        }) {
                            Text("History")
                        }
                    }
                }
                .navigationTitle("Today, \(formattedConsumedDate(zDayRun))")
        }
    }

    private func formattedConsumedDate(_ zDayRun: ZDayRun) -> String {
        guard let dateVal = zDayRun.consumedDate()
        else { return "unknown" }
        return Self.df.string(from: dateVal)
    }
}
