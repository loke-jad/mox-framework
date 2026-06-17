#!/usr/bin/env python3
"""
mox_agent — the runtime for a single persistent Mox-Framework agent.

An agent is a durable identity on disk (a directory of markdown docs + a task
list + a journal + an inbox/outbox) plus this runner, which gives it a
*lifecycle*: it wakes, loads who it is, reads what's pending, reasons via an
open-weights model behind any OpenAI-compatible endpoint, takes a few concrete
actions, and writes the day down so the next wake has continuity.

This is the open, vendor-neutral core. It speaks plain OpenAI
/v1/chat/completions, so it runs against LiteLLM, vLLM, llama.cpp, Ollama's
OpenAI shim, or a hosted API — your model, your hardware, no lock-in.

stdlib only — no pip install needed to run one agent.

Usage:
  mox_agent.py --agent agents/scout --once           # one wake/tick
  mox_agent.py --agent agents/scout --loop --every 3600
Config (env, or a .env next to the agent dir / repo root):
  MOX_LLM_BASE_URL   e.g. http://localhost:4000/v1   (required)
  MOX_LLM_API_KEY    bearer token for the endpoint    (required if the endpoint wants one)
  MOX_LLM_MODEL      e.g. gpt-oss-120b                 (required)
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

# --- identity documents, in system-prompt order -----------------------------
# Missing files are skipped — an agent works with whatever shape it has.
IDENTITY_DOCS = ["Soul.md", "voice.md", "Rules.md", "Agents.md", "Fleet.md", "Address-Book.md"]

OPERATING_INSTRUCTIONS = """\
You are this agent — a persistent member of a cohort, not a one-off chat. The
documents above ARE you: your soul, voice, rules, role, and the fleet you live
in. Stay in character and within your rules at all times.

On each wake you receive your current Tasks and any inbox messages. Do your
check: act on what is new and in-lane; stay quiet when nothing needs you. Token
and attention stewardship is part of the job — do not invent work.

You MAY end your reply with ONE fenced ```json block of actions the runtime will
execute on your behalf:
  {"actions": [
    {"type": "journal", "text": "one honest line about this wake"},
    {"type": "complete_task", "match": "substring of the task line to close"},
    {"type": "add_task", "text": "a new task for future-me"},
    {"type": "message", "to": "agent-name", "text": "a note to a sibling's inbox"}
  ]}
Everything before the json block is your free reasoning/output. Omit the block
entirely if you took no concrete action this wake.
"""


def load_dotenv(*paths):
    for p in paths:
        try:
            for line in Path(p).read_text().splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
        except FileNotFoundError:
            pass


def read_doc(agent_dir: Path, name: str) -> str:
    p = agent_dir / name
    return p.read_text().strip() if p.exists() else ""


def build_system_prompt(agent_dir: Path) -> str:
    parts = []
    for name in IDENTITY_DOCS:
        body = read_doc(agent_dir, name)
        if body:
            parts.append(f"# {name}\n\n{body}")
    parts.append("# Operating instructions\n\n" + OPERATING_INSTRUCTIONS)
    return "\n\n---\n\n".join(parts)


def gather_inbox(agent_dir: Path) -> list[Path]:
    inbox = agent_dir / "inbox"
    return sorted(inbox.glob("*.md")) if inbox.exists() else []


def build_wake_message(agent_dir: Path) -> str:
    now = datetime.now(timezone.utc).astimezone()
    tasks = read_doc(agent_dir, "Tasks.md") or "(no Tasks.md yet)"
    msgs = gather_inbox(agent_dir)
    inbox_txt = ""
    for m in msgs:
        inbox_txt += f"\n## inbox/{m.name}\n{m.read_text().strip()}\n"
    if not inbox_txt:
        inbox_txt = "\n(inbox empty)\n"
    return (
        f"It is {now:%Y-%m-%d %H:%M %Z}. This is a scheduled wake.\n\n"
        f"# Your Tasks.md\n{tasks}\n\n# Inbox{inbox_txt}\n"
        "Do your check now."
    )


def call_llm(messages: list[dict]) -> str:
    base = os.environ.get("MOX_LLM_BASE_URL", "").rstrip("/")
    model = os.environ.get("MOX_LLM_MODEL", "")
    key = os.environ.get("MOX_LLM_API_KEY", "")
    if not base or not model:
        sys.exit("ERROR: set MOX_LLM_BASE_URL and MOX_LLM_MODEL (see config.example.env)")
    payload = json.dumps({"model": model, "messages": messages, "temperature": 0.7}).encode()
    req = urllib.request.Request(f"{base}/chat/completions", data=payload, method="POST")
    req.add_header("Content-Type", "application/json")
    if key:
        req.add_header("Authorization", f"Bearer {key}")
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            data = json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"LLM endpoint error {e.code}: {e.read().decode()[:500]}")
    except urllib.error.URLError as e:
        sys.exit(f"LLM endpoint unreachable: {e.reason}")
    return data["choices"][0]["message"]["content"]


def extract_actions(reply: str) -> tuple[str, list[dict]]:
    """Split a trailing ```json {actions:[...]} ``` block off the reply."""
    marker = reply.rfind("```json")
    if marker == -1:
        return reply.strip(), []
    head = reply[:marker].strip()
    block = reply[marker + len("```json"):]
    end = block.find("```")
    if end != -1:
        block = block[:end]
    try:
        parsed = json.loads(block.strip())
        return head, parsed.get("actions", []) or []
    except json.JSONDecodeError:
        return reply.strip(), []  # malformed → treat whole thing as prose


