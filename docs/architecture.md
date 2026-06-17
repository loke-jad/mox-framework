# Architecture

Mox-Framework is small on purpose. The whole core is one file
(`runtime/mox_agent.py`); everything else is templates, scheduling, and docs.

## The agent lifecycle (one "wake")

```
        ┌─────────────────────────────────────────────┐
        │  wake (manual --once, or a systemd timer)    │
        └───────────────────────┬─────────────────────┘
                                 ▼
   load identity  ──►  Soul + voice + Rules + Agents + Fleet + Address-Book
                                 │   (become the system prompt, in that order)
                                 ▼
   read state     ──►  Tasks.md  +  inbox/*.md   (become the wake message)
                                 ▼
   reason         ──►  one call to an OpenAI-compatible /v1/chat/completions
                                 ▼
   act            ──►  parse a trailing ```json {"actions":[…]} ``` block:
                         journal · add_task · complete_task · message <peer>
                                 ▼
   journal        ──►  append the wake to journal/<date>.md (always, even if quiet)
```

This is the same shape whether an agent runs once or loops on a schedule. The
key property: **state lives on disk, not in the process.** A fresh process is a
new wake of the same role — continuity comes from the files, never from a
long-lived session. (That's also what `becoming.md` formalizes for re-instantiation.)

## The action protocol

The agent's reply is free prose, optionally ending with one fenced `json` block:

```json
{"actions": [
  {"type": "journal", "text": "…"},
  {"type": "add_task", "text": "…"},
  {"type": "complete_task", "match": "substring of the task line"},
  {"type": "message", "to": "peer-agent", "text": "…"}
]}
```

The runtime executes these against the agent's directory (and a peer's `inbox/`
for messages). It's deliberately minimal — a real but small set of side effects
that make an agent *act* rather than just chat. Adding a tool = adding a case in
`apply_actions()`; this is the intended extension point (shell, HTTP, MCP, etc.),
gated by the agent's `Rules.md`.

## Scheduling (the "poke" pattern)

In production the cohort wakes each agent on a cadence that mirrors a team's
rhythm: an hourly check, an end-of-day journal, a weekly self-improvement pass, a
weekly tidy, a weekly self-reflection, and a periodic off-host backup. Here that's
reduced to a single `systemd --user` timer per agent (`mox-agent-tick@<name>`),
with the cadence as `--every`. You can run several timers with different prompts
to reproduce the full rhythm.

## Why open weights / OpenAI-compatible

Routing every agent through one OpenAI-compatible endpoint (e.g. a LiteLLM proxy
fronting a self-hosted model) means: no per-token vendor lock-in, one place to
swap or fall back models, and the whole cohort runs on hardware you control. See
`examples/litellm-config.example.yaml`.

## What's intentionally NOT here

The commercial product, any private registry, and the operator's private network
live in **separate closed repos** and integrate with this framework only at
arm's length (network/process boundaries). That separation — not the license — is
the real moat. See `docs/LICENSE-DECISION.md`.
