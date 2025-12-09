# ActionDescriptionOverrides

## Overview

Master **context-specific action descriptions** to improve LLM action selection. Learn how to define different action descriptions for different topics based on user expertise, context, and conversation state for more accurate tool calling.

## Agent Flow

```mermaid
%%{init: {'theme':'neutral'}}%%
graph TD
    A[Agent Starts] --> B[start_agent: topic_selector]
    B --> C{User Mode Selection}
    C -->|Beginner| D[Transition to beginner_mode]
    C -->|Advanced| E[Transition to advanced_mode]
    C -->|Contextual| F[Transition to contextual_search]
    D --> G[Simple Action Descriptions]
    G --> H[simple_search: basic description<br/>create_new_item: simple description]
    E --> I[Technical Action Descriptions]
    I --> J[advanced_search: detailed with filters<br/>create_record_advanced: with schema info<br/>generate_analytics: with parameters]
    F --> K{Search Context Variable?}
    K -->|accounts| L[search_accounts action available]
    K -->|contacts| M[search_contacts action available]
    K -->|cases| N[search_cases action available]
    H --> O[User Executes Action]
    J --> O
    L --> O
    M --> O
    N --> O
    O --> P{Switch Mode?}
    P -->|Yes| C
    P -->|No| Q[Continue in Current Mode]
```

## Key Concepts

- **Topic-level action definitions**: Each topic can define actions with different descriptions
- **Context-aware descriptions**: Adapt descriptions to user level
- **Expertise-based descriptions**: Different detail levels for beginners vs experts
- **Conditional availability**: Use `available when` to show actions based on context
- **Improved LLM selection**: Better descriptions = better tool choices

## How It Works

### Base Action Definition in Topic

Each topic defines its own version of actions with appropriate descriptions:

```agentscript
topic beginner_mode:
   description: "Simplified interface for beginners"

   actions:
      perform_search:
         description: "Search the knowledge base"
         inputs:
            query: string
               description: "Search query text to find relevant articles"
            filters: object
               description: "Filter criteria object to refine search results"
         outputs:
            results: list[object]
               description: "List of search result objects"
         target: "flow://PerformSearch"
```

### Different Descriptions Per Topic

The same underlying action can have different descriptions in different topics:

```agentscript
# Beginner mode - simple descriptions
topic beginner_mode:
   actions:
      perform_search:
         description: "Search the knowledge base"
         ...

# Advanced mode - detailed technical descriptions
topic advanced_mode:
   actions:
      perform_search:
         description: "Execute knowledge base query with advanced filters (supports: type, date range, tags, custom fields). Returns paginated results with relevance scoring."
         inputs:
            query: string
               description: "Search query text with support for advanced syntax and operators"
            filters: object
               description: "Advanced filter criteria object with type, date range, tags, and custom field filters"
         ...
```

### Context-Based Action Availability

Use `available when` to show actions only in specific contexts:

```agentscript
topic contextual_search:
   reasoning:
      actions:
         search_accounts: @actions.perform_search
            available when @variables.search_context == "accounts"
            with query=...
            with filters=...

         search_contacts: @actions.perform_search
            available when @variables.search_context == "contacts"
            with query=...
            with filters=...

         search_cases: @actions.perform_search
            available when @variables.search_context == "cases"
            with query=...
            with filters=...
```

## Key Code Snippets

### Beginner Mode with Simple Descriptions

```agentscript
topic beginner_mode:
   description: "Simplified interface for beginners"

   actions:
      perform_search:
         description: "Search the knowledge base"
         inputs:
            query: string
               description: "Search query text to find relevant knowledge base articles"
            filters: object
               description: "Filter criteria object to refine search results"
         outputs:
            results: list[object]
               description: "List of search result objects containing matching articles"
         target: "flow://PerformSearch"

      create_record:
         description: "Create a new record"
         inputs:
            record_type: string
               description: "Type of record to create"
            data: object
               description: "Record data object containing field-value pairs"
         outputs:
            record_id: string
               description: "Unique identifier of the newly created record"
         target: "flow://CreateRecord"

   reasoning:
      instructions:->
         | Beginner Mode - Simplified Interface

           I'll help you with basic tasks using simple language.

      actions:
         simple_search: @actions.perform_search
            with query=...
            with filters=...

         create_new_item: @actions.create_record
            with record_type=...
            with data=...

         switch_to_advanced: @utils.transition to @topic.advanced_mode
```

### Advanced Mode with Technical Descriptions

