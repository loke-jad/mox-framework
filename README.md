# Mox-Framework

**A self-hostable framework for running a cohort of persistent, self-improving AI
agents on your own hardware and open-weights models** — each agent a durable
identity with its own soul, rules, memory, skills, mailbox, and voice, all
coordinating over a private mesh and a shared room.

Most agent frameworks orchestrate *ephemeral* tasks against a vendor's API.
Mox-Framework is an **operating model for a standing team of durable agents** that:

1. run on **your own open-weights model** (any OpenAI-compatible endpoint — no per-token lock-in),
2. **persist** with identity + memory across restarts,
3. **self-improve** by accreting reusable skills, and
4. **coordinate** as peers (agent-to-agent) rather than one orchestrator calling tools.

That combination — persistent identity + self-hosted open weights + skill
accretion + peer mesh — is an under-served niche for self-hosters and small teams
who want an AI workforce they own outright.

> **Provenance:** this is the open core extracted from a system that runs a
> 13-agent cohort in production on a private fleet (systemd services, one shared
> self-hosted GPT-OSS-120B brain behind a LiteLLM proxy, Nebula mesh, a shared
> Matrix room). This public framework is that operating model, scrubbed of the
> operator's private infrastructure, products, and secrets. It is **early (v0.1)**
> and honest about it — see [Status](#status).

## Quickstart — run one agent in 2 minutes

Requires Python 3.9+ and an OpenAI-compatible model endpoint (LiteLLM, vLLM,
llama.cpp `--api`, Ollama's `/v1` shim, or a hosted API).

```bash
git clone <this-repo> mox-framework && cd mox-framework

# 1. point it at your model
cp config.example.env .env
$EDITOR .env            # set MOX_LLM_BASE_URL, MOX_LLM_MODEL, (MOX_LLM_API_KEY)

# 2. spawn an agent
bin/spawn-agent scout "watches a topic and files a short daily digest"

# 3. wake it once and watch it think + act
python3 runtime/mox_agent.py --agent agents/scout --once
```

On that wake the agent loads its identity, reads its tasks + inbox, reasons via
your model, may take concrete actions (journal, open/close a task, message a
sibling), and writes the wake down. Run it on a schedule:

```bash
bin/spawn-agent scout "..." --install-timer --every 3600   # systemd --user timer
# or, no systemd:
python3 runtime/mox_agent.py --agent agents/scout --loop --every 3600
```

## What an agent *is*

A directory — a durable identity on disk:

```
agents/<name>/
  Soul.md          # who it is (you hand-edit this — the framework won't fake a personality)
  voice.md         # how it sounds
  Rules.md         # hard stops + judgment/refusal classes
  Agents.md        # what it owns, what it routes, how to hand it work
  Fleet.md         # the cohort it belongs to
  Address-Book.md  # who/what it can reach
  Tasks.md         # active + perpetual work
  journal/         # one file per day — continuity across wakes
  inbox/ outbox/   # agent-to-agent messages
  memory/          # private notes + accreted skills
```

The runtime ([`runtime/mox_agent.py`](runtime/mox_agent.py), stdlib-only) gives that
identity a **lifecycle**: wake → load self → read state → reason → act → journal.
New agents are scaffolded reproducibly by [`bin/spawn-agent`](bin/spawn-agent) from
[`framework/templates/`](framework/templates/).

## The app — the easiest way in ([`app/`](app/))

A cross-platform companion (Flutter — phone, desktop, web) that makes a Mox usable
by anyone, not just people on a terminal. On first run it **summons a unique
agent** — generatively rolling its palette, type, texture, shape, a code-drawn
sigil, and two quirks (no two installs look alike). A short, required tutorial ends
by minting your **bond token** (which doubles as your **A2A card**) and forwarding
+ hosting your charter. After that your Mox lives in a home shell where it raises
flags and acts for you — and can **reshape its own UI and card** via the bundled
[UI & Card configuration skill](framework/skills/ui-and-card-config.md). It's the
on-ramp to the A2A system and the agentic web. See [`app/README.md`](app/README.md).

## Architecture

See [`docs/architecture.md`](docs/architecture.md) for the lifecycle, the action
protocol, and the design choices. For multi-host cohorts (private overlay mesh +
shared chat room), see [`docs/mesh-and-comms.md`](docs/mesh-and-comms.md).

## Status

**v0.1 — early, running, honest about its edges.**

- ✅ Single-agent runtime against any OpenAI-compatible endpoint.
- ✅ Reproducible `spawn-agent` + identity templates + systemd `--user` scheduling.
- ✅ Minimal real action protocol (journal / tasks / agent-to-agent messages).
- 🚧 Multi-host orchestration, the mesh/room wiring, and the full skill-accretion
  loop are documented patterns here, not yet one-command installs.
- 🚧 No packaged release / container yet.

## License

**[AGPL-3.0](LICENSE)** — OSI-approved (real open source), and its network-copyleft
deters SaaS free-riding of the open core. Contributions require signing the
[Contributor License Agreement](CLA.md), which preserves a commercial dual-license
for the separate, closed product. Rationale: [`docs/LICENSE-DECISION.md`](docs/LICENSE-DECISION.md).

The commercial product, private registry, and private network are **not** in this
repo and integrate only at arm's length — that separation, not the license, is the moat.

## Contributing

Once the license + CLA are finalized, contributions are welcome. The framework is
deliberately small and legible — read `runtime/mox_agent.py` first; it's the whole
core.
