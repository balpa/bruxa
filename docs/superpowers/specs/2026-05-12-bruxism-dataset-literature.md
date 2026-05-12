# Bruxism Detection — Literature & Dataset Review

**Date:** 2026-05-12
**Status:** Decision document. Reframes the original Path A / Path B choice.
**Inputs:** Three parallel research agents covering (1) public datasets, (2) wrist↔jaw coupling evidence, (3) prior systems and commercial landscape.

---

## TL;DR

Three findings change the original framing:

1. **No public dataset exists that pairs masseter EMG with wrist accelerometry during sleep.** Both Path A (EMG pilot → CoreML) and Path B (heuristic MVP) assumed we'd eventually train such a model. The training-data gap is total.

2. **The biomechanical premise is weak.** Wrist-only IMU detection of bruxism has a theoretical sensitivity ceiling of ~50%, because only 40–55% of bruxism episodes co-occur with arm movement in PSG-controlled studies — and that co-occurrence is *arousal-mediated*, not mechanical jaw→wrist coupling. Ear-canal IMUs (5–10 cm from jaw, rigid skull) achieve 66–76% clenching accuracy; the wrist is 60–80 cm further along multiple compliant joints.

3. **The commercial niche is wide open at the validated end.** No App Store product currently uses Apple Watch motion sensors for passive sleep-bruxism detection with any published accuracy backing. BruxApp uses the Watch only as a prompt delivery device. The opening is real — but the technical bar to clear is high (>80% sens AND spec to match Sleep Profiler, the only ambulatory device currently meeting both).

**Recommendation:** Reject the original A vs B framing as posed. Three more honest options:

- **Option 1 (Pivot — recommended):** Re-scope to a *companion + data-collection* product. Track sleep-quality + arousal-correlated motion + audio (phone microphone on nightstand), and let users optionally pair with their existing EMG splint to *contribute paired data*. Position as "sleep wellness with bruxism indicators," not "bruxism detector." Build the dataset nobody else has, then earn the right to ship a real detector in v2.
- **Option 2 (Audio-led):** Switch primary sensor from wrist IMU to nightstand iPhone microphone. Bruxism has a distinctive acoustic signature (stick-slip dental grinding sounds), and microphone-based detection has *more* evidence than wrist-IMU. Watch becomes a secondary signal (HR + arousal motion).
- **Option 3 (Stop):** Conclude that consumer-grade wrist-only bruxism detection isn't viable today and redirect to an adjacent niche (e.g., BFRB intervention — option C from the original brainstorm, which has stronger biomechanical grounding for wrist sensing).

Detailed reasoning, dataset survey, evidence table, and design implications below.

---

## 1. Public Dataset Survey

### 1.1 The headline gap

No public repository (PhysioNet, Mendeley Data, Zenodo, OpenNeuro, IEEE DataPort, figshare, Kaggle, NSRR, university pages) contains a dataset combining **masseter or temporalis EMG with wrist accelerometry during sleep**. This was confirmed across 12+ targeted queries. Public PSG databases use only chin (submental) EMG for sleep staging; masseter EMG is systematically absent from open repositories.

### 1.2 Closest open datasets

