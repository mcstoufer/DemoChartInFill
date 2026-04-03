//
//  Helpers.swift
//  DemoChartInFill
//
//  Created by on 4/2/26.
//
import Foundation

enum ByteFormatter {
    static let unitNames = ["B", "KB", "MB", "GB", "TB"]

    private static let unitsDescending: [(String, Double)] = [
        ("TB", pow(1024, 4)),
        ("GB", pow(1024, 3)),
        ("MB", pow(1024, 2)),
        ("KB", 1024),
        ("B", 1)
    ]

    /// Returns the best human-readable unit for the given byte value.
    static func bestUnit(for bytes: Double) -> String {
        var value = abs(bytes)
        var idx = 0
        while value >= 1024 && idx < unitNames.count - 1 {
            value /= 1024
            idx += 1
        }
        return unitNames[idx]
    }

    /// Returns the divisor for a given unit string (e.g. "MB" → 1048576).
    static func divisor(for unit: String) -> Double {
        let idx = unitNames.firstIndex(of: unit) ?? 0
        return pow(1024, Double(idx))
    }

    /// Converts bytes to the given unit (e.g. 1048576 bytes → 1.0 for "MB").
    static func scaled(_ bytes: Double, to unit: String) -> Double {
        bytes / divisor(for: unit)
    }

    /// Formats a byte count as a human-readable string (e.g. "12.3 MB").
    static func format(_ bytes: Int64) -> String {
        format(Double(bytes), signed: false)
    }

    /// Formats a byte value as a human-readable string with automatic unit selection.
    static func format(_ bytes: Double, signed: Bool = true) -> String {
        let absBytes = abs(bytes)
        let sign: String = signed
            ? (bytes < 0 ? "-" : (bytes > 0 ? "+" : ""))
            : ""
        for (unit, divisor) in unitsDescending where absBytes >= divisor {
            let value = absBytes / divisor
            let precision = value >= 100 ? 0 : (value >= 10 ? 1 : 2)
            return "\(sign)\(value.formatted(.number.precision(.fractionLength(precision)))) \(unit)"
        }
        return "\(sign)0 B"
    }
}
