//
//  SizeRegistryEntry.swift
//  DemoChartInFill
//
//  Created by on 4/2/26.
//
import Foundation

enum SizeRegistryCategory: String, Codable {
    case Measured
    case Threshold
}

struct SizeRegistryEntry: Codable, Identifiable, Equatable {
    var epochDate: Double
    var pluginComponent: String
    var sizeInBytes: Double
    var codeOwners: [String]
    var id = UUID()
    var category: SizeRegistryCategory
    /// Whether the threshold value comes from a temporary bypass/exception
    /// rather than the base allotment. `false` for legacy CSV rows that
    /// predate the 6th column.
    var isTemporaryException = false

    func scaleFor(scale: String) -> Double {
        ByteFormatter.scaled(sizeInBytes, to: scale)
    }

    static func == (lhs: SizeRegistryEntry, rhs: SizeRegistryEntry) -> Bool {
        lhs.id == rhs.id
    }

    var date: Date {
        Date(timeIntervalSince1970: epochDate)
    }

    /// Human-readable formatted date string.
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    /// Human-readable size string (e.g. "14.92 MB").
    var formattedSize: String {
        ByteFormatter.format(sizeInBytes, signed: false)
    }
}
