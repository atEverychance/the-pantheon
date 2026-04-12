# The Pantheon

> *Sing, O Muse, of the ordered mind — of agents swift and agents deep,*
> *of routing laws that hold the line between bright motion and blind sleep.*

The Pantheon is a portable operating system for a small AI agent team. It holds the shape of the team, the law of routing, the gates of verification, and the receipts that prove a thing was truly done.

This is not a framework of excitement. It is a framework of truth.

Agents are tireless. They are not automatically honest. Left without law, they will move with great confidence toward wrong conclusions, declare victory over incomplete work, and mistake the appearance of completion for the thing itself.

The Pantheon was built because of this. It is the structure that holds agents to account.

---

## The Scrolls Within

| Scroll | What It Holds |
|---|---|
| `AGENTS.md` | The divine roster, routing table, and escalation rites |
| `docs/orchestration.md` | The laws of how the team moves and decides |
| `docs/signal-gate.md` | When work shall be rejected, fast-pathed, or fully formed before it may proceed |
| `docs/github-ops.md` | Issues, branches, pull requests, reviews, and the rites of the merge |
| `docs/media-craft.md` | The laws of tutorial video and narration quality for media specialists |
| `docs/receipts.md` | The mandatory structured completion receipt — proof that something was truly done |
| `templates/receipt.schema.json` | The schema from which all receipts are cast |
| `templates/agent-identity.md` | The founding scroll of a new agent's identity |
| `agents/` | Filled founding scrolls for named specialists currently in the assembly |
| `scripts/` | Shell incantations for pre-flight and post-flight verification |
| `scripts/pre-flight-check.sh` | Portable pre-spawn gating, fallback selection, and circuit-awareness |
| `scripts/verify-receipt.sh` | Portable receipt validation and artifact checks |
| `scripts/process-receipt.sh` | Portable post-flight verification, compliance tracking, and circuit updates |
| `scripts/circuit-breaker.sh` | Failure tracking, escalation thresholds, and probation handling |

---

## The Core Law

Agents are good at motion. They are not automatically good at truth.

So the Pantheon is built upon four immutable laws:

**I. Route work to the right specialist.**
No god is asked to do another's labour. The scout does not forge. The smith does not prophesy.

**Tooling bias:** when a trustworthy CLI exists, prefer it over an MCP or custom integration. Use the direct, stable path first; reach for MCPs when they are actually the better tool.

**II. Reject weak ideas before the forge is lit.**
To begin building without a worthy plan is to waste the fire of Hephaestus on straw.

**III. Break approved work into small, testable pieces.**
Even Daedalus built his wings one feather at a time.

**IV. Never trust a "done" without a receipt and verification.**
A claim is not proof. A receipt is not proof. Only independent verification is proof.

---

## The Shape of the Assembly

The team holds nine sacred functions. Each function has its deity. No function may be collapsed without cost.

- **Signal & Research** — the eyes and ears of the Pantheon
- **Product & Planning** — the forethought that asks *should this be built at all?*
- **Architecture & Strategy** — the mind that sees second-order effects
- **Coding** — the forge
- **Testing & Verification** — the gate that nothing false may pass
- **Repository & Workflow** — the keeper of the record
- **Writing & Publishing** — the voice that makes meaning legible
- **Media Craft** — the hand that teaches through picture, pace, timing, and voice
- **Synthesis** — the loom that weaves many threads into one cloth

You may run the Pantheon with OpenClaw, a custom orchestrator, or by hand.

---

## Portable Guardrails

The repo now ships the core orchestration guardrails directly:

```bash
scripts/pre-flight-check.sh <agent> "task context"
scripts/process-receipt.sh <agent> '<receipt-json>'
```

Useful environment overrides:

- `PANTHEON_SCRIPT_DIR` — alternate script directory
- `PANTHEON_STATE_FILE` — custom circuit-breaker state location
- `PANTHEON_LOG_FILE` — custom process log location
- `PANTHEON_COMPLIANCE_FILE` — custom compliance stats location
- `PANTHEON_POST_HOOK` — local executable to capture observations or memory after receipt processing
- `PANTHEON_FALLBACK_MAP` — optional `agent:fallback` mapping file
- `PANTHEON_CIRCUIT_THRESHOLD` — failures before circuit opens
- `PANTHEON_PROBATION_AFTER_FALLBACKS` — fallback successes needed before probation

This keeps the repo portable while still allowing local deployments to add their own house wiring.

---

## A Note on Portability

This repository has been scrubbed of private paths, user-specific secrets, and environment details. It belongs to no single mountain. Carry it where you will.