```agentscript
topic advanced_mode:
   description: "Full-featured interface for advanced users"

   actions:
      perform_search:
         description: "Execute knowledge base query with advanced filters (supports: type, date range, tags, custom fields). Returns paginated results with relevance scoring."
         inputs:
            query: string
               description: "Search query text with support for advanced syntax and operators"
            filters: object
               description: "Advanced filter criteria object with type, date range, tags, and custom field filters"
         outputs:
            results: list[object]
               description: "Paginated list of search result objects with relevance scores"
         target: "flow://PerformSearch"

      create_record:
         description: "Create new database record. Specify record_type (Account, Contact, Case, Custom__c) and provide data object with field-value pairs. Returns record ID on success."
         inputs:
            record_type: string
               description: "Database record type (Account, Contact, Case, Custom__c, etc.)"
            data: object
               description: "Record data object with field-value pairs matching the specified record type schema"
         outputs:
            record_id: string
               description: "Unique 18-character Salesforce record ID"
         target: "flow://CreateRecord"

      generate_report:
         description: "Generate analytics report. Available types: sales_summary, user_activity, performance_metrics. Accepts parameters object for date ranges, filters, and aggregation options."
         inputs:
            report_type: string
               description: "Report type (sales_summary, user_activity, performance_metrics, etc.)"
            parameters: object
               description: "Report parameters object with date ranges, filters, and aggregation options"
         outputs:
            report_url: string
               description: "URL to access or download the generated report"
         target: "flow://GenerateReport"

   reasoning:
      instructions:->
         | Advanced Mode - Full Technical Interface
         |
         | All features available with detailed technical descriptions.

      actions:
         advanced_search: @actions.perform_search
            with query=...
            with filters=...

         create_record_advanced: @actions.create_record
            with record_type=...
            with data=...

         generate_analytics: @actions.generate_report
            with report_type=...
            with parameters=...

         switch_to_beginner: @utils.transition to @topic.beginner_mode
```

### Context-Aware Search Actions

```agentscript
topic contextual_search:
   description: "Search with context-specific descriptions"

   actions:
      perform_search:
         description: "Search the knowledge base"
         inputs:
            query: string
               description: "Search query text adapted to the current search context"
            filters: object
               description: "Context-specific filter criteria object"
         outputs:
            results: list[object]
               description: "List of context-relevant search result objects"
         target: "flow://PerformSearch"

   reasoning:
      instructions:->
         | Context-Aware Search Interface

           Search descriptions adapt based on what you're looking for.

      actions:
         search_accounts: @actions.perform_search
            available when @variables.search_context == "accounts"
            with query=...
            with filters=...

         search_contacts: @actions.perform_search
            available when @variables.search_context == "contacts"
            with query=...
            with filters=...

         search_cases: @actions.perform_search
            available when @variables.search_context == "cases"
            with query=...
            with filters=...
```

## Try It Out

### Example: Beginner Mode

```text
User: Find information about pricing

Agent sees action:
  simple_search: "Search the knowledge base"

LLM thinks: "User wants to find information, use simple_search"

Agent: [Calls perform_search with query="pricing"]
       Here's what I found about pricing...
```

### Example: Advanced Mode

```text
User: I am an advanced user. Query the knowledge base for articles tagged "API" from last 30 days.

Agent sees action:
  advanced_search: "Execute knowledge base query with advanced filters (supports: type, date range, tags, custom fields). Returns paginated results."

LLM thinks: "User wants advanced query with filters, use advanced_search"

Agent: [Calls perform_search with query="API" and complex filters]
       Found 15 API articles from the last 30 days...
```

### Example: Context-Aware

```text
User: Search for contact John Smith

[Context: search_context = "accounts"]
Agent sees: search_accounts action available

Agent: [Searches accounts]
       Found 3 companies with "John Smith" in the name

---

User: Search for John Smith

[Context: search_context = "contacts"]
Agent sees: search_contacts action available

Agent: [Searches contacts]
       Found 5 contacts named John Smith
```

## Why Different Descriptions?

### Better LLM Understanding

- Clearer descriptions = better tool selection
- Context-specific language matches user intent
- Reduces wrong tool calls

### Expertise Adaptation

- Beginners get simple explanations
- Experts get technical details
- Appropriate for skill level

### Context Clarity

- Actions described for current context
- Reduces ambiguity
- Guides LLM to right tool

## Best Practices

✅ **Match user expertise** - Beginners need simple, experts need detailed

✅ **Be specific** - Describe what action does in this context

✅ **Use clear language** - Avoid jargon unless in advanced mode

✅ **Document parameters** - Explain what inputs are available

❌ **Don't use same description** - If context matters, customize it

❌ **Don't be vague** - Specific descriptions help LLM choose correctly

## Description Guidelines

### Beginner Descriptions

- Use plain language
- Focus on outcome
- Hide technical details
- Example: "Search the knowledge base"

### Advanced Descriptions

- Use technical terms
- Explain parameters
- Include capabilities
- Example: "Execute query with advanced filters (type, date range, tags). Returns paginated results with relevance scoring."

### Context-Specific Descriptions

- Mention the context
- Explain what it searches
- Be concrete
- Example: "Search customer accounts by name, industry, location"

## What's Next

- **DynamicActionRouting**: Combine with `available when` patterns
- **SystemInstructionOverrides**: Use with persona changes
- **AdvancedReasoningPatterns**: Build sophisticated selection logic

## Testing

Test description effectiveness:

### Test Case 1: Beginner Mode

- Use beginner-friendly descriptions
- Test LLM selects correct action
- Verify simple language works

### Test Case 2: Advanced Mode

- Use technical descriptions
- Test with complex requests
- Verify detailed descriptions help

### Test Case 3: Context Switching

- Switch between contexts
- Verify actions adapt
- Check LLM selects appropriately

### Test Case 4: Ambiguous Request

- Give ambiguous input
- Verify context-specific action guides LLM
- Check correct action chosen
