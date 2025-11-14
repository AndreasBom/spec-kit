---
description: Implement the bug fix based on the investigation plan
---

## User Input

```text
$ARGUMENTS
```

You **MAY** consider the user input for additional implementation guidance (if not empty).

## Bug Fix Implementation

This command implements the bug fix based on the investigation plan created by `/speckit.bugInvestigate`.

### 1. Verify Investigation Exists

**Check for investigation report**:
- Determine the current feature directory:
  - If on a feature branch matching `{number}-{short-name}`, use that
  - Otherwise, look for the most recently modified directory in `specs/`
- Look for `specs/{number}-{short-name}/bug-investigation.md`
- If not found, show error:
  ```
  ❌ No bug investigation found!

  You must run /speckit.bugInvestigate first to analyze the bug and create a fix plan.

  If you already investigated the bug:
  1. Ensure you're on the correct branch
  2. Check that bug-investigation.md exists in specs/{number}-{short-name}/
  ```

### 2. Load Investigation Plan

**Read the investigation report**:
- Parse `bug-investigation.md` to extract:
  - Bug summary and reproduction steps
  - Root cause analysis
  - Recommended fix approach
  - Implementation steps
  - Files to modify
  - Testing plan

**Display fix summary**:
```markdown
🔧 Implementing Bug Fix

**Bug**: {title from investigation}
**Root Cause**: {primary hypothesis}
**Fix Approach**: {approach summary}

**Files to Modify**:
- {file 1}
- {file 2}
...

**Implementation Steps**:
1. {step 1}
2. {step 2}
...
```

### 3. Implement the Fix

Follow the implementation steps from the investigation report:

#### Step-by-step Implementation

For each implementation step:

1. **Read Affected Files**:
   - Use Read tool to examine files that need modification
   - Understand the current code structure
   - Locate the exact lines that need changes

2. **Make Code Changes**:
   - Use Edit tool to apply the fix
   - Follow the recommended approach from the investigation
   - Maintain code style and conventions
   - Add comments explaining the fix (reference bug ID)

3. **Verify Changes**:
   - Review each change to ensure it addresses the root cause
   - Check for any side effects or edge cases
   - Ensure no new issues are introduced

#### Code Quality Checks

After implementing changes:
- **Null safety**: Ensure null/undefined checks are in place
- **Edge cases**: Handle boundary conditions
- **Error handling**: Add appropriate error handling
- **Logging**: Add debugging logs if helpful
- **Documentation**: Update comments if behavior changed

### 4. Testing

Execute the testing plan from the investigation report:

#### Run Automated Tests

1. **Run existing tests**:
   - Execute relevant unit tests: `{test command from project}`
   - Execute integration tests if applicable
   - Document test results

2. **Add new tests** (if needed):
   - Create test case that reproduces the original bug
   - Verify the test fails without the fix
   - Verify the test passes with the fix

#### Manual Testing

Follow manual testing steps from the investigation:
- Execute reproduction steps to verify bug is fixed
- Test edge cases identified during investigation
- Verify no regressions in related functionality

**Document test results**:
```markdown
## Test Results

**Unit Tests**: {Pass/Fail} - {details}
**Integration Tests**: {Pass/Fail} - {details}
**Manual Testing**: {Pass/Fail} - {details}

**Bug Reproduction**: {Verified Fixed/Still Fails}
```

### 5. Create Fix Report

Update the investigation report with implementation details. Add a new section:

```markdown
## Implementation

**Implemented**: {current date}
**Status**: {Fixed/Partial Fix/Blocked}

### Changes Made

**Files Modified**:
- `path/to/file1.ext:lines` - {description of changes}
- `path/to/file2.ext:lines` - {description of changes}

### Code Changes Summary

{Brief description of what was changed and why}

### Test Results

{Paste test results from above}

### Verification

- [x] Bug reproduction steps no longer trigger the issue
- [x] All existing tests pass
- [x] New tests added to prevent regression
- [x] Code reviewed for side effects
- [x] Edge cases handled

### Notes

{Any important observations during implementation}
```

### 6. Update Fix Checklist

Create or update `specs/{number}-{short-name}/checklists/fix.md`:

```markdown
# Bug Fix Checklist: {Bug Title}

**Purpose**: Verify fix quality before committing
**Created**: {date}
**Bug**: [Link to bug-investigation.md]

## Implementation Quality

- [ ] All identified files have been modified
- [ ] Root cause has been addressed (not just symptoms)
- [ ] Code follows project conventions
- [ ] Comments explain the fix (with bug ID reference)
- [ ] No obvious side effects introduced

## Testing Completeness

- [ ] Bug reproduction steps no longer trigger the issue
- [ ] All existing tests pass
- [ ] New regression test added
- [ ] Manual testing completed
- [ ] Edge cases verified

## Code Review

- [ ] Changes reviewed for correctness
- [ ] Null/undefined checks in place
- [ ] Error handling appropriate
- [ ] Performance impact considered
- [ ] Security implications reviewed

## Documentation

- [ ] Code comments updated
- [ ] Fix report completed in bug-investigation.md
- [ ] Commit message prepared

## Ready for Commit

- [ ] All checklist items complete
- [ ] Ready to commit changes

## Notes

{Any additional observations or concerns}
```

### 7. Prepare for Commit

After successful implementation and testing:

**Create commit message**:
```markdown
Ready to commit! Here's the suggested commit message:

---
fix: {brief description of what was fixed}

Fixes Azure DevOps Bug #{work-item-id}

**Root Cause**: {one-line summary}

**Changes**:
- {change 1}
- {change 2}

**Testing**: {brief test summary}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
---

Run this command to commit:
git add {list of modified files}
git commit -m "{commit message above}"

Or ask me to create the commit for you.
```

### 8. Report Completion

```markdown
✅ Bug fix implemented successfully!

**Bug**: #{work-item-id} - {title}
**Branch**: {branch-name}
**Files Modified**: {count} files
**Tests**: {Pass/Fail status}

## Summary

{1-2 sentence summary of the fix}

## Next Steps

1. Review the changes in the modified files
2. Run additional testing if needed
3. Commit the changes (I can do this for you)
4. Create a pull request
5. Update Azure DevOps work item #{work-item-id} to "Resolved"

**Branch ready for**: Commit → PR → Merge
```

## Guidelines

### Implementation Best Practices

1. **Follow the plan**: Stick to the investigation's recommended approach
2. **Minimal changes**: Only modify what's necessary to fix the bug
3. **Preserve behavior**: Don't refactor unless necessary for the fix
4. **Test thoroughly**: Verify the fix doesn't break anything else

### When to Deviate from the Plan

Only deviate from the investigation plan if:
- You discover the root cause was misidentified (document why)
- A simpler fix is available (explain the alternative)
- The recommended approach has unforeseen complications (describe issue)

**Always document deviations** in the fix report.

### Error Handling

If implementation fails:
- **Cannot locate code**: Investigation may have wrong file paths
- **Tests fail**: Fix may have side effects, needs revision
- **Cannot reproduce fix**: Root cause may be incorrect

**In all cases**: Update the investigation report with findings and ask user for guidance.

### Commit Strategy

- **Single logical commit**: All changes for this bug in one commit
- **Reference bug ID**: Include #{work-item-id} in commit message
- **Descriptive message**: Explain what, why, and how

### Quality Gates

Before marking as complete:
1. ✅ Bug is fixed (verified by reproduction steps)
2. ✅ No tests are broken
3. ✅ Code quality maintained
4. ✅ Fix is documented

**If any gate fails**: Report issue and wait for user input.
