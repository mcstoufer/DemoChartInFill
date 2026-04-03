//
//  ViewModel.swift
//  DemoChartInFill
//
//  Created by on 4/2/26.
//
import Foundation

struct AreaFillEntry: Identifiable {
    let id: UUID
    let measured: SizeRegistryEntry
    let thresholdScaled: Double
    let measuredScaled: Double

    /// The date of the next measured point — defines the right edge of this entry's rectangle.
    let nextDate: Date

    var isOver: Bool { measuredScaled > thresholdScaled }
}

public struct SizeRegistryGrouping {
    /// Full-resolution data for accurate hover/selection lookups.
    let fullMeasured: [SizeRegistryEntry]
    let fullThreshold: [SizeRegistryEntry]

    /// LTTB-downsampled data for chart rendering — keeps the mark count
    /// low enough for smooth interaction while preserving visual fidelity.
    var measured: [SizeRegistryEntry]
    var threshold: [SizeRegistryEntry]

    /// Threshold entries where no temporary bypass was active.
    let normalThreshold: [SizeRegistryEntry]

    /// Threshold entries where a temporary bypass was active — rendered
    /// with a distinct color (red) and symbol (triangle) on the chart.
    let exceptionThreshold: [SizeRegistryEntry]

    /// Whether any threshold entry in this grouping has a temporary exception.
    let hasExceptions: Bool

    /// Cap for rendered data points per series. 500 provides >1 point per
    /// pixel on typical chart widths while keeping `Chart` body fast.
    private static let maxRenderPoints = 500

    init(measured: [SizeRegistryEntry], threshold: [SizeRegistryEntry]) {
        fullMeasured = measured
        fullThreshold = threshold
        self.measured = measured.downsampled(to: Self.maxRenderPoints)
        self.threshold = threshold.downsampled(to: Self.maxRenderPoints)
        normalThreshold = self.threshold.filter { !$0.isTemporaryException }
        exceptionThreshold = self.threshold.filter { $0.isTemporaryException }
        hasExceptions = self.threshold.contains { $0.isTemporaryException }
    }

    func maxExtents() -> (min: Double, max: Double) {
        let allEntries = fullMeasured + fullThreshold
        let minSize = allEntries.compactMap { $0.sizeInBytes }.min() ?? 0
        let maxSize = allEntries.compactMap { $0.sizeInBytes }.max() ?? 0
        return (min: minSize, max: maxSize)
    }

    func measuredRange(scale: String, padding: Bool = false) -> ClosedRange<Double> {
        let extents = maxExtents()
        let paddingAmount = padding ? 0.05 : 0.0

        let minScaled = extents.min.scaleFor(scale: scale)
        let maxScaled = extents.max.scaleFor(scale: scale)

        let minVal = max(minScaled - (minScaled * paddingAmount), 0)
        let maxVal = maxScaled + (maxScaled * paddingAmount)

        return minVal...maxVal
    }

    /// Pre-compute area fill entries pairing each measured point with its
    /// nearest threshold, so the chart body avoids per-point lookups.
    func areaFillEntries(scale: String) -> [AreaFillEntry] {
        measured.enumerated().map { index, entry in
            let nearest = threshold.findNearest(to: entry.date)
            let nextDate = index + 1 < measured.count
                ? measured[index + 1].date
                : entry.date.addingTimeInterval(86400)
            return AreaFillEntry(
                id: UUID(),
                measured: entry,
                thresholdScaled: nearest?.scaleFor(scale: scale) ?? 0,
                measuredScaled: entry.scaleFor(scale: scale),
                nextDate: nextDate
            )
        }
    }
}
