# Meridian: Evidence Notes

Companion to meridian.md. Labels: Confirmed, Ran it, Per the docs, My reading, Ask the author, Author says. Paths are repository-relative. The clone was never written to; all runs used a scratch copy and a scratch project. The repository contains an earlier explainer file (meridian_MASTER_EXPLAINER.md, added 2026-10-19); it was deliberately not read.

## E1 Fact sheet

| Fact | Finding |
| --- | --- |
| Name, address, licence | meridian; github.com/PCSchmidt/meridian, public. GitHub reports no licence; no LICENSE file in the tree; README says "MIT, see LICENSE (coming in Phase 8)". Confirmed. |
| Kind | Agent harness: shell scripts, hooks, prompt files, templates. Confirmed. |
| Status | v0.1.0 tag on commit b4943f3 (2026-07-23); no GitHub release; README says Phase 8 "Next", ROADMAP says deferred. Confirmed. |
| Size | 60 commits, 2026-05-26 to 2026-10-19; 148 tracked files; about 6,400 lines of shell in scripts, hooks, install, templates; about 4,900 lines in 20 test files. Ran it (wc). |
| Counts | 25 scripts (README says 22), 10 hooks, 15 skills, 3 agents, 3 recipes, 20 test files. Confirmed. |
| Tests | See E7. |
| Needs | bash 4+, jq, yq (mikefarah), git. No paid service, no GPU, no download. Tests make no network calls (grep for curl, wget, docker found none). |
| Deployed / users | GitHub: 0 stars, 0 forks, no releases, 2 page views in 14 days (gh api). Ran it. |
| Related | meridian-jspace, portfolio-kit, gate-enforced-rag, dsh-plugin-honesty-gate, living-docs-architect, agent-framework-bakeoff (TECHNICAL_OVERVIEW; some names differ there: "bake-off", "redteam-blue-gate"). Per the docs. |

## E2 Reading and running log

Read: README, TECHNICAL_OVERVIEW, PHILOSOPHY, ASSUMPTIONS, CALIBRATION, G3.5-FINDINGS, CHANGELOG, CLAUDE.md, CONTRIBUTING (first 60 lines), DEMO_GUIDE, MERIDIAN_ARCHITECTURE_DECISIONS, ROADMAP (all), experiment/GENERATOR_EVALUATOR_VALIDATION.md, docs/gate-model, platform-tiers, memory (120 lines), observability, quickstart (90 lines), gate-engine.sh, meridian-verify.sh, PreToolUse.sh, PostToolUse.sh, block-dangerous.sh, run-evaluator.sh, hook-wrapper.sh, gate-evaluator.md, security-rules.yaml, settings.json, pre-commit, CI template, ml-research gates.yaml, dogfood.sh header, git log. scratch-notes.txt: read first 3.5 KB, prompt list and Syntaris excerpts only.
Not read: other scripts in full, other docs (api-reference, recipes, troubleshooting, windows-install, tier1-verification beyond a grep), the other two agents' prompt bodies, skills bodies, most test bodies, meridian_MASTER_EXPLAINER.md (instructed). AeroIntel and Hard Power Intelligence repositories were not available.
Runs: scratch copy of the clone (fresh git init); HOME pointed to an empty folder; all 20 test files; install.sh into a fresh git repo with the ml-research recipe; attack probes (E4); gh repo and traffic queries (read-only). shellcheck not installed (not run).
Final state: git status in the clone showed no changes before the runs and nothing was written there (Ran it at start; clone untouched afterwards by construction, all runs were in the scratch copy).

## E3 Claims check

Levels: L1 doc matches its source file; L2 reproduced by re-running; L3 independently recomputed.

