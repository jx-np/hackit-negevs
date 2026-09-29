---
name: context-management
description: Keep the working context small and focused during long or growing sessions. Use when the conversation is getting long, context/tokens are adding up, work spans many files or PRs, the agent starts re-reading things it already saw, or the user says the chat is getting big, asks to summarize, compact, checkpoint, or hand off. Also use before a large multi-step task to set up an efficient context strategy.
metadata:
  author: ScamReg team
  version: "1.0"
---

# Context Management

Long sessions accumulate context (large file reads, tool output, superseded
plans) that crowds out what matters and slows things down. This skill is a
playbook for keeping the working set small, current, and relevant — without
losing important decisions.

## When this applies
- The conversation is long or the user says context/tokens are "adding up".
- Work spans many files, branches, or PRs across a session.
- You catch yourself re-reading files or re-deriving decisions already made.
- The user asks to summarize, compact, checkpoint, or hand off.
- You're about to start a large multi-step task.

## Core principles
1. **Summarize, then discard detail.** Once a chunk of work is done, keep a
   short durable summary (what changed, where, why) and stop referring back to
   the raw file dumps or long tool output that produced it.
2. **Read narrowly.** Prefer `grep`/`glob` + targeted line-ranged reads over
   whole-file reads. Never re-read a file whose relevant content is already in
   context or captured in a summary.
3. **Delegate exploration.** For "understand this area" questions, dispatch the
   `context-gatherer` sub-agent and keep only its returned analysis — the bulky
   intermediate reads stay in the sub-agent, not the main thread.
4. **Track state compactly.** Use the todo list as the durable record of intent
   and progress; put file paths + one-line notes in its context updates rather
   than re-explaining in chat.
5. **Drop the stale.** When a plan/design is superseded, say so once and move
   on. Don't keep reconciling against abandoned approaches.

## Practical checklist during a long task
- [ ] After each meaningful sub-task, write a 1-3 line summary (files touched,
      key decision, test/build status) — into the todo `context_update`.
- [ ] Reference earlier work by summary, not by re-reading or re-quoting.
- [ ] Use `grep_search`/`file_search` to locate; read only the needed ranges.
- [ ] For unfamiliar areas, use `context-gatherer` instead of many manual reads.
- [ ] Keep only the latest version of an evolving artifact in view.
- [ ] Prefer diffs/PR links over pasting whole files back into chat.

## Producing a context digest (on request or at a natural break)
When asked to summarize/checkpoint/hand off, output a compact digest:

```
## Session digest
- Goal: <the overall objective>
- Done: <bullet list of completed items, each with file paths / PR numbers>
- Current state: <branch, build/test status, what's merged vs open>
- Open threads / next steps: <what remains, decisions pending>
- Key decisions & constraints: <choices that must persist (stack, conventions)>
- Pointers: <important files/dirs, PR links> (not full file contents)
```

Keep it to what a fresh session would need to continue — omit narrative and
raw tool output.

## Kiro tools that reclaim context (tell the user about these)
These are user-invoked slash commands in Kiro — surface them when context is
heavy; don't assume they run automatically:
- **`/compact`** — summarizes the conversation so far and continues with a
  smaller context window. Best after finishing a chunk of work.
- **`/rewind`** — roll back to an earlier point in the session to drop context
  accumulated by an exploration or dead end.
- Starting a **new session** for an unrelated task is often cheaper than
  carrying a long history forward; hand off with a digest (above).

When the user says context is growing, offer a digest now and suggest
`/compact` (or a fresh session seeded with the digest) as the next step.

## Anti-patterns to avoid
- Re-reading a file already summarized "just to be sure".
- Pasting entire files back into chat to reference one function.
- Keeping multiple superseded plans "for context".
- Doing broad manual exploration in the main thread instead of delegating it.
