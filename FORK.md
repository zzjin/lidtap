# Top-right double-tap fork

Based on LidTap by Yemcube (Instagram [@yem.cube](https://www.instagram.com/yem.cube)). Original license and commercial restrictions remain in LICENSE.

## Behavior

- One physical target: the top-right edge of the open built-in display. One configurable action per existing profile.
- Calibration records separated single taps to reuse the original feature extraction and classifiers. Background examples are required for first-time training; include other edges as negatives.
- Two independently accepted target events, separated by 180–650 ms, dispatch once. A pair is consumed; a third tap cannot reuse the second. The default action is Desktop Right, matching the original top-right default.
- Rejected/gated events, settings changes, calibration, retraining and profile changes cancel the pending pair. Closed-lid events (reported angle below 20°) also cancel it. Sensor timestamps are monotonic.
- The detector refractory interval is fixed at 180 ms. The pre-motion veto is relaxed only while awaiting a second recognised tap because the first tap leaves residual movement. Other input/lid gates, strength, confidence and novelty checks still apply. Hardware tuning is necessary to validate the tradeoff between ringing and missed second taps.
- Privacy Guard still allows click-to-release, but physical activation and release both require double taps. The explicit Try It/menu click action remains an intentional test button, not a physical single-tap trigger.
- Internal `Grid`/`z0` types remain for storage/ML compatibility, but the application enforces a single target and exposes no layout chooser. Historical Python prototype/research code remains unchanged.

## Independent installation

Bundle ID: `dev.zzjin.LidTapDoubleTap`. Installed app: `~/Applications/LidTap Double Tap.app`. Data: `~/Library/Application Support/LidTapDoubleTap`. Original data is not modified. Incompatible multi-zone datasets loaded through a custom data directory are discarded in memory, not silently relabelled.

Automatic update checking defaults off. The updater refuses checks until its placeholder Team ID is replaced with the fork maintainer's own signing identity. Its feed points to `zzjin/lidtap`, never upstream. `release.sh` still requires your Developer ID and notarization credentials. CI artifacts use ad-hoc signing, not Apple notarization.

## Validation

`LidTapApp/scripts/test.sh ml detector doubletap` runs the retained core tests and new gesture/dispatch tests on macOS. The old application/UI/profile/update tests remain available explicitly but contain upstream behavior assumptions and need porting before inclusion in default CI.

On the Linux development host, `git diff --check` and shell syntax validation pass. Native Swift/AppKit compilation must run on macOS. Attempting the historical Python tests on Linux fails at Apple's `IOHIDCheckAccess` symbol; it is not a portable replacement for native testing.

Manual acceptance on a supported MacBook:

1. Grant permissions and calibrate the top-right edge plus background bumps.
2. Single tap: no action. Double tap within 180–650 ms: exactly one action. Triple tap: one action. Pause beyond 650 ms: starts a new pair.
3. Tap other corners, type, scroll, move the lid and knock the desk: no actions. Repeat on each profile/surface.
4. Pause/resume, switch profiles or actions between taps: no stale pair.
5. Verify every existing action, including double-tap Privacy Guard activation/release and click recovery.
6. Verify separate installation/data, build ZIP and any locally configured Developer ID/notarization flow.

Recognition accuracy and real sensor double-tap timing are not proven by fixture tests; validate on the actual MacBook before relying on actions with side effects.
