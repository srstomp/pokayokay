# Operating Modes

## SUPERVISED Mode (Default)

Human reviews after every task. Maximum control, slower pace.

**Checkpoint behavior:**
- Task complete → PAUSE
- Story complete → PAUSE
- Epic complete → PAUSE

**Use when**: Starting new projects, unfamiliar domains, critical code.

## SEMI-AUTO Mode

Human reviews at story/epic boundaries. Good balance.

**Checkpoint behavior:**
- Task complete → Log and continue
- Story complete → PAUSE
- Epic complete → PAUSE

**Use when**: Established patterns, routine implementation.

## AUTONOMOUS Mode

Human reviews at epic boundaries only. Maximum speed.

**Checkpoint behavior:**
- Task complete → Skip
- Story complete → Log and continue
- Epic complete → PAUSE

**Use when**: Well-defined specs, trusted patterns, time pressure.
