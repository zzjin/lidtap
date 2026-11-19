import Foundation

@MainActor
func doubleTapTests() {
    T.suite = "Double tap"
    T.run("single, pair, triple and timeout") {
        var pair = DoubleTap()
        T.expect(!pair.accept(at: 1), "single tap acted")
        T.expect(pair.accept(at: 1.3), "pair did not act")
        T.expect(!pair.accept(at: 1.6), "triple reused second tap")
        T.expect(!pair.accept(at: 3), "expired tap acted")
        T.expect(pair.accept(at: 3.4), "new pair did not act")
    }
    T.run("ringing, invalid times and reset") {
        var pair = DoubleTap()
        T.expect(!pair.accept(at: 0), "single acted")
        T.expect(!pair.accept(at: 0.1), "ringing acted")
        T.expect(pair.accept(at: 0.3), "ringing moved first tap")
        _ = pair.accept(at: 1)
        pair.reset()
        T.expect(!pair.accept(at: 1.3), "reset retained pending tap")
        T.expect(!pair.accept(at: .nan), "invalid timestamp acted")
        T.expect(pair.first == nil, "invalid timestamp retained state")
    }
    T.run("inclusive interval bounds") {
        for interval in [DoubleTap.minimumInterval, DoubleTap.maximumInterval] {
            var pair = DoubleTap()
            _ = pair.accept(at: 0)
            T.expect(pair.accept(at: interval), "boundary rejected")
        }
    }

    // Use recorded top-right samples as target and other corners as negatives.
    // This checks the dispatch pipeline, not real-world double-tap sensor accuracy.
    func harness(_ name: String, kind: ActionKind = .desktopRight) -> AppHarness {
        var data = T.loadDataset()
        data.grid = .singleTarget
        data.samples = data.samples.map { sample in
            var s = sample
            s.label = s.label == "z1" ? "z0" : noiseLabel
            return s
        }
        var config = AppConfig()
        config.actions = ["z0": ZoneAction(kind: kind)]
        config.minConfidence = 0.3
        config.rejectFactor = 5
        return AppHarness(name: name, dataset: data, config: config)
    }
    func tap(_ h: AppHarness, at time: Double, gated: String? = nil, lid: Int = 100) {
        let s = h.app.dataset.samples.first { $0.label == "z0" }!
        h.app.handle(TapEvent(id: Int(time * 1000), time: time, date: Date(), g: s.g, a: s.a,
                             peakG: s.peakG, peakA: s.peakA, lid: lid, threshold: 1, noise: 0.1, gated: gated))
    }
    T.run("action requires two recognised taps; triple fires once") {
        let h = harness("double-dispatch")
        guard h.train() else { return T.fail("training failed") }
        tap(h, at: 10)
        T.expect(h.performed.isEmpty, "single tap acted")
        tap(h, at: 10.35)
        T.expect(h.performed.count == 1, "pair did not act: \(h.app.lastRecord?.detail ?? "")")
        tap(h, at: 10.6)
        T.expect(h.performed.count == 1, "triple acted twice")
    }
    T.run("gated tap, pause and closed lid cancel pending pair") {
        let h = harness("double-cancel")
        guard h.train() else { return T.fail("training failed") }
        tap(h, at: 10)
        tap(h, at: 10.2, gated: "lid moved")
        tap(h, at: 10.4)
        T.expect(h.performed.isEmpty, "gated tap bridged pair")
        h.app.config.enabled = false
        h.app.config.enabled = true
        tap(h, at: 10.6)
        T.expect(h.performed.isEmpty, "pause bridged pair")
        tap(h, at: 10.8, lid: 0)
        tap(h, at: 11)
        T.expect(h.performed.isEmpty, "closed lid bridged pair")
    }
    T.run("Privacy Guard activation and release both need double taps") {
        let h = harness("double-guard", kind: .privacyGuard)
        guard h.train() else { return T.fail("training failed") }
        tap(h, at: 10)
        T.expect(!h.app.privacyGuard.isActive, "single enabled guard")
        tap(h, at: 10.35)
        T.expect(h.app.privacyGuard.isActive, "pair did not enable guard")
        tap(h, at: 12)
        T.expect(h.app.privacyGuard.isActive, "single released guard")
        tap(h, at: 12.35)
        T.expect(!h.app.privacyGuard.isActive, "pair did not release guard")
    }
    T.run("fresh target and incompatible legacy datasets") {
        let h = AppHarness(name: "legacy-recalibration")
        T.expect(h.app.grid == .singleTarget, "legacy layout loaded")
        T.expect(h.app.dataset.samples.isEmpty, "legacy samples silently reused")
        T.expect(h.app.config.actions.count == 1, "multiple actions configured")
        h.app.startCalibration(grid: Grid(rows: 3, cols: 3))
        T.expect(h.app.calibration?.grid == .singleTarget, "multi-zone calibration enabled")
        T.expect(Set(h.app.calibration?.sequence ?? []) == ["z0"], "more than one target")
    }
}
