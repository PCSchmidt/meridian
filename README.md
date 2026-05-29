# Meridian

**A next-generation agent harness framework for AI coding assistants**

![Status](https://img.shields.io/badge/status-in%20development-green)
![Version](https://img.shields.io/badge/version-0.0.1--alpha-blue)
![Progress](https://img.shields.io/badge/phase%201-43%25-orange)

---

## What Is Meridian?

Long-running AI agents fail predictably: hallucinated completion, context loss, generous self-evaluation. **Meridian fixes each mechanically** — enforced gates, validated memory, a separate Evaluator subagent that cannot praise its own work, and engineer-legible telemetry.

Meridian is an agent harness framework that sits between you and the AI model, providing:

- **Enforced gates** the model cannot hallucinate past
- **Schema-validated memory** that persists across sessions
- **Generator-Evaluator separation** to prevent self-grading
- **Engineer-legible observability** via `/health report` and structured telemetry
- **Composable gate DAG** configured in YAML, not hardcoded
- **Multi-platform support** (Claude Code, Cursor, Windsurf, and advisory tier)

---

## Status: Phase 1 - Foundation (In Progress)

**Current Phase:** Phase 1 - Foundation (3/7 gates complete - 43%)  
**Next Milestone:** G1.4 - Telemetry System (JSONL)  
**Timeline:** 11 weeks to v0.1.0 (target: 2026-09-10)

**Progress:**
- ✅ Phase 0: Planning & Validation (6h actual vs 8h estimated - 1.33x faster)
- 🔄 Phase 1: Foundation (24h spent / 40h estimated - 60% complete)
  - ✅ G1.1: Composable Gate DAG Engine (6h - 1.33x faster)
  - ✅ G1.2: Schema-Validated Memory System (10h - 1.0x on target)
  - ✅ G1.3: Basic Hook Infrastructure (8h - 1.0x on target)
  - ⏳ G1.4-G1.7: In progress

See [ROADMAP.md](ROADMAP.md) for detailed progress tracking and [MERIDIAN_ARCHITECTURE_DECISIONS.md](MERIDIAN_ARCHITECTURE_DECISIONS.md) for the complete architectural blueprint.

---

## Key Differentiators Over Existing Frameworks

1. **Engineer-legible observability** - You can see what's happening (gate pass rates, token costs, calibration trends)
2. **Composable gate DAG** - YAML-configured, fully customizable workflow
3. **Schema-validated memory** - Integrity-guaranteed, queryable JSONL storage
4. **Generator-Evaluator separation** - Independent evaluation prevents self-grading hallucinations
5. **ASSUMPTIONS.md governance** - Documents every harness assumption, evolves as models improve
6. **Pattern-based recipes** - Stack-flexible (`fullstack-web`, `cli-tool`, `ml-research`)

---

## Planned Features (v0.1.0)

### Core Architecture
- [x] Architectural design complete
- [x] Composable gate DAG engine
- [x] Schema-validated memory system (JSONL)
- [x] Basic hook infrastructure (PreToolUse, PostToolUse)
- [ ] Multi-tier platform support (Claude Code, Cursor/Windsurf, Advisory)
- [ ] Generator-Evaluator feedback loop

### Observability Layer
- [x] JSONL telemetry (`.meridian/telemetry.jsonl`) - basic implementation
- [x] Hook execution logging
- [ ] `/health report` - gate rates, costs, trends
- [ ] `/status` - project completion tracking
- [ ] Real-time cost tracking
- [ ] Enhanced telemetry schema

### Recipes
- [ ] `fullstack-web` (reference: Next.js + FastAPI + Supabase)
- [ ] `cli-tool` (reference: Python + Click)
- [ ] `ml-research` (reference: PyTorch + FastAPI) - **unique to Meridian**

### Documentation
- [ ] Complete installation guide
- [ ] Windows support (Git Bash/WSL2)
- [ ] Recipe adaptation guide
- [ ] Governance documentation

---

## Design Principles

From [MERIDIAN_ARCHITECTURE_DECISIONS.md](MERIDIAN_ARCHITECTURE_DECISIONS.md):

1. **Mechanical enforcement** - Nothing the model can hallucinate past
2. **Self-improving** - Mistakes become permanent fixes, not retries
3. **Context-efficient** - Load only what's needed when it's needed
4. **Observability-complete** - Engineer-legible, not just LLM-readable
5. **Model-agnostic** - Assumptions documented and pruned as models improve

---

## Repository Structure (Planned)

```
meridian/
  .meridian/              # Framework configuration
    gates.yaml            # Composable gate DAG
    memory-schema.json    # Memory validation schema
    
  .claude/                # Claude Code integration
    hooks/                # 18 bash hooks
    skills/               # 12+ slash-command skills
    agents/               # Subagent definitions
    
  recipes/                # Stack-specific patterns
    fullstack-web/
    cli-tool/
    ml-research/
    
  docs/                   # Documentation
  bench/                  # Benchmark suite
  
  README.md
  PHILOSOPHY.md           # Design principles
  ASSUMPTIONS.md          # Harness assumptions governance
```

---

## Installation (Coming Soon)

```bash
# Clone the framework
git clone https://github.com/PCSchmidt/meridian

# Install to your project
cd your-project
bash ../meridian/install.sh --recipe fullstack-web

# Verify installation
./meridian-doctor.sh
```

---

## Documentation

- [Architecture Decisions](MERIDIAN_ARCHITECTURE_DECISIONS.md) - Complete design blueprint
- [Planning Notes](scratch-notes.txt) - Research and analysis
- Philosophy (coming soon)
- Quick Start (coming soon)
- Windows Installation Guide (coming soon)

---

## Roadmap

### Phase 1 (Weeks 1-2): Foundation
- Gate DAG engine
- Memory system with schema validation
- Basic hook infrastructure

### Phase 2 (Weeks 3-4): Observability
- Telemetry system
- `/health report` and `/status` commands
- Cost tracking

### Phase 3 (Weeks 5-7): Core Features
- 18 bash hooks
- 12+ skills
- Memory management commands

### Phase 4 (Weeks 7-8): Multi-Platform
- Tier 1 (Claude Code) - full enforcement
- Tier 2 (Cursor/Windsurf) - partial enforcement
- Tier 3 (Advisory) - guidance only

### Phase 5 (Weeks 8-9): Recipes
- 3 pattern-based recipes with reference implementations

### Phase 6 (Weeks 9-10): Subagents
- Generator-Evaluator validation
- Gate Evaluator, Spec Reviewer, Test Writer, Security Auditor

### Phase 7 (Weeks 10-11): Documentation
- Complete docs for all components

### Phase 8 (Weeks 11-12): Validation
- Dogfooding with real projects
- Refinement based on usage

---

## Contributing

Meridian is currently in the planning/implementation phase. Contributions will be welcome after v0.1.0 release.

---

## License

MIT License - See LICENSE file (coming soon)

---

## Author

**Paul Christopher Schmidt**  
- GitHub: [@PCSchmidt](https://github.com/PCSchmidt)
- Email: p.christopher.schmidt@gmail.com

---

## Acknowledgments

Built on research and patterns from:
- Original Syntaris framework (brianonieal)
- Anthropic engineering research on agent harnesses
- Martin Fowler's "Harness engineering for coding agent users"
- Reflexion paper (Shinn et al., NeurIPS 2023)

---

**Status:** Phase 1 in progress. Gate DAG, memory system, and hook infrastructure complete (43%). Target: v0.1.0 by 2026-09-10.