| ID | Claim (where) | Evidence | Level | Verdict |
| --- | --- | --- | --- | --- |
| CL-01 | Self-score 5.5 vs independent 2.5, delta -3.0 (README, CHANGELOG, experiment file) | Numbers match experiment file; one run, one file, prompts differ in tone | L1 | Supported as recorded; interpretation partly (confounded) |
| CL-02 | 240 passing assertions across 18 suites (README, CLAUDE.md) | 20 test files exist; README also says "All 20 suites pass"; 224 reproduced in 15 files; 5 files had failures in a clean copy | L2 | Contradicted for a fresh copy; internally inconsistent |
| CL-03 | 15 skills, 3 subagents, 10 hooks | Counted | L3 | Supported |
| CL-04 | 22 scripts | 25 .sh files in scripts/ | L3 | Contradicted (stale) |
| CL-05 | shellcheck clean on all hooks (README, CHANGELOG) | shellcheck not installed | none | Not checked |
| CL-06 | MIT licence | No LICENSE file; GitHub licence null | L3 | Unsupported (README admits it is coming) |
| CL-07 | Dogfooded on two production projects; HPI live at a public address | Repos not available; commit 65eab77 says HPI passed 4 gates whose checks never ran | none | Not checked; nine-gates claim partly contradicted by the project's own commit |
| CL-08 | "No other agent framework enforces ML methodology mechanically" (README, recipe) | Unsupported absolute; ml-research ships 0 of its 11 pre-hook scripts, so the gate blocks until user writes them; approval and artifacts are what is enforced | L1 | Unsupported |
| CL-09 | Memory "validated on every write... no silent failure" (README) | PostToolUse validates only Edit/Write to memory paths, returns exit 1 (warn, not block); Bash appends unchecked; commit boundary blocks | L2 | Partly |
| CL-10 | CLAUDE.md under 60 lines | 57 lines | L3 | Supported |
| CL-11 | Calibration thresholds validated (CALIBRATION.md: 8.5/3.6/5.95 and 8/3/7) | Values match fixtures; three hand-built fixtures, judged in one session | L1 | Partly (n=3) |
| CL-12 | Estimates improve; multiplier converges toward 1.0 (README, PHILOSOPHY) | ROADMAP table shows 0.18 to 0.93 and itself says the low values are not convergence | L1 | Unsupported as a result; stated as goal |
| CL-13 | Gate pass requires checks, deps, artifacts, approval (gate-model.md) | Probed: refusals confirmed (E4) | L2 | Supported |

## E4 Rule attacks

Scratch project from install.sh (ml-research). Results (Ran it):
- P1/P2 mark-passed human gate: refused (artifacts missing first; approval path covered by tests).
- P3 verify with undeclared hook: exit 2; with MERIDIAN_ALLOW_MISSING_HOOKS=1 passes with warning.
- P4 `rm -rf /` blocked (exit 2); `rm -rf ./build` allowed; `rm --recursive --force /` NOT blocked.
- P5 Write to gate-state.json blocked; Bash redirect blocked; split-quote file name (`gate-st""ate.json`) NOT blocked.
- P6 agent `mark-passed ... --approve` blocked. P9 a commit message containing those words also blocked (false positive).
- P7 Write of own verdict file allowed; P10b forged verdict {score 9, verdict pass} accepted by run-evaluator (rc 0). P10c pass with score 3 blocked; P10d warn with score 9 accepted; non-numeric score blocked; malformed JSON blocked; missing verdict blocked.
- P8 AWS key in Write blocked; generic secret literal only warns.
- P11 two-gate cycle detected (rc 3). Gate requiring undefined gate "zzz": validate and check-circular pass; `current` prints all_complete; can-proceed says blocked. Defect.
- P11c invalid type rejected; P12 empty file rejected.
- P13 hand-edited state with human gate passed: meridian-verify fails (rc 1).
- P14 without jq/yq on PATH, can-proceed prints a warning and returns 0 (permissive). P15 PreToolUse in a non-Meridian folder: exit 0 for `rm -rf /`.
- Pre-commit with an invalid corrections.jsonl: commit rejected; `--no-verify` commits.
- PostToolUse with invalid memory via Write: exit 1 (non-blocking); via Bash append: exit 0, unchecked.

## E5 Code map

