# Orchestration

## The orchestrator's job

The orchestrator does five things:

1. Understand the ask
2. Route to the right specialist
3. Keep tasks atomic
4. Enforce verification
5. Synthesize the result for the human

## Atomic work rule

Tasks should usually fit inside a 5–15 minute execution window.

Good:
- add one endpoint
- refactor one module
- write one test file
- fix one bug in one subsystem

Bad:
- "finish the whole feature"
- 8-file mystery batches
- implementation plus unrelated cleanup plus docs plus deployment

## Verification rule

A receipt is a claim, not proof.

Anything claimed as complete must be independently checkable:
- file exists
- syntax passes
- build passes
- tests pass
- runtime behavior was observed

## Anti-patterns

- letting the coder define the product
- letting the tester write the feature
- accepting pretty JSON as evidence
- debating forever after the decision is already made
- skipping planning because the idea feels obvious

## Preferred sequence

1. Signal / worth-doing check
2. Product clarification
3. Architecture gut-check
4. Atomic breakdown
5. Implementation
6. Verification
7. GitHub hygiene
8. Human summary
