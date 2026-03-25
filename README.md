# The Pantheon

A portable operating system for running a small AI agent team with clear roles, routing rules, verification gates, GitHub workflow, and receipts.

This repo captures the useful part of the Pantheon: how to lead the team, how to route work, how to keep agents from hallucinating completion, and how to use GitHub as mission control.

## What's in here

- `AGENTS.md` — roster, routing table, escalation policy
- `docs/orchestration.md` — how the team operates
- `docs/signal-gate.md` — when work should be rejected, fast-pathed, or fully specified
- `docs/github-ops.md` — issues, branches, PRs, reviews, and merge policy
- `docs/receipts.md` — mandatory structured completion receipts
- `templates/receipt.schema.json` — copy/paste starting point for agent receipts
- `templates/agent-identity.md` — starter identity template for new agents
- `scripts/` — tiny shell helpers for pre-flight and post-flight verification

## Core idea

Agents are good at motion. They are not automatically good at truth.

So the Pantheon is built around four rules:

1. **Route work to the right specialist.**
2. **Reject weak ideas before coding starts.**
3. **Break approved work into small, testable chunks.**
4. **Never trust a "done" without a receipt and verification.**

## Team shape

- Research / signal
- Product / planning
- Architecture / strategy
- Coding
- Testing / verification
- GitHub / repo management
- Writing / publishing
- Synthesis

You can run this with OpenClaw, a custom orchestrator, or by hand.

## Public repo note

This repo is intentionally portable and scrubbed of private user details, internal paths, and environment-specific secrets.