scripts/ (gate-engine.sh 565 lines: validate, check-circular, current, can-proceed, verify, mark-passed; meridian-verify.sh; validate-memory.sh; write-reflexion.sh; log-event.sh; session.sh; health-report.sh; status-report.sh; drift-check.sh; features-init/report.sh; gen-rules.sh; dogfood.sh; meridian-doctor.sh and others). .claude/hooks/ (hook-wrapper.sh library; PreToolUse.sh; PostToolUse.sh; SessionStart.sh; block-dangerous.sh; run-evaluator.sh; run-tests.sh; validate-contract/spec/roadmap.sh). .claude/agents/ (gate-evaluator, drift-evaluator, spec-reviewer). .meridian/ (schemas, security-rules.yaml with 11 rules: 3 destructive block, 3 destructive warn, 2 secret block, 1 secret warn, 2 SQL warn). recipes/{fullstack-web, cli-tool, ml-research}. templates/{pre-commit, meridian-ci.yml, CLAUDE.md}.

## E6 Model call sites

No model is called from code. Judge agents are prompt files invoked by the coding agent's subagent facility (/evaluate, /review, /drift-check). Verdicts are files read by run-evaluator.sh and drift-check.sh. Model, temperature and cost are not specified anywhere. Cost fields exist in the telemetry schema; the roadmap says capture awaits a token source. Confirmed.

## E7 Tests and CI

Ran it, 20 files, HOME set to an empty folder, scratch copy:
passed fully (15): calibration 21, detect 8, dogfood 22, drift 15, gate-enforcement 19, gate-passing 26, gen-rules 7, hook-contract 9, hooks 7, lifecycle 19, memory-hooks 22, security 14, skills 19, telemetry 8, verify 8 = 224.
failures (5): health 8/12, integration-phase1 8/9, integration-phase2 16/19, doctor (rc 1, count not captured), status (rc 1, count not captured). For health, status, phase1 the failing lines concern missing gate/calibration data; corrections.jsonl and other runtime files are gitignored (.gitignore). Cause for doctor and phase2 not established (My reading: same family).
CI: no .github directory in the repo; templates/meridian-ci.yml is installed into other projects and runs only meridian-verify.sh. The README claim "shellcheck clean" was not checked.
Spot checks: not done (Ask the author / reviewer). Tests were written by AI agents (Per the docs: commit credits).
Coverage: not measured.

## E8 Plan-versus-results and history

First commit 2026-05-26 (decisions); experiment commit 2026-05-28 precedes the foundation and scripts (order confirmed by log). Commits per day: 05-26 1, 05-28 9, 05-29 2, 06-01 8, 06-02 12, 06-03 9, 06-04 5, 07-21 1, 07-22 2, 07-23 3, 09-04 3, 09-29 4, 10-19 1. Credit lines (by commit): Claude Sonnet 4.6 22, Opus 4.8 17, Opus 5.5 5 (one says 1M context), Sonnet 4.5 5; 11 commits without a credit line (the first 8 on 05-26/28 plus three on 09-04). All commits authored as Chris Schmidt. The plan was committed before the results it describes, but the experiment results and the plan arrived within days; no locked protocol with a success rule. Hours in ROADMAP (about 134 across phases 0-6, 148.5 incl. 7) sit over a 10-day span of commits; whether timed is unknown.

## E9 Gates and approvals

Approval records: gate-state.json "approvals" holds git user.name and time written by mark-passed. Identity is a configurable git name, not authenticated. Per the gate-model doc, forged approvals show in the committed diff. gate-state.json is not gitignored? (.gitignore does not list it; Confirmed) so diffs are visible.

## E10 Environment

Tools used: bash 5.3 (Git for Windows), jq 1.8.2, yq 4.53.6. Docs require bash 4+. No lockfile; the CI template installs yq from the latest release. Results do not depend on package versions apart from tool behaviour (CRLF from Windows jq, handled in code).

## E11 Security and privacy

