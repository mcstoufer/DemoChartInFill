//
//  Extensions.swift
//  DemoChartInFill
//
//  Created by on 4/2/26.
//
import Foundation

extension Double {
    public func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    public func scaleFor(scale: String) -> Double {
        return self / pow(1024, Double(["B", "KB", "MB", "GB", "TB"].firstIndex(of: scale) ?? 0))
    }
}

extension RandomAccessCollection {
    /// Returns the element whose extracted key is closest to `target`,
    /// assuming the collection is already sorted by that key.
    ///
    /// Uses binary search (O(log n)) to locate the insertion point,
    /// then compares the two candidates that straddle it.
    ///
    /// - Parameters:
    ///   - target: The value to search for.
    ///   - keyPath: A closure that extracts the comparable key from each element.
    /// - Returns: The nearest element, or `nil` if the collection is empty.
    public func findNearest<T: Comparable & SignedNumeric>(
        to target: T,
        by key: (Element) -> T
    ) -> Element? {
        guard !isEmpty else { return nil }

        // Binary search for the first element whose key is >= target.
        var lowerBound = startIndex
        var upperBound = endIndex

        while lowerBound < upperBound {
            let half = distance(from: lowerBound, to: upperBound) / 2
            let midpoint = index(lowerBound, offsetBy: half)

            if key(self[midpoint]) < target {
                lowerBound = index(after: midpoint)
            } else {
                upperBound = midpoint
            }
        }

        // Target is smaller than every element — first is nearest.
        if lowerBound == startIndex {
            return self[startIndex]
        }

        // Target is larger than every element — last is nearest.
        if lowerBound == endIndex {
            return self[index(before: endIndex)]
        }

        // Compare the two candidates that straddle the insertion point.
        let elementBefore = self[index(before: lowerBound)]
        let elementAfter = self[lowerBound]

        let distanceToBefore = abs(key(elementBefore) - target)
        let distanceToAfter = abs(key(elementAfter) - target)

        return distanceToBefore <= distanceToAfter ? elementBefore : elementAfter
    }
}

extension Array where Element == SizeRegistryEntry {
    func maxScale() -> String {
        ByteFormatter.bestUnit(for: map(\.sizeInBytes).max() ?? 0)
    }
    
    func findNearest(to targetDate: Date) -> SizeRegistryEntry? {
        findNearest(
            to: targetDate.timeIntervalSince1970,
            by: \.epochDate
        )
    }
    
    /// Largest-Triangle-Three-Buckets (LTTB) downsampling.
    ///
    /// Reduces the array to at most `targetCount` entries while preserving
    /// visual shape. The algorithm divides the data into equal-sized buckets
    /// and selects the point in each bucket that forms the largest triangle
    /// area with the previously selected point and the average of the next
    /// bucket. This ensures peaks, valleys, and sharp transitions are
    /// retained while flat/redundant stretches are aggressively reduced.
    ///
    /// - Parameter targetCount: The maximum number of entries in the result.
    ///   If the array already has fewer entries, it is returned unchanged.
    /// - Returns: A downsampled array preserving the first and last entries.
    ///
    /// Reference: Sveinn Steinarsson, "Downsampling Time Series for Visual
    /// Representation" (2013), University of Iceland.
    func downsampled(to targetCount: Int) -> [SizeRegistryEntry] {
        guard count > targetCount, targetCount >= 2 else { return Array(self) }
        
        var result = [SizeRegistryEntry]()
        result.reserveCapacity(targetCount)
        result.append(self[0])
        
        let bucketSize = Double(count - 2) / Double(targetCount - 2)
        var prevSelected = 0
        
        for i in 0..<(targetCount - 2) {
            let bucketStart = Int(Double(i + 1) * bucketSize) + 1
            let bucketEnd = Swift.min(Int(Double(i + 2) * bucketSize) + 1, count - 1)
            
            let nextBucketStart = Swift.min(bucketEnd, count - 1)
            let nextBucketEnd = Swift.min(Int(Double(i + 3) * bucketSize) + 1, count - 1)
            var avgX = 0.0
            var avgY = 0.0
            let nextCount = Swift.max(nextBucketEnd - nextBucketStart, 1)
            for j in nextBucketStart..<Swift.min(nextBucketStart + nextCount, count) {
                avgX += self[j].epochDate
                avgY += self[j].sizeInBytes
            }
            avgX /= Double(nextCount)
            avgY /= Double(nextCount)
            
            let px = self[prevSelected].epochDate
            let py = self[prevSelected].sizeInBytes
            
            var maxArea = -1.0
            var bestIdx = bucketStart
            for j in bucketStart..<bucketEnd {
                let area = abs(
                    (px - avgX) * (self[j].sizeInBytes - py)
                    - (px - self[j].epochDate) * (avgY - py)
                )
                if area > maxArea {
                    maxArea = area
                    bestIdx = j
                }
            }
            
            result.append(self[bestIdx])
            prevSelected = bestIdx
        }
        
        result.append(self[count - 1])
        return result
    }
}
