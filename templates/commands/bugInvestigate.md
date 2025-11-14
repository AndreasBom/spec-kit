---
description: Investigate a bug from Azure DevOps and create an investigation plan
scripts:
  sh: scripts/bash/create-new-feature.sh --json "{ARGS}"
  ps: scripts/powershell/create-new-feature.ps1 -Json "{ARGS}"
---

## User Input

```text
$ARGUMENTS
```

You **MAY** consider the user input for additional investigation context (if not empty).

## Azure DevOps Bug Investigation

This command is specifically designed for investigating bugs from Azure DevOps. It reads the bug data from `/speckit.startIssue` and performs a thorough investigation.

### 1. Check for Bug Data

**Check for saved work item data**:
- Look for `.specify/temp/current-issue.json` in the repository root
- **CRITICAL**: Verify that `type === "Bug"`. If not, show error:
  ```
  ❌ This command is only for Bug work items.
  Current work item type: {type}

  For User Stories/Features/Tasks, use /speckit.specify instead.
  For bugs, ensure you run /speckit.startIssue with a Bug work item first.
  ```
- If the file exists and type is "Bug", read:
  - Work item ID
  - Title
  - **prompt**: Main description (AI Prompt or Repro Steps)
  - **context**: Reproduction steps (if AI Prompt was used)
  - **additionalContext**: System Info
  - **rawFields**: All original fields (description, systemInfo, aiPrompt)

**If no work item data exists**:
- Show error: "Please run /speckit.startIssue with a Bug work item first"
- Exit

### 2. Create Bug Branch and Directory

Follow the same branching logic as `/speckit.specify`:

a. First, fetch all remote branches:
   ```bash
   git fetch --all --prune
   ```

b. Generate short-name from bug title (2-4 words, e.g., "fix-payment-timeout")

c. **Always use work item ID as branch number**:
   - Use the work item ID as the branch number
   - Run the script `{SCRIPT}` with: `--number {WORK_ITEM_ID} --short-name "{short-name}"`
   - Bash example: `{SCRIPT} --json --number 12345 --short-name "fix-payment-bug" "Investigate payment processing timeout"`
   - PowerShell example: `{SCRIPT} -Json -Number 12345 -ShortName "fix-payment-bug" "Investigate payment processing timeout"`
   - This creates a branch like: `12345-fix-payment-bug`

d. The script will create the directory `specs/{number}-{short-name}/` and check out the branch

### 3. Bug Investigation Process

Perform a thorough investigation using the following structured approach:

#### Phase 1: Understand the Bug
1. **Parse Bug Information**:
   - Extract reproduction steps from `prompt` or `context`
   - Extract system information from `additionalContext`
   - Identify key symptoms and error messages
   - Determine affected components/modules

2. **Reproduce the Bug** (if possible):
   - Follow the reproduction steps
   - Try to trigger the bug in the codebase
   - Document actual vs expected behavior
   - Capture any error messages or stack traces

#### Phase 2: Code Investigation
1. **Search for Related Code**:
   - Use Grep/Glob to find files related to the bug symptoms
   - Search for error messages mentioned in the bug
   - Identify functions/classes involved in the failure
   - Trace the execution path

2. **Analyze Code**:
   - Read relevant files to understand the logic
   - Look for obvious issues (null checks, edge cases, race conditions)
   - Check recent commits that might have introduced the bug (git log, git blame)
   - Identify dependencies and external integrations

3. **Identify Root Cause Candidates**:
   - List potential causes based on code analysis
   - Rank by likelihood (most likely → least likely)
   - For each candidate, explain why it could cause the observed symptoms

#### Phase 3: Create Investigation Report

Write the investigation report to `specs/{number}-{short-name}/bug-investigation.md`:

