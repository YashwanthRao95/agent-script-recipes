# ContextualProductAdvisor

Demonstrates the **pre-flight context collection** pattern: before answering the user's first product question, the agent interrupts to collect one key piece of context — company size — then answers the original question (and all future ones) with that context baked in, without ever asking again.

## What this recipe shows

| Concept | How it is used |
|---|---|
| Pre-flight context gate | `available when @variables.number_of_employees == 0` blocks the collect action after the first use |
| Two-state instructions | One branch for "not collected yet", one for "collected", so the LLM always knows what to do |
| Persistent session context | Variable value survives for the entire chat; no re-prompting |
| Conversation history recall | LLM uses message history to answer the user's original question after the interruption |

## Conversation flow

```
User  → "What pricing plan would suit us best?"

Agent → "Before I answer, could you quickly tell me how many employees
          your company has? This helps me give you the most relevant
          recommendation."

User  → "We have around 120 people."

Agent → [collect_employee_count fires, stores 120]
         "Great! For a 120-person team you'd typically fall into our
          mid-market tier. Here's what I'd recommend for your pricing…"

User  → "Does it integrate with Slack?"

Agent → [number_of_employees == 120, no re-prompting]
         "Yes — for a team your size the Slack integration is especially
          useful because…"
```

## Key mechanics

### 1. Single mutable variable

```yaml
variables:
   number_of_employees: mutable number = 0
```

`0` means "not yet collected". Any positive value means "already known". No second variable is needed.

### 2. `available when` guard — the ask-once guarantee

```yaml
collect_employee_count: @utils.setVariables
   available when @variables.number_of_employees == 0
   with number_of_employees=...
```

Once the value is set, the condition evaluates to `false` and Agentforce never offers this action again — for the rest of the session.

### 3. Two-state instructions

```yaml
if @variables.number_of_employees == 0:
   | Do NOT answer yet. Ask for employee count first.
else:
   | Company size: {!@variables.number_of_employees} employees.
     Answer the user's question, tailoring to their company size.
     If the original question was never answered, answer it now.
```

The LLM always has one unambiguous job per turn.

### 4. Conversation history for the pending question

When the agent finally answers after collecting company size, it reads back through the conversation to find the user's unanswered question. No extra variable is needed — the chat transcript is the source of truth.

## Adapting to your use case

| What to change | Where |
|---|---|
| Collected field | Rename `number_of_employees`; change type if needed (`string`, `boolean`, …) |
| Sizing tiers / answer guidance | Edit the `else` branch of `instructions` |
| Agent persona | Edit `system.instructions` |
| Welcome message | Edit `system.messages.welcome` |

## Deploy

```bash
sf project deploy start \
  -d force-app/main/01_languageEssentials/contextualProductAdvisor
```
