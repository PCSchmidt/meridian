# Memory Management Skill

**Skill:** memory  
**Trigger:** `/memory`  
**Purpose:** Manage and validate Meridian's three-tier memory system

---

## Commands

### `/memory doctor`

Validates all memory files, checks for corruption, deduplicates patterns, and reports health.

**What it does:**
1. Validates semantic.json against schema
2. Validates episodic.jsonl (line-by-line)
3. Validates corrections.jsonl (line-by-line)
4. Deduplicates semantic patterns by hash
5. Checks for corruption or malformed entries
6. Reports memory health statistics

**Example output:**
```
Memory Health Check

✓ Semantic memory: 42 patterns, 3 duplicates removed, schema valid
✓ Episodic memory: 127 events, all valid
✓ Corrections memory: 16 gates, schema valid, avg calibration 0.73x
! Warning: semantic pattern PAT-001 has confidence:LOW (only 1 validation)

Memory health: GOOD
```

---

### `/memory show <type>`

Displays human-readable view of memory (converts JSONL to markdown).

**Arguments:**
- `semantic` - Show validated patterns
- `episodic` - Show recent session events
- `corrections` - Show reflexion entries with calibration data

**Example:**
```
/memory show corrections

Recent Corrections (newest first):

Gate v0.3: predicted 4h, actual 6h (0.67x)
  Root cause: Underestimated frontend complexity
  Action: Apply 1.5x to similar tasks
  
Gate v0.2: predicted 3h, actual 3.2h (0.94x)
  Root cause: Accurate estimate, minor scope creep
  Action: Maintain current estimation approach
```

---

### `/memory stats`

Shows memory statistics and trends.

**What it reports:**
- Total patterns (semantic)
- Confidence distribution (LOW/MEDIUM/HIGH)
- Total events (episodic)
- Total corrections
- Operator multiplier trend
- Estimate accuracy over time

---

### `/memory prune`

Trims episodic memory to last N sessions to prevent unbounded growth.

**Default:** Keep last 50 sessions

---

### `/memory export`

Exports structured memory summary for handoff or backup.

---

## Implementation

When user invokes `/memory doctor`:

1. Run validation scripts:
   ```bash
   ./scripts/validate-memory.sh semantic .meridian/memory/semantic.json
   ./scripts/validate-memory.sh episodic .meridian/memory/episodic.jsonl
   ./scripts/validate-memory.sh corrections .meridian/memory/corrections.jsonl
   ```

2. Check for warnings:
   - Patterns with confidence:LOW (validated_count < 3)
   - Episodic file > 200 events (suggest prune)
   - Missing fields or malformed entries

3. Report summary with clear status

---

## Memory File Locations

- **Project-local:**
  - `.meridian/memory/semantic.json` - Project-specific patterns
  - `.meridian/memory/episodic.jsonl` - Session events
  - `.meridian/memory/corrections.jsonl` - Reflexion entries

- **Global:**
  - `~/.meridian/global/semantic_global.json` - Cross-project patterns
  - `~/.meridian/global/stats.json` - Operator multiplier, calibration

---

## Usage Notes

- Memory files are JSONL internally (engineer-queryable)
- `/memory show` renders human-readable views (no need to read raw JSONL)
- Schema validation runs automatically on writes via PostToolUse hook
- `/memory doctor` is for manual health checks and recovery

---

## Error Recovery

If corruption detected:

1. `/memory doctor` will report the specific issue
2. Backup corrupt file: `cp file.json file.json.corrupt`
3. Fix manually or regenerate from git history
4. Re-run `/memory doctor` to verify

---

**Status:** Basic implementation complete (Gate 1.2)  
**Enhanced features:** Coming in Phase 2 (visualization, advanced queries)