```markdown
# Bug Investigation: {Bug Title}

**Bug ID**: {work-item-id}
**Created**: {current date}
**Status**: Investigation Complete

## Bug Summary

{1-2 paragraph summary of the bug from Azure DevOps}

## Reproduction Steps

{Repro steps from Azure DevOps}

## System Information

{System Info from Azure DevOps}

## Investigation Findings

### Affected Components

- Component/module 1 - {file paths}
- Component/module 2 - {file paths}

### Code Analysis

{Detailed findings from code investigation}

**Files Analyzed**:
- `path/to/file1.ext:line` - {what was found}
- `path/to/file2.ext:line` - {what was found}

### Root Cause Analysis

**Primary Hypothesis**: {Most likely cause}
- **Evidence**: {Why this is most likely}
- **Location**: `file:line`
- **Impact**: {What this affects}

**Alternative Hypotheses** (if applicable):
1. {Second most likely cause} - {brief explanation}
2. {Third most likely cause} - {brief explanation}

## Recommended Fix

### Approach

{High-level description of the fix strategy}

### Implementation Steps

1. {Step 1}
2. {Step 2}
3. {Step 3}
...

### Files to Modify

- `path/to/file1.ext` - {what changes needed}
- `path/to/file2.ext` - {what changes needed}

### Testing Plan

**Unit Tests**:
- {Test case 1}
- {Test case 2}

**Integration Tests**:
- {Test case 1}
- {Test case 2}

**Manual Testing**:
- {Verification step 1}
- {Verification step 2}

### Risks and Considerations

- {Risk 1 and mitigation}
- {Risk 2 and mitigation}

## Next Steps

1. Review this investigation report
2. Run `/speckit.fix` to implement the recommended fix
3. Verify the fix resolves the bug
4. Update Azure DevOps work item #{work-item-id}
```

### 4. Create Investigation Checklist

Create a checklist at `specs/{number}-{short-name}/checklists/investigation.md`:

```markdown
# Bug Investigation Checklist: {Bug Title}

**Purpose**: Ensure thorough investigation before implementing fix
**Created**: {date}
**Bug**: [Link to bug-investigation.md]

## Investigation Completeness

- [ ] Reproduction steps documented and tested
- [ ] Root cause identified with evidence
- [ ] All affected components analyzed
- [ ] Alternative hypotheses considered
- [ ] Fix approach validated as feasible

## Fix Plan Quality

- [ ] Implementation steps are clear and specific
- [ ] All files to modify are identified
- [ ] Testing plan covers reproduction scenario
- [ ] Risks and side effects considered
- [ ] No implementation details overlooked

## Readiness for Fix

- [ ] Investigation report reviewed
- [ ] Fix approach approved
- [ ] Ready to run /speckit.fix

## Notes

{Any additional observations or concerns}
```

### 5. Report Completion

After creating the investigation report and checklist:

```markdown
✅ Bug investigation complete!

**Bug**: #{work-item-id} - {title}
**Branch**: {branch-name}
**Investigation Report**: specs/{number}-{short-name}/bug-investigation.md
**Checklist**: specs/{number}-{short-name}/checklists/investigation.md

## Findings Summary

**Root Cause**: {brief summary}
**Fix Complexity**: {Simple|Moderate|Complex}
**Estimated Impact**: {Low|Medium|High}

## Next Steps

1. Review the investigation report: `specs/{number}-{short-name}/bug-investigation.md`
2. Check the investigation checklist for completeness
3. Run `/speckit.fix` to implement the recommended fix

**Note**: The fix will be implemented in the current branch: `{branch-name}`
```

### 6. Cleanup

**IMPORTANT**: After completing the investigation, DELETE `.specify/temp/current-issue.json` to prevent accidental reuse.

## Guidelines

### Investigation Depth

- **For obvious bugs**: Quick investigation, focus on the fix
- **For complex bugs**: Deep analysis, consider multiple hypotheses
- **For intermittent bugs**: Include timing/concurrency analysis
- **For integration bugs**: Trace through system boundaries

### Code Search Strategy

1. Start with error messages (exact string match)
2. Search for function/class names mentioned in repro steps
3. Look for recent changes (`git log -p --since="1 month ago"`)
4. Check related test files for clues

### Root Cause Validation

Before finalizing the investigation:
- Can you explain HOW this cause produces the observed symptoms?
- Is there code evidence (not just speculation)?
- Would fixing this cause resolve the bug?

### When to Ask for Clarification

Only ask the user if:
- Reproduction steps are unclear or missing critical information
- Multiple equally-likely root causes exist and you need domain knowledge to choose
- The bug might be in external dependencies/infrastructure (not in codebase)
- You cannot reproduce or find relevant code

**Limit**: Maximum 2 clarification questions. Make informed guesses for everything else.