| Dataset | n / hours | Modalities | Bruxism labels? | License | Commercial use | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| **DreamCatcher** (NeurIPS 2024, Tsinghua) | 24 subjects / ~210 hours | In-ear audio + IMU (accel+gyro), both ears | Yes — *teeth grinding* event label among 8 sleep events; human-annotated, no PSG ground truth | MIT (audio); full IMU on author email | Audio: yes. Full IMU: unclear | The only open dataset with IMU-labeled bruxism events from real sleep. Ear-worn, not wrist-worn, but the closest analog. **Useful for pre-training motion-based classifiers.** |
| **PhysioNet Sleep-Accel** | 31 subjects / 31 nights | Apple Watch accel (g) + HR (bpm) + PSG sleep stages | No bruxism — only sleep stages | ODC-By | Yes | Same hardware as our target. **Useful only for the sleep-stage detection layer**, not bruxism per se. |
| **CAP Sleep Database** | 108 subjects, 2 bruxism | PSG (EEG, chin EMG, EOG, ECG); no masseter | Diagnostic label per patient (n=2); no episode-level RMMA | ODC-By | Yes | Too few bruxism patients, wrong EMG channel. Several ML papers have used it; their accuracy claims are not trustworthy at n=2. |
| **Sunrise/Pérez 2021 (private)** | 67 OSA patients | Chin IMU + bilateral masseter EMG + full PSG; 79,650 epochs scored against AASM RMMA | Yes — gold standard | CC BY-NC; "available on request" | No | **Scientifically rigorous. Privately held.** Worth emailing the Sunrise / Lobbezoo group; possible academic collaboration. Not in commercial path. |
| **DREAMS** (Zenodo) | ~47 subjects | PSG + chin EMG | No bruxism | CC BY-NC-ND | No | Not viable for commercial product. |
| **Sleep-EDF Expanded** | 78 subjects / 197 nights | PSG + chin EMG (1 Hz!) | No bruxism | ODC-By | Yes | Large but irrelevant for bruxism. |

### 1.3 Translation

- **No open dataset can train a wrist-bruxism CoreML model directly.**
- DreamCatcher could *pre-train* a motion classifier on in-ear IMU and transfer to wrist-IMU — but the transferability across this much anatomical distance is unproven.
- A custom pilot remains necessary if we proceed with wrist-IMU.
- One academic collaboration path: reach out to the Sunrise/Lobbezoo (Amsterdam) group for the chin-IMU+masseter-EMG dataset under a research agreement.

---

## 2. Biomechanical Evidence — Wrist↔Jaw Coupling

### 2.1 What we hoped to find

We wanted: peer-reviewed evidence that masseter contractions during sleep transmit measurable acceleration to the wrist, with quantified sensitivity for an IMU sensor.

### 2.2 What we actually found

**No direct coupling study exists.** Not a single peer-reviewed paper has placed a wrist IMU synchronously with masseter EMG during sleep bruxism. This is not "evidence against," it is a complete absence of supporting evidence. The closest is a 270-subject chest-accelerometer study (Saczuk 2022) showing elevated *trunk* motion during bruxism epochs, with no isolation of wrist signal.

### 2.3 The damning indirect evidence

Two PSG-controlled studies on co-occurrence of bruxism and limb movements:

- **Carra et al., 2017** (J Sleep Res, n=8): 85% of bruxism episodes co-occur with limb movements — but **70.5% of those limb movements *precede* bruxism onset**, indicating the wrist sees the arousal event, not a mechanical consequence of jaw motion.
- **Makino et al., 2021** (J Sleep Res, larger PSG cohort): RMMA episodes co-occur with arm movements in only 40–55% of cases, and "*no consistent temporal pattern*" links jaw activity to body movement.

**Implication:** Even a theoretically perfect wrist-IMU classifier — one that detects every single arm movement perfectly — would catch at most 40–55% of bruxism episodes. That's the ceiling, and it's below the >80% sensitivity threshold the 2024 ambulatory-device review uses to define clinical utility.

### 2.4 Signal attenuation argument

Adjacent biomechanics literature gives the engineering perspective:

- Hand-arm vibration transmissibility (Lundström et al.) measures ~0.3 at 6–12 Hz from hand to neck. The reverse direction (jaw → wrist) adds the atlanto-occipital, cervical, shoulder, elbow and wrist joints in series — all compliant, all attenuating.
- Even an *ear-canal* gyroscope on the same rigid skull as the jaw (Kalantarian et al. 2021, n=13) achieves only **66–73% accuracy for clenching** in real-world conditions, vs. 76–88% for grinding.
- Bruxism jaw kinematics: RMMA fundamental at 1 Hz, stick-slip grinding micro-vibration at 5–10 Hz, sub-millimeter displacement amplitude. At the wrist, this signal is buried under PLM, REM micro-movements, and positional shifts that live in the same 1–10 Hz band.

### 2.5 The one path that *isn't* refuted

Two design choices the literature leaves open:

