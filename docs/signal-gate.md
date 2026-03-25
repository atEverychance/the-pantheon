# Signal Gate

Most work should die before it becomes a ticket.

## Tier 1 — Fast path

Use for:
- bug fixes
- small features
- config changes
- obvious scripts

Flow:
1. Scout gives quick ROI / relevance read
2. PM gives worth-doing check
3. Architect gives trap check
4. Planner breaks into atomic tasks
5. Tester verifies plan coverage
6. Coder executes
7. Tester verifies implementation

## Tier 2 — Full ceremony

Use for:
- new products
- architecture changes
- multi-component work
- anything expensive to get wrong

Flow:
1. research / signal
2. product spec
3. architecture review
4. atomic plan
5. test-plan gate
6. implementation
7. verification
8. PR + merge

## Decision rules

- weak ROI → reject
- clear value, low blast radius → Tier 1
- high complexity or strategic consequence → Tier 2

The point is not paperwork. The point is forcing real thought before execution.