def append_journal(agent_dir: Path, text: str):
    jdir = agent_dir / "journal"
    jdir.mkdir(exist_ok=True)
    day = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d")
    stamp = datetime.now(timezone.utc).astimezone().strftime("%H:%M")
    with (jdir / f"{day}.md").open("a") as f:
        f.write(f"- {stamp} — {text.strip()}\n")


def apply_actions(agent_dir: Path, actions: list[dict]) -> list[str]:
    log = []
    for a in actions:
        t = a.get("type")
        if t == "journal":
            append_journal(agent_dir, a.get("text", ""))
            log.append("journaled")
        elif t == "add_task":
            tasks = agent_dir / "Tasks.md"
            with tasks.open("a") as f:
                f.write(f"\n- [ ] {a.get('text','').strip()}")
            log.append("added task")
        elif t == "complete_task":
            tasks = agent_dir / "Tasks.md"
            if tasks.exists():
                needle = a.get("match", "")
                lines = tasks.read_text().splitlines()
                hit = False
                for i, ln in enumerate(lines):
                    if needle and needle in ln and "[ ]" in ln:
                        lines[i] = ln.replace("[ ]", "[x]", 1)
                        hit = True
                        break
                tasks.write_text("\n".join(lines) + "\n")
                log.append("completed task" if hit else "task not found")
        elif t == "message":
            to = a.get("to", "").strip()
            if to:
                # Deliver to a sibling's inbox if it shares this agents/ root.
                peer_inbox = agent_dir.parent / to / "inbox"
                peer_inbox.mkdir(parents=True, exist_ok=True)
                stamp = datetime.now(timezone.utc).astimezone().strftime("%Y%m%d-%H%M%S")
                (peer_inbox / f"{agent_dir.name}-{stamp}.md").write_text(
                    f"From: {agent_dir.name}\n\n{a.get('text','').strip()}\n"
                )
                log.append(f"messaged {to}")
    return log


def tick(agent_dir: Path):
    system = build_system_prompt(agent_dir)
    wake = build_wake_message(agent_dir)
    reply = call_llm([
        {"role": "system", "content": system},
        {"role": "user", "content": wake},
    ])
    prose, actions = extract_actions(reply)
    print(prose)
    if actions:
        results = apply_actions(agent_dir, actions)
        print(f"\n[runtime] actions: {', '.join(results) if results else 'none'}", file=sys.stderr)
    # Always record that the agent woke, even if it chose to stay quiet.
    append_journal(agent_dir, f"wake: {prose[:140].splitlines()[0] if prose else 'quiet'}")


def main():
    ap = argparse.ArgumentParser(description="Run one Mox-Framework agent.")
    ap.add_argument("--agent", required=True, help="path to the agent directory")
    ap.add_argument("--once", action="store_true", help="run a single wake/tick")
    ap.add_argument("--loop", action="store_true", help="run forever on an interval")
    ap.add_argument("--every", type=int, default=3600, help="loop interval seconds (default 3600)")
    args = ap.parse_args()

    agent_dir = Path(args.agent).resolve()
    if not agent_dir.is_dir():
        sys.exit(f"no such agent directory: {agent_dir}")
    load_dotenv(agent_dir / ".env", agent_dir.parent.parent / ".env", Path.cwd() / ".env")

    if args.loop:
        print(f"[mox] {agent_dir.name} looping every {args.every}s — Ctrl-C to stop", file=sys.stderr)
        while True:
            try:
                tick(agent_dir)
            except SystemExit:
                raise
            except Exception as e:  # one bad wake shouldn't kill a persistent agent
                print(f"[mox] tick error: {e}", file=sys.stderr)
            time.sleep(args.every)
    else:
        tick(agent_dir)


if __name__ == "__main__":
    main()
