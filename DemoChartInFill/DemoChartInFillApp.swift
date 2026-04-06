//
//  DemoChartInFillApp.swift
//  DemoChartInFill
//
//  Created by on 4/2/26.
//

import SwiftUI

@main
struct DemoChartInFillApp: App {
    var body: some Scene {
        let model = DataModel()
        let grouping = SizeRegistryGrouping(
            measured: model.measured,
            threshold: model.threshold
        )
        WindowGroup {
//            ContentViewRectangleFill(grouping: grouping)
            ContentViewAreaFill(grouping: grouping)
        }
    }
}
