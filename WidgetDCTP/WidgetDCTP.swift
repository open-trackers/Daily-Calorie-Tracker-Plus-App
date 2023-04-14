//
//  WidgetDCTP.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI
import WidgetKit

import DcaltLib
import DcaltUI

struct WidgetDCTP: Widget {
    let kind: String = "WidgetDCTP"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Calories")
        .description("Show progress towards your daily goal.")
        .supportedFamilies([.systemSmall])
    }
}

struct WidgetDCTP_Previews: PreviewProvider {
    static var previews: some View {
        let entry = WidgetEntry(targetCalories: 2000, currentCalories: 500)
        return WidgetView(entry: entry)
            .accentColor(.blue)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
