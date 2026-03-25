# Receipts

Every meaningful agent run should end with a receipt.

## Why

Without receipts, teams drift into theater:
- "done"
- "works on my end"
- "integrated successfully"

None of that is evidence.

## Required shape

```json
{
  "receipt": {
    "agent": "coder",
    "task": "add healthcheck endpoint",
    "status": "completed",
    "outputs": ["src/routes/health.ts", "tests/health.test.ts"],
    "claims": [
      { "type": "file_modified", "target": "src/routes/health.ts" },
      { "type": "build_passes", "target": "npm test" }
    ],
    "evidence": {
      "commands_run": ["npm test"],
      "artifacts": ["tests/health.test.ts"],
      "notes": ["endpoint returns 200 with version payload"]
    },
    "confidence": 0.91,
    "uncertainties": [],
    "observations": []
  }
}
```

## Rules

- `completed` must name concrete outputs or claims
- vague claims are invalid
- confidence is advisory, not proof
- verifier outcome beats self-report

## Receipt review questions

- Can I verify each claim?
- Are the targets exact?
- Is there runtime evidence where runtime was claimed?
- Is anything suspiciously broad?
