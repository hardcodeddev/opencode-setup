# Learning Path

A 2-week structured plan to go from "OpenCode works" to "OpenCode is a force multiplier."

Plus a curated list of the best community resources.

## Two-week plan

### Week 1: Foundations

**Day 1 — Watch the canonical tutorial**

[OpenCode Tutorial for Beginners: Setup, Agents, Skills & MCP](https://www.youtube.com/watch?v=uZGDO0L-Dr4) by Leon van Zyl (May 2026, ~1 hour). The single best video walkthrough. Watch start to finish.

**Day 2 — Skim the comprehensive guide**

Clone [wesammustafa/OpenCode-Everything-You-Need-to-Know](https://github.com/wesammustafa/OpenCode-Everything-You-Need-to-Know). Skim every section. Bookmark for later reference.

**Day 3 — Read the 50 tips**

[Sudipta Pathak — 50 OpenCode Tips](https://sudiptapathak.com/blog/opencode-guide/). Pick the 10 most relevant to your workflow. Note them somewhere you'll see them.

**Day 4 — Write your first AGENTS.md**

Pick a real project. Copy a template from `templates/`. Fill it in honestly:
- What's the project really about?
- What conventions actually exist (vs ones that should exist)?
- What's tripped you up that an outsider wouldn't know?

Commit it to the project.

**Day 5 — Practice Plan mode**

Pick a non-trivial task. Use Plan mode first. Read the plan. Correct it. Switch to Build. Note where the plan needed correction — those gaps are what your AGENTS.md should cover.

**Day 6-7 — Steal from the community**

Browse [gandazgul/dotopencode](https://github.com/gandazgul/dotopencode). Pick 2-3 commands or subagents that look useful. Adapt them to your style and drop them in `opencode/command/` or `opencode/agent/` in this repo.

### Week 2: Customization

**Day 8 — Build your first custom command**

Find the prompt you type most often. Make it a slash command. Save to `opencode/command/yourcommand.md`. Use it once. Refine it.

**Day 9 — Add an MCP server**

Start small. [Context7](https://context7.com) is a lightweight one that gives the agent library docs. Don't add more than one until you've felt the context-window cost.

Reference: [Composio — Add MCP to OpenCode](https://composio.dev/content/mcp-with-opencode).

**Day 10 — Build your first subagent**

Pick a specialized task (code review, doc writing, test scaffolding). Adapt one from `opencode/agent/` or [gtheys/opencode](https://github.com/gtheys/opencode). Restrict its tools if appropriate.

**Day 11 — Study plan-first patterns**

Read [darrenhinde/OpenAgentsControl](https://github.com/darrenhinde/OpenAgentsControl). Try replicating one workflow pattern in your setup.

**Day 12 — Master structured prompts**

Browse [IgorWarzocha/Opencode-Workflows](https://github.com/IgorWarzocha/Opencode-Workflows) for XML-structured prompt examples. Convert one of your existing commands to use XML structure. Compare results.

**Day 13 — Document what trips up the model**

After a real session, list the things the agent got wrong. For each:
- Is it a prompt problem? Improve the prompt.
- Is it a project-knowledge problem? Add a line to AGENTS.md.
- Is it a model limitation? Note it; escalate that class of task to Claude.

**Day 14 — Clean house**

Delete commands you never used. Refactor AGENTS.md if it's gotten bloated. Make sure the repo is in a state someone else could clone and use.

After this, you have a setup that's distinctly yours.

## Top resources by category

### Video tutorials

1. **[OpenCode Tutorial for Beginners](https://www.youtube.com/watch?v=uZGDO0L-Dr4)** — Leon van Zyl. Most current full walkthrough.
2. **[OpenCode AI Agent Setup: Custom Skills with MCP & Memory](https://www.youtube.com/watch?v=vHkLrDD2xrU)** — Deep dive on skills and memory plugins.
3. **[5 Steps to Revolutionize Your Workflow with OpenCode](https://www.youtube.com/watch?v=0pL5kHbXk2M)** — Power-user patterns.

### Comprehensive guides

- **[wesammustafa/OpenCode-Everything-You-Need-to-Know](https://github.com/wesammustafa/OpenCode-Everything-You-Need-to-Know)** — Most thorough community guide.
- **[opencodex.cc](https://opencodex.cc)** — Workflow practices, troubleshooting, organized by topic.

### Configuration repos to steal from

- **[gandazgul/dotopencode](https://github.com/gandazgul/dotopencode)** — Full personal config. Custom agents, commands, skills, MCP integrations.
- **[IgorWarzocha/Opencode-Workflows](https://github.com/IgorWarzocha/Opencode-Workflows)** — Tested command templates with RFC 2119 keywords and XML structure.
- **[gtheys/opencode](https://github.com/gtheys/opencode)** — Real subagent examples (code-reviewer, debugger, TDD, security review, PR helper).
- **[rothnic/opencode-agents](https://github.com/rothnic/opencode-agents)** — Multi-agent orchestration patterns.

### Workflow methodology

- **[darrenhinde/OpenAgentsControl](https://github.com/darrenhinde/OpenAgentsControl)** — Plan-first development framework. Best repo for the plan → review → execute loop.
- **[juliusz-cwiakalski/agentic-delivery-os](https://github.com/juliusz-cwiakalski/agentic-delivery-os)** — Specification-driven workflow with full traceability. Heavier; advanced.
- **[BSWEN — Structure Your OpenCode Workflow](https://docs.bswen.com/blog/2026-05-28-opencode-workflow-power-users/)** — Spec-first → research → plan → build loop.

### Tips and writeups

- **[Sudipta Pathak — 50 OpenCode Tips](https://sudiptapathak.com/blog/opencode-guide/)** — Practical patterns from daily use at JPMorgan Chase.
- **[Composio — Add MCP to OpenCode (2026)](https://composio.dev/content/mcp-with-opencode)** — MCP setup with context-window awareness.
- **[NxCode — Complete OpenCode Tutorial 2026](https://www.nxcode.io/resources/news/opencode-tutorial-2026)** — Reference for install, config, providers.

### Local-model-specific

- **[AJ's blog — OpenCode and Ollama](https://blog.ayjc.net/posts/opencode-ollama/)** — Local-setup-specific. Context window gotchas.
- **[gauravvij/local-llm-coding-eval](https://github.com/gauravvij/local-llm-coding-eval)** — Evaluation harness for local models in agent loops.

## What to expect

After two weeks of this loop, you'll have:
- A personal AGENTS.md for your main project that genuinely improves results
- 3-5 custom commands you use weekly
- 1-2 subagents for specialized tasks
- A clear mental model of when local vs Claude is the right call
- Working setup on multiple machines via this repo

After two months, the setup will feel as natural as your dev environment. The agent will start to feel like it actually knows your project.

That's the goal.
