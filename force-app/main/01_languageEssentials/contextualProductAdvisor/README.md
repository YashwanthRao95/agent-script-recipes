# ContextualProductAdvisor

Combines **pre-flight context collection** with **dynamic topic routing**:

1. **`context_gate`** (start topic) — collects company size once, then hands off to the dispatcher.
2. **`dispatcher`** (hub) — routes every message to the right specialist topic based on intent.
3. **`product_advisor`**, **`escalation`**, **`off_topic`** — specialist topics that answer and return to the dispatcher.

```
start_agent context_gate  →  collects number_of_employees
       ↓ (instant transition on collect)
 topic dispatcher          →  routes each message by intent
       ↓                ↑  (all specialists return here)
 ┌──────────────┬────────────┬───────────┐
 product_advisor  escalation   off_topic
```

## What this recipe shows

| Concept | Where |
|---|---|
| Pre-flight context gate | `context_gate` intercepts the first message, never answers |
| Two-step gate transition | `collect_employee_count` stores value; `route_to_dispatcher` (gated by `available when > 0`) transitions |
| Shared variable across all topics | `number_of_employees` declared at the top level |
| Intent-based routing | `dispatcher` picks a topic from labelled `@utils.transition` actions |
| Specialist topics returning to hub | Every specialist ends with `transition to @topic.dispatcher` |
| Company size never re-asked | `context_gate` is never re-entered; variable persists for the session |

## Conversation flow

```
User  → "What pricing plan suits us best?"

Agent → [context_gate]
         "Before I answer, how many employees does your company have?"

User  → "Around 120."

Agent → [collect_employee_count: stores 120] [route_to_dispatcher: transitions]
        [dispatcher: sees unanswered product question → routes to product_advisor]
        [product_advisor]
         "For a 120-person team I'd recommend the mid-market Growth plan — it
          covers the admin controls and integrations a team your size typically needs."

User  → "This is taking too long, I need to speak to someone."

Agent → [product_advisor: off-domain → return_to_dispatcher]
        [dispatcher: complaint → escalation]
        [escalation]
         "I'm sorry to hear that. Let me connect you with your account manager."

User  → "What's the weather like today?"

Agent → [escalation: off-domain → return_to_dispatcher]
        [dispatcher: off-topic → off_topic]
        [off_topic]
         "That's a bit outside what I can help with here — is there anything
          about our products I can assist you with?"

User  → "Yes, does the Enterprise plan include SSO?"

Agent → [off_topic: → return_to_dispatcher]
        [dispatcher: product question → product_advisor]
        [product_advisor — number_of_employees still 120]
         "Yes, SSO is included in the Enterprise plan. For a team your size…"
```

## Key mechanics

### 1. Gate-to-dispatcher transition (two actions, not one)

`transition to @topic.xxx` as a suffix is only valid on `@actions.xxx` (custom Flow/Apex actions), **not** on `@utils.setVariables`. The fix is two separate actions called in sequence:

```yaml
# Step 1 — store the value
collect_employee_count: @utils.setVariables
   with number_of_employees=...

# Step 2 — transition (only available after step 1 stores a positive value)
route_to_dispatcher: @utils.transition to @topic.dispatcher
   available when @variables.number_of_employees > 0
```

The `available when` guard prevents `route_to_dispatcher` from appearing in the tool list until the count is stored. The instructions explicitly tell the LLM to call both in sequence, so the hand-off happens in the same turn.

### 2. Intent-based routing in the dispatcher

```yaml
topic dispatcher:
   reasoning:
      actions:
         product_questions: @utils.transition to @topic.product_advisor
            description: "Product features, pricing, plan comparisons, or recommendations"

         escalate: @utils.transition to @topic.escalation
            description: "Complaints, urgent issues, or requests to speak to a person"

         off_topic: @utils.transition to @topic.off_topic
            description: "Questions unrelated to company products"
```

The LLM reads each `description` and picks the best match — exactly like function-calling tool selection.

### 3. Specialist topics returning to the hub

```yaml
topic product_advisor:
   reasoning:
      actions:
         return_to_dispatcher: @utils.transition to @topic.dispatcher
            description: "User's next question is not about products — re-route it"
```

Every specialist has a `return_to_dispatcher` action. When the conversation shifts domain, the LLM triggers it and the dispatcher takes over for the next message.

### 4. Company size persists everywhere

`number_of_employees` is a top-level variable. All topics reference `{!@variables.number_of_employees}` in their instructions — no need to re-collect or pass it between topics.

## Adding more topics

To add a new specialist (e.g. `billing`):

1. Add a routing action to `dispatcher`:
   ```yaml
   billing: @utils.transition to @topic.billing
      description: "Billing questions, invoices, payment methods"
   ```

2. Define the new topic and have it return to the dispatcher:
   ```yaml
   topic billing:
      description: "Handles billing and payment questions"
      reasoning:
         instructions:->
            | Answer billing questions.
              Company size: {!@variables.number_of_employees} employees.
         actions:
            return_to_dispatcher: @utils.transition to @topic.dispatcher
               description: "Billing handled — re-route the next question"
   ```

## Deploy

```bash
sf project deploy start \
  -d force-app/main/01_languageEssentials/contextualProductAdvisor
```
