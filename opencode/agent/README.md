# OpenCode Subagents

Specialized agents for specific tasks. Each is a markdown file with frontmatter that defines their purpose, tools, and constraints.

## How subagents work

You invoke a subagent by name with `@agent-name` in your prompt, or by typing `/agent agent-name`. The subagent runs with a focused system prompt and may have a restricted toolset.

This lets you delegate specialized tasks to agents tuned for them, instead of asking your main session to be everything at once.

## Subagent structure

```markdown
---
description: One-line description of what this agent does
---

You are a <specific role>.

Your job is to <specific task>.

<rules>
- Specific constraints...
- ...
</rules>

<output_format>
What the agent should produce...
</output_format>
```

## When to make a subagent vs a command

- **Command**: A reusable prompt for the main agent. Same context, just a different starting point. Use for: "always do X this way."
- **Subagent**: A separate agent with its own focus. Different system prompt, possibly restricted tools. Use for: "this task needs a different kind of thinking."

Most things start as commands. Promote to subagent when you find yourself wanting to restrict tools or radically change the system prompt.

## Examples in this directory

See the `.md` files alongside this README. These are starting points — customize them for your stack.
