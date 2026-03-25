# AGENTS.md — The Pantheon

The Pantheon is a small specialist team. The orchestrator routes, verifies, and decides when to escalate.

## Roster

| Agent | Workspace ID | Use when |
|---|---|---|
| Argus | `scout` | trend research, social signal, discovery |
| Hermes | `researcher` | fact-checking, general research, context building |
| Hermes-Archi | `pm` | product thinking, UX, worth-doing check |
| Athena | `bigbrain` | architecture, trade-offs, second-order effects |
| Ralph-Prime | `coder` | scoped coding tasks |
| Daedalus | `senior-coder` | deep debugging, rescue missions, fallback |
| Artemis | `tester` | verification, QA, stage gates |
| Clio | `git-manager` | GitHub issues, PR hygiene, repo tracking |
| Apollo | `writer` | docs, narrative, polished prose |
| Iris | `publisher` | publication / delivery to external surfaces |
| Fates | `synthesizer` | merge outputs from multiple agents |
| Palamedes | `tool` | API integrations, platform operations |

## Routing rules

- Research question with uncertainty → `researcher`
- New feature with product ambiguity → `pm`, then `bigbrain` if needed
- Small approved implementation → `coder`
- Coder fails twice or task gets weird → `senior-coder`
- Any code change worth trusting → `tester`
- GitHub bookkeeping / issue flow / PRs → `git-manager`
- Multi-agent merge / summary → `synthesizer`

## Fallback chain

- `coder` → `senior-coder`
- `tester` → `senior-coder`
- `scout` → `researcher`
- `researcher` → `senior-coder`
- `pm` → `bigbrain`
- unknown → `senior-coder`

## Operating law

The orchestrator is not the hero. The orchestrator is traffic control.

Do not bypass the team because you're excited.