Secret scan (patterns for AWS keys, private keys, common token prefixes) over tracked files and history: only documentation text and a fake private-key fixture in tests/fixtures/hook-stdin (commit f3c8cf9). No real secret found. README lists the author's public email; ARCHITECTURE_DECISIONS contains a local path to a fork (a local user-folder path, line 504), a minor privacy leak in a public repo. Outside services: none called by code. Security hooks fail open without jq; non-Meridian folders are unprotected.

## E12 Shortcomings register (High and Medium)

1. Verdict author not verified (High). Evidence: P7, P10b. Options: (A) document the limit; (B) only a script writes verdicts after launching the judge; (C) sign verdicts. Gains/costs: A free but no protection; B moderate work, depends on platform; C complex, key handling. Recommend A then a cheap hook rule blocking Write/Edit to .meridian/evaluator by the coding agent. Effort small, payoff high. Verify: repeat P7 and expect exit 2.
2. Headline experiment confounded (High for credibility). One file, prompts differ in tone. Options: repeat with controlled prompts and N runs; or reword claim. Effort small/medium.
3. Clean-copy test failures (Medium). Options: make tests seed their own runtime data; or declare prerequisites. Effort small.
4. Undefined dependency yields all_complete (Medium). Fix in validate: reject requires naming unknown gates. Effort small.
5. Evasions: long-flag rm, split-quote path (Medium). Options: broaden patterns; document that blocklist is best-effort. Effort small.
6. Memory write validation after the fact, and not for shell appends (Medium). Disclosed partly.
7. Licence missing though README says MIT (Medium). Add LICENSE. Effort tiny.
8. False block on commit message text (Low).
9. Recipes ship 20 of 25 declared checks (Medium, partly disclosed in code comments and commit 65eab77).
Minor: README counts stale (22 scripts, 18 suites, "Phase 8 Next"); path leak.

## E13 Math and method detail

Gate evaluator overall = 0.30 completeness + 0.25 quality + 0.20 consistency + 0.25 spec_adherence, rounded to one decimal (gate-evaluator.md). Worked: 6, 5, 8, 4 gives 5.65, rounds to 5.7, verdict warn, then run-evaluator blocks because 5.7 < 7.0. Verdict rules: pass if overall >= 7.0 and no high issue; warn if >= 5.0 and no high; else fail. run-evaluator: fail blocks; warn allowed unless score < threshold; unknown verdict blocks. Cycle check: DFS with recursion stack, O(gates + edges), but uses a yq call per gate. Current gate: first unpassed gate with all requires passed. Reflexion: delta_ratio = predicted / actual (sample 10/4 = 2.50, variance -60%). Drift: alignment < 5 drifted; < 7 warn.

## E14 Discrepancies

README "240 assertions / 18 suites" vs "All 20 suites pass" vs 20 files; README "22 scripts" vs 25; README "Phase 8 Next" vs ROADMAP "deferred"; README MIT vs no LICENSE; README "nine gates enforced" vs commit 65eab77; docs say memory validated "at keystroke time" vs PostToolUse exit 1; CLAUDE.md says test baseline 2026-09-04; ASSUMPTIONS A004 says drift promoted to warn-blocking in G3.5 findings but A004 says advisory (verify default remains advisory: Confirmed).

## E15 Production readiness detail

Traits: clean start run - Partly (install works; tests fail in 5 files; versions unpinned). Automatic checks block bad change - Partly (in installed projects; none for Meridian itself). Quality measured vs baseline - Partly (one experiment, three fixtures). Safe on failure - Partly (blocks logged; fails open without jq/yq). Human in the loop - Partly (human gates only). Prompts versioned - Yes (git, CHANGELOG). Logs - Yes (8 event types, dogfood labelling). Data and secrets - Partly (blocklist; no real secrets found). Placement: Works locally. Gap list: licence, release, own CI, authenticated verdicts and approvals, measured trial, runbook, cost capture, rollback (rollback-gate.sh exists for gate state only).

## E16 Review dispositions