1. **Arousal-mediated detection.** Use the wrist IMU to detect the *pre-bruxism arousal burst* (limb movement 30–60 s before episode onset) combined with HR acceleration. This is a *predictor*, not a *detector*, but in some product framings that's enough.
2. **Hand-on-cheek posture amplification.** Lateral sleep with wrist dorsum against the cheek would mechanically couple masseter to wrist IMU via bone-to-bone contact. Biologically plausible, *completely uncharacterized* — no study has measured this. If it works, the product would target lateral sleepers specifically.

### 2.6 Verdict on the original premise

**WEAK BUT PLAUSIBLE — with a near-certain requirement for multimodal sensing.** Wrist IMU alone, as the primary detector, will not clear the clinical-utility bar. Wrist IMU as one channel in an HR+HRV+motion+audio fusion, with carefully framed claims, *might*.

---

## 3. Commercial & Academic Landscape

### 3.1 The validated bar is high

The 2024 narrative review of 8 ambulatory bruxism devices (PMC11937739) used >80% on *both* sensitivity and specificity vs. PSG-AV as the clinical-utility threshold. The result:

- **Sleep Profiler** (multi-channel forehead EEG+EMG) — only device clearing both
- **Bruxoff** (masseter EMG + ECG) — sens 83%, spec 72% — fails specificity
- **Sunrise** (chin IMU) — sens 84%, balanced acc 86%, AUC 0.98 — close to threshold but limited to OSA cohort
- **GrindCare** (single-channel temporal EMG) — fails both
- **BiteStrip** (effectively withdrawn from market)
- **No wrist-based device on the list.**

### 3.2 The consumer landscape is barely occupied at the validated end

- **BruxApp** (App Store, Apple Watch companion): the only well-cited consumer product, but it's an *ecological momentary assessment* tool (timed self-report prompts), not a passive sensor detector. 30+ peer-reviewed publications. CE-marked Class I in Europe.
- **Do I Snore or Grind** (BruxLab → SleepScore): microphone-based; documented false-positive complaints in App Store reviews; no peer-reviewed accuracy.
- **byteSense** (Bluetooth night guard with force sensors): no clinical validation, compliance risk.
- **SOVN** (smart earbuds with IMU + biofeedback): early-stage, no peer review.
- **Garmin / Fitbit / Apple Health**: none offer bruxism detection.
- **GrindCare**: markets a 58% headache-reduction figure as if it were accuracy — this is a patient-reported outcome, not diagnostic performance.

### 3.3 Failed patterns to avoid

The research surfaced a clear set of mistakes prior products made:

1. Validating against task labels or self-report instead of PSG-AV.
2. Training on a single sleep posture; generalization fails.
3. Reporting sensitivity OR specificity, never both.
4. Marketing a patient-reported outcome (headache reduction, sleep quality) as if it were diagnostic accuracy.
5. Conflating awake-bruxism EMA with sleep-bruxism detection.
6. Overestimating episode counts (~40% false-positive rate is typical in ambulatory EMG — the wrist will be much worse).
7. Tuning sensitivity threshold via consumer UI ("medium sensitivity") with no clinical calibration.

### 3.4 Architecture borrowings (if we proceed with wrist)

- **No published pretrained CoreML or PyTorch model exists** for bruxism detection.
- HAR (human activity recognition) backbones — CNN-LSTM hybrids on 6-axis IMU, 50–100 Hz windows — are the closest reusable architecture pattern.
- **Gyroscope > accelerometer** for jaw-related motion (consistent finding across earable studies).
- Time-domain features (RMS, zero-crossing rate, slope sign change, waveform length) from the EMG-posture study (Gul 2024) translate cleanly to IMU.
- XGBoost on hand-engineered features (the Sunrise/Pérez 2021 approach) achieved Kappa 0.799 against PSG — but with chin sensor, not wrist.

---

## 4. Design Implications (if we proceed with the original plan anyway)

If — despite Section 2 — we still want to build the wrist-IMU detector:

