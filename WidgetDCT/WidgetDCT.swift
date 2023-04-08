//
//  WidgetDCT.swift
//  WidgetDCT
//
//  Created by Reed Esau on 4/8/23.
//

import WidgetKit
import SwiftUI
import Intents

import DcaltUI
import DcaltLib

struct WidgetDCT: Widget {
    let kind: String = "WidgetDCT"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
        //IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Calories")
        .description("Show progress towards your daily goal.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct WidgetDCT_Previews: PreviewProvider {
    static var previews: some View {
//        WidgetView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
        let entry = WidgetEntry(targetCalories: 2000, currentCalories: 500)
        return WidgetView(entry: entry)
            .accentColor(.blue)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
