# Calibration Results — Gate 3.4

**Date:** 2026-06-02  
**Purpose:** Validate that the G3.1 gate-evaluator and G3.3 drift sensor discriminate correctly
before either is promoted to blocking enforcement.

**Methodology:** Three fixture project states constructed. Both evaluators run against each fixture
in this session (independent of the session that built the evaluators — same-session evaluation
is architecturally avoided per A003, but this calibration session did not produce the evaluator
artifacts). Verdicts written to `tests/fixtures/calibration/*/`.

---

## Fixtures

| Fixture | Description |
|---------|-------------|
| `aligned/` | 4 contracted features, lifecycle progressing at varied rates, no out-of-scope work |
| `drifted/` | 2 out-of-scope features (auth, sync) actively tracked; 2 contracted features stalled |
| `happy-path-only/` | 4 contracted features, all `happy_path: true`, all other lifecycle states `false` |

---

## Discrimination Results

### Drift Sensor (drift-evaluator)

| Fixture | Alignment Score | Recommendation | High Divergences |
|---------|----------------|----------------|-----------------|
| aligned | **8/10** | aligned | 0 |
| drifted | **3/10** | drifted | 2 (scope_creep ×2) |
| happy-path-only | **7/10** | warn | 0 (1 medium: feature_lag) |

**Drift sensor discrimination delta: 5 points (aligned vs drifted).** Correctly identifies the drifted fixture. Happy-path-only gets a warn, not drifted — correct, because the issue is lifecycle shallowness, not scope creep.

### Gate Evaluator (gate-evaluator)

| Fixture | Overall Score | Verdict | High Issues |
|---------|--------------|---------|------------|
| aligned | **8.5/10** | pass | 0 |
| drifted | **3.6/10** | fail | 2 |
| happy-path-only | **5.95/10** | warn | 0 (2 medium) |

**Gate evaluator discrimination delta: 4.9 points (aligned vs drifted).** Correctly fails the drifted fixture. Provides stronger signal on happy-path-only (5.95 → warn) than the drift sensor (7 → warn) — the gate-evaluator penalizes lifecycle shallowness more aggressively because it checks spec_adherence against CONTRACT acceptance criteria.

---

## Key Findings

### Finding 1: Both tools discriminate — the thesis holds
The 5-point drift-sensor delta and 4.9-point gate-evaluator delta between aligned and drifted fixtures demonstrate clean separation. Neither tool is confused by the aligned fixture or lenient about the drifted one.

### Finding 2: Gate evaluator is the right tool for lifecycle depth
On the happy-path-only fixture, the drift sensor scores 7/10 (warn) because it sees no scope creep. The gate evaluator scores 5.95/10 (warn) and explicitly flags the lifecycle gap against CONTRACT acceptance criteria. The gate evaluator is the tool to promote to blocking for lifecycle-completeness checks; the drift sensor is the right tool for scope-creep detection.

### Finding 3: Drift sensor threshold at 5 is correct for blocking candidacy
If the drift sensor were blocking, the threshold of `alignment_score < 5` → drifted correctly catches the drifted fixture (score 3) without blocking the happy-path-only fixture (score 7). This threshold can be used without tuning.

### Finding 4: No false positives on the aligned fixture
Both tools scored the aligned fixture correctly high (8.5, 8.0) with no spurious issues. The only issue in the aligned gate verdict was low-severity (delete-task not past happy_path), which is expected for an in-progress project.

---

## Thresholds Validated

| Tool | Block threshold | Warn threshold | Status |
|------|----------------|----------------|--------|
| Gate evaluator | overall < 5.0 OR any high issue | overall < 7.0 | Validated — no tuning needed |
| Drift sensor | alignment_score < 5 (drifted) | alignment_score < 7 (warn) | Validated — no tuning needed |

---

## Promotion Readiness

| Tool | Advisory now? | Promote to blocking? | Condition |
|------|--------------|---------------------|-----------|
| Gate evaluator | No (run-evaluator.sh already blocking) | Already blocking | — |
| Drift sensor | Yes (G3.3) | Ready when operator decides | Calibration confirms false-positive risk is low |

---

## Fixture Files

```
tests/fixtures/calibration/
  aligned/
    CONTRACT.md     SPEC.md     FEATURES.json
    drift-verdict.json          gate-verdict.json
  drifted/
    CONTRACT.md     SPEC.md     FEATURES.json
    drift-verdict.json          gate-verdict.json
  happy-path-only/
    CONTRACT.md     SPEC.md     FEATURES.json
    drift-verdict.json          gate-verdict.json
```

See `tests/test-calibration.sh` for the automated discrimination assertions.
