//
//  AreaFillEntry.swift
//  DemoChartInFill
//
//  Created by on 4/2/26.
//


//
//  ContentView.swift
//  DemoChartInFill
//
//  Created by m0s0l1z on 4/2/26.
//
import Charts
import SwiftUI

struct ContentViewAreaFill: View {
    var grouping: SizeRegistryGrouping

    var body: some View {
        let scale = grouping.measured.maxScale()
        let closedRange = grouping.measuredRange(scale: scale, padding: true)
        let areaFill = grouping.areaFillEntries(scale: scale)

        VStack(spacing: 6) {
            Chart {
                // --- Fill between measured and threshold ---
                // RectangleMark instead of AreaMark: each point is an independent
                // rectangle, so per-point coloring works (AreaMark applies one
                // color to the entire series, which breaks at crossing points).
                ForEach(areaFill) { entry in
                    // Measured is under Threshold
                   AreaMark(
                       x: .value("Date", entry.measured.date),
                       yStart: .value("Start", entry.measuredScaled),
                       yEnd: .value("End", entry.maxValue)
                   )
                   .foregroundStyle(by: .value("IsUnder", entry.isUnder))
                   .interpolationMethod(.stepStart)

                   // Measured is over Threshold
                   AreaMark(
                       x: .value("Date", entry.measured.date),
                       yStart: .value("Start", entry.thresholdScaled),
                       yEnd: .value("End", entry.maxValue)
                   )
                   .foregroundStyle(by: .value("IsOver", entry.isOver))
                   .interpolationMethod(.stepStart)
                }

                // --- Measured line (Stepwise) ---
                ForEach(grouping.measured, id: \.id) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Size in \(scale)", entry.scaleFor(scale: scale)),
                        series: .value("Series", "Measured")
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.stepStart)
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                    .symbolSize(20)
                }

                // --- Normal threshold line (dashed orange, step) ---
                ForEach(grouping.normalThreshold, id: \.id) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Size in \(scale)", entry.scaleFor(scale: scale)),
                        series: .value("Series", "Threshold")
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .interpolationMethod(.stepStart)
                    .foregroundStyle(.orange)
                    .symbol(.diamond)
                    .symbolSize(16)
                }
            }
            .chartForegroundStyleScale([
                "over": .red.opacity(0.2),
                "under": .green.opacity(0.2),
                "not": .clear
            ])
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color(nsColor: .controlBackgroundColor))
                    .border(.gray.opacity(0.2), width: 0.5)
            }
            .chartXAxisLabel("Date")
            .chartYAxisLabel("Size in \(scale)")
            .chartXAxis {
                AxisMarks(
                    values: .stride(by: .day, count: 30)
                ) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.gray.opacity(0.2))
                    AxisTick()
                    AxisValueLabel(
                        format: .dateTime.month(.abbreviated).day(),
                        orientation: .vertical
                    )
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 8)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.gray.opacity(0.2))
                    AxisTick()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(
                                "\(doubleValue.formatted(.number.precision(.fractionLength(1)))) \(scale)"
                            )
                            .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: closedRange)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