- **Sample rate:** 50 Hz Apple Watch IMU is adequate. Going higher buys nothing for the relevant signal bands.
- **Frequency bands:** 0.5–3 Hz (RMMA envelope) + 4–12 Hz (grinding micro-vibration). Band-pass alone is insufficient — same band as PLM, positional shifts, REM micro-movements.
- **Window size:** ≥3 seconds (AASM minimum: 3 phasic bursts).
- **Include gyroscope:** Earable evidence consistently shows gyro outperforms accel for jaw-related motion.
- **Multimodal fusion (necessary, not optional):** HR + HRV from Apple Watch PPG, sleep stage from HealthKit, motion features from IMU. Heart rate accelerates 1–3 s before RMMA onset (well-documented).
- **Posture stratification:** Train conditional classifiers per sleep posture (supine / left-lateral / right-lateral). Apple Watch gravity vector gives gross posture cheaply.
- **Confound classes in training set:** Positional shifts, restless leg movements, REM micro-movements, snoring-associated arousals — labelled negatives, not just bruxism-vs-quiet.
- **Honest sensitivity target:** 40–50% episode-level sensitivity, ~80% night-level "any bruxism detected" sensitivity. Specificity must lead messaging.
- **App Store framing:** "wellness tracker" / "sleep monitoring" — NOT "diagnose" / "detect bruxism." Class I medical device path in EU optional; US FDA 510(k) triggered only by diagnostic claims.

---

## 5. The Three Re-framed Options

### Option 1 — Pivot to Companion + Data-Collection Platform (recommended)

**Product:** Sleep-quality + arousal-correlated motion tracker. Frame as "your night-time stress tracker, with a special focus on jaw-clenching indicators." Watch IMU + HR + HRV + sleep stages. iPhone microphone optional ("Bedside Mode") for acoustic episode confirmation. Power-user feature: pair with an existing EMG splint (Bruxoff, Sunrise, dental-clinic device) over Bluetooth to *contribute paired data* in exchange for a free Premium tier.

**Why:**
- Bypasses the biomechanical ceiling — never claims to detect bruxism per se.
- Builds the dataset that doesn't exist. After 1,000 paired nights from users, we'd own training data nobody else has.
- App Store reviews and 1-star refunds become near impossible to earn — we never promised false precision.
- A real bruxism detector becomes a v2 paid upgrade once the data justifies it.

**Risk:** Marketing is harder. "Sleep stress tracker" is not as crisp as "bruxism detector." Differentiation from Oura / Whoop / AutoSleep is fuzzy without a sharper hook.

**Foundation plan impact:** Most of what we already built is reusable — sensor recording, storage, sleep state, the on-device detector becomes a heuristic arousal-classifier. The training-pipeline tasks (Path A) are deferred until the dataset bootstrap matures.

### Option 2 — Audio-Led Detection (Watch as Secondary Signal)

**Product:** Primary sensor is the iPhone microphone on the nightstand. Watch contributes HR + arousal motion. Bruxism has a *distinctive acoustic signature* (stick-slip grinding, tooth-on-tooth) that propagates through air far better than mechanical signal through soft tissue.

**Why:**
- The acoustic-detection literature is stronger than the wrist-IMU literature. The transducer-placement paper (Nahhas 2024) and even Do I Snore or Grind (despite its false-positive issues) confirm that grinding *sound* is detectable.
- iPhone microphones are higher quality than wrist IMUs as bruxism sensors.
- Apple Watch contribution becomes credible: it adds physiological corroboration (HR spike, arousal motion) to the acoustic primary signal.

**Risk:** Microphone-based has known false-positive issues (snoring partner, ambient noise). The competitor space (SleepScore Labs) is more developed here. Requires phone-side audio processing pipeline we haven't built.

**Foundation plan impact:** Larger pivot. Watch app remains useful but becomes secondary; iPhone app needs an audio capture + on-device ML pipeline (Whisper-style architecture). Significantly more iOS engineering.

### Option 3 — Drop Bruxism, Switch to BFRB (option C from the original brainstorm)

