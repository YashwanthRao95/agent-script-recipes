# ContextualProductAdvisor

Demonstrates the **intercept → collect → hand off** pattern using two topics:

1. **`context_gate`** (start topic) — never answers a product question; its only job is to collect company size and immediately transition away.
2. **`product_advisor`** — answers every question for the rest of the session, always using company size as context.

The hand-off is **instant**: `transition to @topic.product_advisor` is attached directly to the `collect_employee_count` action, so the advisor topic receives control in the same turn the number is stored — no extra round-trip, no intermediate response.

## What this recipe shows

| Concept | Where |
|---|---|
| Pre-flight context gate | `context_gate` start topic intercepts the first message |
| Immediate topic transition | `transition to @topic.product_advisor` on the collect action |
| Shared variables across topics | `number_of_employees` declared at the top level, visible in both topics |
| One-way hand-off (no return) | `product_advisor` has no transition back — company size is never asked again |
| Conversation history recall | `product_advisor` instructions tell the LLM to find and answer the original question |

## Conversation flow

```
User  → "What pricing plan would suit us best?"

Agent → [context_gate active]
         "Before I answer, could you quickly tell me how many employees
          your company has? This helps me give you the most relevant
          recommendation."

User  → "Around 120."

Agent → [collect_employee_count fires: stores 120, transitions to product_advisor]
        [product_advisor now active — answers immediately in the same turn]
         "For a 120-person team you're right in mid-market territory.
          I'd recommend our Growth plan: it covers the admin controls and
          integrations a team your size typically needs, and…"

User  → "Does it integrate with Slack?"

Agent → [product_advisor, number_of_employees = 120 — no re-prompting]
         "Yes — for a team your size the Slack integration is especially
          valuable because…"
```

## Key mechanics

### Instant transition on collect

```yaml
collect_employee_count: @utils.setVariables
   with number_of_employees=...
   transition to @topic.product_advisor
```

`transition to` is a suffix on the action, not a separate step. The variable is written first, then control passes to `product_advisor` — all within the same turn.

### Variables shared across topics

```yaml
variables:
   number_of_employees: mutable number = 0
```

Top-level variables are visible to every topic. `product_advisor` reads `number_of_employees` the moment it receives control.

### One-way gate

`context_gate` only transitions **out**, never back in. Once the advisor topic is active it stays active, so company size is asked exactly once per session.

### LLM recall of the pending question

`product_advisor` instructions say:
> "Look back at the conversation, find the user's original unanswered question, and answer it now."

The full chat transcript is available to the LLM, so no extra variable is needed to remember what was asked.

## Adapting to your use case

| What to change | Where |
|---|---|
| Collected field | Rename `number_of_employees`; change type if needed |
| Collection prompt | Edit `context_gate` instructions |
| Sizing tiers / answer guidance | Edit `product_advisor` instructions |
| Agent persona | Edit `system.instructions` |
| Welcome message | Edit `system.messages.welcome` |

## Deploy

```bash
sf project deploy start \
  -d force-app/main/01_languageEssentials/contextualProductAdvisor
```