No review pass has been run on this draft. Pending: plain-language check, accuracy review.

## E17 Completeness and backlog

Promised versus built: gate DAG engine, memory, telemetry, hooks, skills, evaluator and drift prompts, lifecycle tracker, recipes, portable verifier, rule generator, doctor, dogfood log: done and tested (clean-copy caveat). Cost tracking: stub. Phase 8 (benchmark tasks, benchmark guide, release packaging, post-release monitoring): planned only. Licence file: promised, absent. Test Writer and Security Auditor subagents: described as "session subagents" in ROADMAP; no files in the repo.
Backlog. Finish: LICENSE, release, benchmark. Fix: items 3, 4, 5, 8 above, stale counts. Improve: verdict authenticity, repeated experiment, own CI. Add: cost capture, working recipe checks. Next milestone: "clean-copy green": tests seed their own data, CI runs them, exit test is a fresh clone passing all 20 files.

## Diagram sources

meridian-parts: agent -> before-action check -> action -> after-action check -> notes; before-action -> gate engine; judge -> gate engine; gate engine -.-> commit check. meridian-learned-vs-rules: request -> coding agent (learned) -> block/allow (rule) <- judge's score (learned); pass mark 7.0 (rule). meridian-gate-journey: gate named -> earlier gates -> files exist -> checks pass -> human approval -> recorded. meridian-experiment: bars 5.5 and 2.5. Drawn with matplotlib.

## Revision log (v2 draft, 2026-10-25)

Previous draft archived as meridian.v1draft.md (7,798 words). Revised draft is about 7,260 words by plain wc -w. All ten reader-check fixes applied:
1. Opening now gives a plain summary and audience before the 5.5 vs 2.5 numbers, and points to the recruiter chapter and the results chapter.
2. Gate, hook, exit code and judge defined in plain words at first use.
3. Acronyms in SHORT (Full Name) form at first use (CI, DAG, YAML, JSON, JSONL, JHU).
4. Harness, scope, drift, happy path, fixture, fail open, honour-system defined at first use and in the glossary.
5. The Parts inventory paragraph replaced by a narrative following one agent action through the diagram.
6. Line, commit-count, hour and version-name figures removed (6,400/4,900 lines, 49 of 60 commits, 148.5/294/134 hours, burst commit counts, model version names). Test results (224 checks, 15 of 20 files) kept as they bear on honesty.
7. Duplicate formula in Methods removed; the worked weighted-score example stays.
8. AeroIntel, Hard Power Intelligence, VERA, Syntaris and Reflexion each explained in one line at first mention.
9. The 15-row attack table replaced with two prose paragraphs (what held, what got through); the 7-row, 4-column recruiter table replaced by prose plus a 3-row table.
10. Recruiter chapter linked from the top; "In short" lines kept per chapter but the tough-question and demo lists cut; the ten likely questions cut to five.
Also removed phrases: "the one idea that makes the project work", "core finding", "careful system design". Honest findings retained: five failing test suites on a clean copy, forgeable verdict, no LICENSE file, single-run confounded headline, honour-system gates. No new factual claims were added; the E-numbered evidence above is unchanged.

## Review follow-ups (2026-10-26)

1. meridian-gate-journey.png regenerated (matplotlib, same style). Box-5 text was clipped and the human step looked universal. Checked recipes/*/gates.yaml in the clone: type human_approval on 4 of 5 gates (cli-tool), 4 of 6 (fullstack-web), 4 of 6 (ml-research); the rest are automated. New picture shows the human step as a dashed side branch for human-approval gates only; automated gates go straight to recorded. Image alt text in meridian.md updated to match.
2. AeroIntel hooks: ROADMAP.md lines 551-552 (G5.2) confirm earlier installs on AeroIntel had non-functional hooks (installer never copied scripts/). The AeroIntel drift-judge result cannot be shown to have run with working hooks, and the AeroIntel repo is not available. Added one sentence in meridian.md (judge chapter) saying so. Word count after edit is under 8,000.
