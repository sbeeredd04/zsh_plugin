# Pull Request

## Description
<!-- Provide a detailed description of your changes -->

## Type of Change
<!-- Mark the relevant option with an 'x' -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code style/formatting
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Test addition/modification
- [ ] Build/CI configuration

## Related Issues
<!-- Link to related issues -->
Fixes #(issue number)
Relates to #(issue number)

## Changes Made
<!-- List the specific changes made in this PR -->

### Core Changes
- 
- 
- 

### Additional Changes
- 
- 

## Implementation Details

### Architecture/Design Decisions
<!-- Explain key architectural or design decisions -->

### Performance Considerations
<!-- Describe any performance implications -->

### Memory Management
<!-- If applicable, describe memory allocation/deallocation approach -->

## Testing

### Test Coverage
<!-- Describe the tests you've added or modified -->

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

### Test Results
```bash
# Include test output
```

### Testing Environment
- **OS**: 
- **Shell**: 
- **Build Type**: Debug/Release

## Code Quality

### Static Analysis
- [ ] No new warnings from `cppcheck`
- [ ] No new warnings from `clang-tidy`
- [ ] Code follows project style guidelines
- [ ] No memory leaks (verified with valgrind on Linux)

### Documentation
- [ ] Code comments added/updated
- [ ] README.md updated (if needed)
- [ ] API documentation updated (if needed)
- [ ] System design docs updated (if needed)

## Backward Compatibility
<!-- Does this change break backward compatibility? -->

- [ ] This change is backward compatible
- [ ] This change requires migration/upgrade steps (documented below)

### Migration Steps (if applicable)
```bash
# Steps users need to take to migrate
```

## Screenshots/Demos
<!-- If applicable, add screenshots or demo output -->

```bash
# Terminal output or demo commands
```

## Performance Impact

### Benchmarks (if applicable)
<!-- Include before/after performance metrics -->

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Startup time | | | |
| Ghost text latency | | | |
| Memory usage | | | |

## Checklist

### Code Quality
- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing tests pass locally with my changes

### Build & CI
- [ ] The code compiles without errors (`make clean && make`)
- [ ] Debug build works (`make debug`)
- [ ] All tests pass (`make test`)
- [ ] CI checks will pass (GitHub Actions)

### Git Hygiene
- [ ] I have rebased on the latest `main`/`dev` branch
- [ ] My commits have descriptive messages
- [ ] I have squashed unnecessary commits
- [ ] No merge commits in the history

### Security
- [ ] I have checked for potential security vulnerabilities
- [ ] No sensitive information (keys, passwords) in the code
- [ ] Input validation added where necessary
- [ ] No buffer overflow possibilities

## Additional Notes
<!-- Any additional information that reviewers should know -->

## Reviewer Notes
<!-- Specific areas you'd like reviewers to focus on -->

## Post-Merge Tasks
<!-- List any tasks that need to be done after merging -->

- [ ] 
- [ ] 

---

**By submitting this PR, I confirm that:**
- My contribution is made under the same license as this project
- I have the right to submit this code
- I understand and agree to the project's contribution guidelines
