import Foundation

/// Pairs independently recognised target taps, using the sensor's monotonic clock.
/// A pair is consumed, so a third tap cannot reuse its second tap.
struct DoubleTap {
    static let minimumInterval = 0.18
    static let maximumInterval = 0.65
    private(set) var first: Double?

    mutating func reset() { first = nil }

    func isAwaitingSecond(at time: Double) -> Bool {
        guard let first else { return false }
        return time >= first && time - first <= Self.maximumInterval
    }

    mutating func accept(at time: Double) -> Bool {
        guard time.isFinite else { reset(); return false }
        guard let previous = first else { first = time; return false }
        let gap = time - previous
        if gap >= Self.minimumInterval && gap <= Self.maximumInterval {
            reset()
            return true
        }
        // Ringing/duplicate detections don't become a new first tap.
        if gap >= 0 && gap < Self.minimumInterval { return false }
        first = time
        return false
    }
}
