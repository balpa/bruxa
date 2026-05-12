# Bruxa — Re-scoped Design (post-literature-review)

**Date:** 2026-05-12
**Status:** Draft, supersedes the relevant sections of `2026-05-11-bruxism-watch-app-design.md`
**Source decision:** `2026-05-12-bruxism-dataset-literature.md` Option 1 (Pivot)

---

## Why we're re-scoping

The original design positioned Bruxa as a *bruxism detector*. The literature review showed:

- No public dataset pairs masseter EMG with wrist accelerometry during sleep.
- Wrist-only IMU detection has a hard biomechanical ceiling at ~50% sensitivity (40–55% of bruxism episodes co-occur with arm movement; the co-occurrence is *arousal-mediated*, not mechanical).
- Specificity, not sensitivity, is what kills consumer wearables in this category.

So Bruxa becomes a **sleep-wellness companion with a jaw-clench indicator layer**, not a detector. We never claim to diagnose. We give users a multi-metric morning view of how restless their night was, including a *jaw activity indicator* as one signal among several. Over time we build the dataset that lets a future v2 actually earn the "detector" label.

---

## 1. Positioning

- **Working name:** Bruxa (unchanged — the name is still the right semantic hook for App Store search).
- **One-liner:** "Track how your jaw and body settle at night — sleep wellness with a clench indicator built for Apple Watch."
- **Category:** Health & Fitness → Sleep tracking. Not Medical.
- **App Store framing:** "Track," "monitor," "indicator," "wellness." Never "detect," "diagnose," "treat."
- **Audience:** People who suspect they grind their teeth, want to understand their sleep restlessness, and aren't ready to spend $300+ on a clinical device. Adjacent: Whoop/Oura users dissatisfied with the lack of jaw-specific signals.

## 2. What Bruxa shows the user (the morning view)

Three first-class metrics, ranked by reliability:

1. **Restless Minutes** — total minutes during sleep where motion energy exceeded a quiet-sleep baseline. High evidence base (actigraphy is well-understood), low specificity risk, cheap to compute.
2. **Arousal Events** — count of HR spikes >25% above sleeping baseline lasting >10 s, gated to sleep periods. Well-supported in the literature as a bruxism precursor (HR accelerates 1–3 s before RMMA onset).
3. **Jaw Activity Indicator** — count of motion windows that pattern-match the bruxism kinematic signature (1 Hz RMMA envelope + 4–12 Hz micro-vibration). Honestly labeled in the UI as an *indicator*, not a detection. Includes a confidence band ("low / medium / high evidence").

A timeline view stacks the three across the night so users see whether their jaw indicator clusters align with arousal events — the kind of self-investigation that's useful even when the absolute count is wrong.

**What we deliberately do NOT show in v1:**

- "Number of bruxism episodes." Too easy to be wrong, too easy to be litigated.
- Trigger correlations (caffeine, late meals). Deferred until we have data.
- Multi-night trends beyond 7 days. Free tier shows 7 days, premium unlocks 30/all.

## 3. Optional bootstrap: morning self-report prompt

After each sleep session ends, the Watch prompts (single notification, dismissable, can be turned off):

> "Wake with jaw soreness or dental pain? Yes / No / Unsure"

The answer is stored alongside the night's metrics. Over weeks this gives us a per-user labeled outcome variable — not episode-level ground truth, but *night-level* ground truth, which is enough to:

- Personalize the Jaw Activity Indicator threshold per user.
- Eventually train a model that predicts "high-discomfort morning" from the previous night's motion + HR features.

This is the v1 form of the data-collection moat. It's user-driven, opt-in, on-device, and respects the user's time (single 3-option prompt).

## 4. v1 sensor + processing pipeline

```
HealthKit sleep state (asleep/awake)
        │
        ▼
SensorRecorder (BruxaCore) — Watch CoreMotion @ 50 Hz, 6-axis (accel + gyro)
        │
        ├──► RestlessnessAggregator — 5-min motion-energy bins
        ├──► JawActivityDetector — band-pass (0.5–3 Hz + 4–12 Hz) + window classifier
        │                          (heuristic in v1; ML candidate in v2)
        └──► HealthKit HR samples ──► ArousalDetector — HR-spike clustering
                                          │
                                          ▼
                                  Local CoreData store
                                          │
                                          ▼
                                  WatchConnectivity push (existing)
                                          │
                                          ▼
                                  iPhone morning view (existing RootView, expanded)
```

What this changes from the existing foundation:

- **No EpisodeDetector ML pilot.** The detector layer stays a protocol with a heuristic implementation. The "ML training plan" originally scheduled for after Path A or Path B is deferred indefinitely — we revisit it after 1,000+ user-nights of self-reported data exist.
- **New components in BruxaCore:**
  - `RestlessnessAggregator` — pure function over `[SensorSample]` → minute-bucketed energy scores.
  - `ArousalDetector` — pulls HR samples from HealthKit, identifies spikes, emits `ArousalEvent`s.
  - `JawActivityDetector` — heuristic implementation of the existing `EpisodeDetector` protocol; band-passes the IMU stream and flags windows with sustained 1 Hz envelope + 4–12 Hz micro-vibration. Emits `JawActivityIndicator` events, not `Episode`s (rename to disambiguate from clinical terminology).
  - `MorningReport` — value type aggregating restless minutes, arousal count, jaw indicator count.