**Product:** Body-focused repetitive behavior (skin picking, nail biting, hair pulling) intervention via real-time wrist-IMU gesture detection. The biomechanics here *actually* favor the wrist: BFRB gestures involve hand-to-face motion, which the Apple Watch IMU is well-suited to detect.

**Why:**
- Wrist IMU is the right sensor for hand-to-face gesture recognition (vs. wrong sensor for jaw motion).
- Active intervention (haptic interruption) has a direct mechanism — vibrate before the hand reaches the face.
- BFRB community is active and underserved (~5% of population, Habit Aware "Keen" wristband already proves market demand).

**Risk:** Different niche, different competitors, restarts the design work. Most of the bruxism-specific code (sleep gating, masseter-frequency band-pass) is wasted; sensor recording and storage carry over.

**Foundation plan impact:** Significant — re-target. The foundation code stays usable (sensors, storage, watchOS shell) but the detection layer and the entire product narrative restart.

---

## 6. Recommendation

**Option 1 (Pivot).** The reasoning:

- The biomechanical evidence is too weak to ship a "bruxism detector" with self-respect. Specificity is the failure mode that earns 1-star reviews and refund requests, and the literature predicts low specificity for wrist-only sensing.
- The dataset gap is real and a moat: whoever ends up holding the first published wrist-IMU + masseter-EMG dataset has an asset competitors can't replicate.
- The foundation we already built is ~90% reusable — sensor recording, sleep state gating, storage, connectivity, the detector protocol — all carry over. Only the marketing framing and the "morning report" narrative shift.
- Option 2 (audio-led) is technically interesting but requires an entirely new iOS audio pipeline and re-enters a more crowded competitive space.
- Option 3 (BFRB) is a respectable retreat but throws away the bruxism-specific design work and re-opens the brainstorming surface area.

If we want to take this path, the next deliverable is a *re-scoped* design spec (replacing `2026-05-11-bruxism-watch-app-design.md` or amending it) that:

1. Renames the product (working title: "Bruxa — Sleep & Stress Companion" or similar).
2. Redefines the morning report around arousal events, HR-spike clusters, motion-restlessness scores, and optionally acoustic events (Bedside Mode v1.1).
3. Defines the EMG-splint pairing flow as the data-collection mechanism — opt-in, rewarded with Premium, used to build the dataset for a real future detector.
4. Removes the "bruxism detection" claim from marketing copy; replaces with "indicators" / "patterns" / "wellness" language.

If we don't want to pivot — i.e., we accept the wrist-IMU ceiling and ship a fundamentally limited detector — then we should at least:

- Drop "detect" / "diagnose" language; use "track" / "monitor."
- Cap the specificity-failure damage with an honest "this is a research-grade indicator, not a clinical diagnosis" onboarding screen.
- Plan for a low (~50%) sensitivity in the model spec, so we don't gaslight ourselves into thinking the model is broken when it's actually hitting the biomechanical ceiling.

---

## 7. References

The full agent reports are not stored in repo (they would be ~30 KB of prose). Key sources cited above, with links:

- Carra et al. 2017 — Bruxism + limb movement co-occurrence: PMID 28735914.
- Makino et al. 2021 — No consistent motor pattern: PMID 33281172.
- Saczuk et al. 2022 — Chest accel + PSG: PMC9599859.
- Lundström et al. 2017 — Hand-arm vibration transmissibility: PMC5672949.
- Pérez/Sunrise et al. 2021 — Chin IMU + masseter EMG: PMC8397703.
- Kalantarian et al. 2021 — eSense earable bruxism: ACM UbiComp/ISWC 2021.
- Nahhas et al. 2024 — Transducer placement: PMC11417139.
- Lavigne et al. 2003 — RMMA neurobiology: DOI 10.1177/154411130301400104.
- 2024 ambulatory bruxism device review: PMC11937739.
- DreamCatcher (NeurIPS 2024): github.com/thuhci/DreamCatcher.
- PhysioNet Sleep-Accel: physionet.org/content/sleep-accel/1.0.0/.
- CAP Sleep Database: physionet.org/content/capslpdb/1.0.0/.
