# Atomic Development Manifesto

## Core Principle
EVERYTHING is broken into stages so small they cannot fail. One surgical change, then validate, then proceed.

## Commitment
- **NO BIG LEAPS**: Maximum 3-5 focused commits per stage
- **NO EXCEPTIONS**: "This is small change" is forbidden thinking
- **NO COMPROMISES**: Quality gates pass 100% or stage rejected
- **NO AMBIGUITIES**: Every commit addresses exactly one concern

## Stage Definition
1. **SINGLE RESPONSIBILITY**: One working feature increment
2. **TESTABLE ISOLATION**: Passes tests independently
3. **REVERSIBLE**: Can be rolled back without dependencies
4. **DOCUMENTABLE**: Clear, bounded scope

## Quality Gates (Required)
### Pre-Commit
□ Code linting passes (shellcheck, yamllint, black, flake8)
□ All existing tests pass
□ No security vulnerabilities introduced

### Post-Commit
□ New functionality works as designed
□ Integration tests pass
□ Memory bank updated
□ Changelog indexed to commit

### Pre-Merge
□ Manual testing confirms behavior
□ Documentation accurate
□ No performance regressions
□ Security audit clean

## Danger Signals (Immediate Halt)
🚨 "Just one more small fix" - SPLIT INTO NEW STAGE
🚨 "This will be quick" - REJECT, MEASURE FIRST
🚨 "Let me bundle these" - NO, ATOMIC ONLY
🚨 Pipeline fails - ROLLBACK, INVESTIGATE ROOT CAUSE
🚨 Complex merge - STAGE WAS TOO LARGE, SPLIT RETROSPECTIVELY

## Implementation Rules
- **File Changes**: < 500 lines per commit
- **Logical Changes**: One concept per commit
- **Test Coverage**: Every line exercised
- **Documentation**: Updated after every functional change

## Success Metrics
- ✅ **Zero Rework**: No "fix" commits for previous features
- ✅ **Zero Mysteries**: Every failure leads directly to root cause
- ✅ **Zero Surprises**: Progress is steady and predictable
- ✅ **Zero Debt**: Every stage complete, no loose ends

## Partnership Protocol
Human: Reviews all commits for scope adherence
AI: Suggests splits when stages feel large
Both: Celebrate each successful atomic stage

## Violation Response
Any violation = immediate rollback + stage split.
No warnings, no second chances. Atomic development is all-or-nothing.

---
Last Updated: Stage 0 (Project Initialization)