- **iPhone RootView** evolves into a real morning report with the three metrics and a timeline. Still SwiftUI-only.

## 5. v1 scope (revised)

In:

- Watch background recording during sleep (already built).
- CoreData persistence on both sides (already built).
- WatchConnectivity sync (already built).
- HealthKit sleep state + HR read (sleep state built; HR read is new).
- RestlessnessAggregator, ArousalDetector, JawActivityDetector (heuristic).
- Morning report on iPhone: three metrics + per-night timeline.
- Morning self-report prompt on Watch.
- Onboarding: HealthKit permission, "this is wellness tracking, not diagnosis" disclosure screen.

Out (deferred to v1.1+):

- Premium subscription (deferred until we have engaged users — premature otherwise).
- iPhone microphone "Bedside Mode" (v1.1 Premium feature).
- EMG-splint Bluetooth pairing (v2 — needs partnership conversations with Bruxoff / Sunrise).
- Trigger correlation analysis (v2 — needs more data).
- PDF export for dental visits (v2 — needs accuracy story we don't have yet).
- Trend graphs beyond 7 days (v1.1).
- Watch haptic intervention during episodes (v2 — the "intervention" play, only sensible after we know the indicator is accurate enough not to cause sleep disruption from false positives).

## 6. What carries over from the existing foundation

The existing code is ~90% reusable:

| Existing component | Fate |
| --- | --- |
| `Episode` | Rename to `JawActivityIndicator` (or keep as `Episode` with a docs note clarifying it's a candidate window, not a clinically-scored event). |
| `SensorSample`, `SensorRecorder` | Unchanged. |
| `EpisodesBatch`, WC coordinators | Rename payload type; transport unchanged. |
| `BruxaStorage` | Unchanged; the schema already stores intensity + isCalibration which map cleanly to the new model. |
| `EpisodeDetector` protocol + `StubEpisodeDetector` | Protocol unchanged; the stub becomes a real `BandPassJawActivityDetector`. |
| `SleepSessionManager` | Unchanged. |
| `SleepStateProvider` + `HealthKitSleepStateProvider` | Unchanged. |
| `SleepAuthorizationCoordinator` | Extended to also request HR read scope. |
| `MotionProvider` + `CoreMotionProvider` | Unchanged. |
| `RootView` + `StatusView` | Expanded — RootView gains the three-metric morning view + timeline; StatusView gets a recording-state indicator and the self-report prompt entry point. |
| `PilotCSVWriter` | Kept for debug — useful for tuning the new detector thresholds. |
| `BruxaModel.xcdatamodeld` | Add `ArousalEvent` entity and `MorningReport` entity (or computed-on-demand from existing rows). |

## 7. Honest claims in onboarding

The first-launch screen will say, in plain terms:

> Bruxa tracks how restless your nights are, how often your heart rate spikes, and gives you a *jaw activity indicator* based on wrist motion. Bruxism (sleep teeth-grinding) can't be diagnosed from a wrist sensor alone — only a sleep clinic with EMG can do that. Bruxa is for tracking patterns and starting a conversation with your dentist or doctor.

This is what protects us from negative App Store reviews, and it's also true. If we shift to it later we'll have a brand-trust problem; if we lead with it we own the high ground in the category.

## 8. Success criteria (3 months post-launch)

- ≥1,000 downloads (assumes minimal marketing — Reddit r/bruxism + ProductHunt launch).
- ≥30% next-day retention; ≥10% day-7 retention (median sleep app benchmarks).
- ≥200 users with ≥7 nights of self-report data → first usable bootstrap dataset.
- App Store rating ≥4.2 with no recurring "false detection" complaint theme.
- Technical: night-over-night metric variance <30% within a user (signal stability — if the same user's "jaw activity indicator" swings 5× day to day we have a noise problem).

## 9. Open questions (defer, but flag)

- **Watch-app prompt timing.** The self-report prompt should fire when the user wakes up and looks at their Watch — not at a fixed time. watchOS workout-style background launch is one option, complication-driven another. Decide at implementation time.
- **HR baseline calibration.** ArousalDetector needs each user's resting nightly HR baseline. First 3 nights become a calibration period — show "still learning" badge in UI.
- **Data export / portability.** GDPR-relevant. Likely Premium feature; v1 ships with a basic JSON export from iPhone Settings.

---

## Next deliverables

1. **Implementation plan** for the re-scoped v1 (this replaces the deferred Detection plan, Reporting UI plan, etc., that the original foundation pointed to). Should be TDD-formatted like `2026-05-11-foundation.md`.
2. **Onboarding spec** (separate plan, smaller) for the wellness-disclosure screen + HealthKit dual-scope request.
3. **Self-report prompt spec** (smaller plan) for the morning Watch notification + storage path.

All three can ship as one combined plan or three separate ones — the existing subagent-driven workflow handles either.
