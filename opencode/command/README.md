# OpenCode Commands

Custom slash commands live here. Each command is a single markdown file. The filename (minus `.md`) becomes the command name.

## How commands work

When you type `/mycommand` in OpenCode, it loads the corresponding `.md` file from this directory (or the per-project `.opencode/command/` directory) and uses its content as the prompt.

Inside command files:
- Plain text is the prompt
- `@path/to/file.md` loads a file's contents into context before the agent thinks
- Arguments after the command name are passed as `$ARGUMENTS`

## Example structure

```markdown
You are a code reviewer. Review the changes in $ARGUMENTS.

Focus on:
- Logic errors
- Edge cases
- Performance concerns
- Security implications

Reference our standards: @AGENTS.md
```

Then use it: `/review HEAD~1`

## Examples in this directory

See the `.md` files alongside this README for starter commands. Customize them, delete the ones you don't use, and add your own.

## Tips for writing good commands

1. **Be specific.** Vague commands produce vague results. "Review code" is bad. "Review for logic errors, edge cases, and security issues following our AGENTS.md" is good.

2. **Use XML tags for structure.** Qwen-family models respond well to:
   ```xml
   <task>What to do</task>
   <constraints>Rules to follow</constraints>
   <context>Files to consider</context>
   ```

3. **Load context upfront.** Use `@file` references to load relevant files before the agent starts.

4. **Specify output format.** "Output a numbered list of issues with severity tags" is better than "tell me what's wrong."

5. **One command per workflow.** Don't make a single mega-command. Make small focused ones and chain them.
