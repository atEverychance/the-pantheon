# GitHub Operations

GitHub is mission control.

## Default workflow

1. Create or refine an issue
2. Decide if it survives the Signal Gate
3. Assign owner / agent
4. Create a branch tied to the issue
5. Land work in a PR
6. Run review + verification
7. Merge with a clear receipt trail

## Branch naming

- `feat/<issue>-short-name`
- `fix/<issue>-short-name`
- `chore/<issue>-short-name`

## PR rules

A PR should contain:
- what changed
- why it changed
- risk / blast radius
- how it was verified
- follow-ups if anything remains

## Review rules

Review should ask:
- does this solve the actual issue?
- is the scope clean?
- are tests enough?
- is the receipt believable?
- is there hidden risk?

## Merge rules

Do not merge because the agent sounds confident.
Merge because the artifact and verification hold up.

## Repo hygiene

- one issue per meaningful unit of work
- no invisible work
- no giant surprise PRs
- comments should explain decisions, not just status spam

## Tooling Bias

- Prefer trusted CLIs over MCPs whenever a stable CLI can do the job well.
- GitHub work should still prefer `gh` where available; use MCPs only when they are clearly the better tool.
- The same bias applies to adjacent ecosystems: Jira → `acli`, Azure DevOps → `az`.
