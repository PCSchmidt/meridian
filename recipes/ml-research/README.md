# Meridian Recipe: ml-research

A gate model and project templates for machine learning and data science projects.

**Reference implementation:** PyTorch + FastAPI  
**Also works with:** scikit-learn, TensorFlow, JAX, HuggingFace, any ML stack  
**This is the unique differentiator** — no other agent framework enforces ML methodological decisions.

---

## Install

```bash
bash path/to/meridian/install.sh <your-project-dir> --recipe ml-research
```

This installs:
- `.claude/hooks/` — enforcement hooks (PreToolUse, PostToolUse)
- `.claude/skills/` — 15 slash-command skills
- `.claude/agents/` — gate-evaluator, drift-evaluator, spec-reviewer
- `.meridian/gates.yaml` — this recipe's gate DAG
- `.meridian/` — schema files, security-rules.yaml, runtime skeleton
- `CLAUDE.md` — session-start context for agents

---

## Gate DAG

```
data_contract ──► pipeline_validated ──► model_eval ──►┬──► [ablation_study]
                                                        ├──► [evidence_pdf]
                                                        └──► deploy_ready
```

Gates in `[brackets]` are optional (warn on failure, don't block).

| Gate | Type | Artifacts required | Why it exists |
|------|------|--------------------|---------------|
| `data_contract` | human_approval | DATA_CONTRACT.md, DECISIONS.md | Human locks target metric, baseline, and eval thresholds before any code runs |
| `pipeline_validated` | automated | — (runs pipeline hooks) | Schema, split integrity, preprocessing correctness — agent blocked until all pass |
| `model_eval` | human_approval | EVAL_RESULTS.md, MODEL_CARD.md | Human reviews results vs contract; automated benchmark must pass thresholds first |
| `ablation_study` | human_approval (optional) | ABLATION_RESULTS.md | Research projects need systematic component removal; production may skip |
| `evidence_pdf` | automated (optional) | — (generates PDF) | Compile results into a portable artifact; required for academic submission |
| `deploy_ready` | human_approval | DEPLOYMENT_CONFIG.md, CHANGELOG.md, MODEL_CARD.md | Final check: serving config, latency test, model export before production |

---

## Quick Start

**Step 1 — Install Meridian:**
```bash
bash install.sh <your-project-dir> --recipe ml-research
```

**Step 2 — Write DATA_CONTRACT.md** (use `foundation/DATA_CONTRACT.md.template`)

This is the most important artifact for ML projects. It forces you to write down:
- What data you're using and its schema
- What you're predicting (the target)
- What metric defines success, with a numeric threshold
- What the baseline is (the thing your model must beat)

Agents cannot train a model without this. The contract exists to prevent
"try everything and see what works" — a pattern that is maximally expensive
and minimally reproducible.

**Step 3 — Write SPEC.md** (use `foundation/SPEC.md.template`)

Use `##` headings for each capability — they become FEATURES.json entries:
```bash
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/features-init.sh
```

**Step 4 — Verify your data pipeline gates**

```bash
# Once pipeline_validated passes, this shows pipeline lifecycle state
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/features-report.sh --full
```

**Step 5 — Work gate-by-gate**

```bash
# Check current gate
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/gate-engine.sh current

# Run drift check (catches when SPEC diverges from what's built)
MERIDIAN_PROJECT_DIR=. bash path/to/meridian/scripts/drift-check.sh
```

---

## The DATA_CONTRACT Pattern

The central idea of this recipe: **the human defines the experiment, the agent runs it.**

Without a data contract, an agent building an ML model will:
1. Pick a model architecture based on what it knows (usually "try a neural network")
2. Train without a defined stopping criterion
3. Report accuracy on the training set
4. Call it done

With a data contract:
1. The human specifies: target, metric, threshold, baseline, train/val/test split
2. The agent implements the pipeline to those specs
3. `pipeline_validated` gate confirms data integrity before training
4. `model_eval` gate compares results against contract thresholds
5. Human approves eval — the agent cannot self-certify

**Example contract (AeroIntel):**

> Data source: OpenSky Network REST API  
> Schema: {icao24, callsign, latitude, longitude, altitude, velocity}  
> Target: Anomaly flag (boolean)  
> Metric: Precision ≥ 0.85, Recall ≥ 0.70 at 5% contamination rate  
> Baseline: IsolationForest with default parameters  
> Deploy: Railway (backend) + Vercel (frontend)

---

## Adapting for Your Stack

| Use case | Change |
|----------|--------|
| scikit-learn | Same gates; replace `run-benchmark.sh` with sklearn evaluation script |
| HuggingFace fine-tuning | Add `pretrained_model` field to DATA_CONTRACT.md; add `validate-tokenizer.sh` to `pipeline_validated` |
| Classification | Add `confusion_matrix` to EVAL_RESULTS.md template |
| Time-series | Add `validate-temporal-splits.sh` to `pipeline_validated` (no future leakage) |
| No deployment | Remove `deploy_ready` gate or mark `required: false` |
| Academic paper | Promote `ablation_study` and `evidence_pdf` to `required: true` |
| Batch inference only | Replace `test-inference-latency.sh` with batch throughput test |

---

## Reference: ml-research Gate Hooks

| Hook | Purpose |
|------|---------|
| `validate-data-contract.sh` | Checks DATA_CONTRACT.md has required sections |
| `validate-schema.sh` | Verifies actual data schema matches contract |
| `validate-splits.sh` | Checks train/val/test split ratios and no leakage |
| `validate-preprocessing.sh` | Null handling, encoding, normalization correctness |
| `run-pipeline-tests.sh` | Unit tests for data pipeline code |
| `run-benchmark.sh` | Runs model evaluation against contract baseline |
| `validate-metrics.sh` | Checks eval results meet contract thresholds |
| `generate-model-card.sh` | Scaffolds MODEL_CARD.md from training run metadata |
| `validate-serving-config.sh` | Checks DEPLOYMENT_CONFIG.md completeness |
| `test-inference-latency.sh` | Measures inference time against latency budget |
| `export-model.sh` | Exports to ONNX, TorchScript, or pickle |

The Meridian-provided hooks (`block-dangerous.sh`, `run-evaluator.sh`) run automatically.
The above are project-specific hooks you write.

---

## Why This Recipe Exists

The `ml-research` recipe addresses the failure modes unique to ML projects:

1. **Agent makes methodological decisions** — the `data_contract` gate forces a human to define target, metric, threshold, and baseline before any training. The agent implements, the human decides.
2. **Training on contaminated data** — `pipeline_validated` runs schema validation and split-integrity checks automatically; no training begins until all pass.
3. **Eval gaming** — `validate-metrics.sh` checks thresholds against the contract baseline, not against the current run's best epoch. The human reviews and approves.
4. **Irreproducible results** — `MODEL_CARD.md` is required at `model_eval`; it captures architecture, hyperparameters, training config, and known limitations.
5. **Deploying without a latency contract** — `deploy_ready` requires `test-inference-latency.sh` to pass; inference time is part of the contract, not an afterthought.
