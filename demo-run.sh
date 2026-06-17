#!/usr/bin/env bash
# demo-run.sh — watch a Mox-Framework agent wake, think, and act, with your own eyes.
#
# Works against ANY OpenAI-compatible endpoint (self-hosted llama.cpp/vLLM/Ollama/
# LiteLLM, or a hosted provider). Point it at yours:
#
#   export MOX_LLM_BASE_URL="http://localhost:8080/v1"   # your endpoint
#   export MOX_LLM_API_KEY="sk-..."                       # its key (or "none")
#   export MOX_LLM_MODEL="gpt-oss-120b"                   # any model the endpoint serves
#
# …or copy config.example.env -> config.env and fill it in (config.env is gitignored).
set -euo pipefail
cd "$(dirname "$0")"

# Load local config if present (gitignored).
[ -f config.env ] && { set -a; . ./config.env; set +a; }

: "${MOX_LLM_BASE_URL:?set MOX_LLM_BASE_URL to your OpenAI-compatible endpoint (see top of this file)}"
: "${MOX_LLM_API_KEY:?set MOX_LLM_API_KEY (use \"none\" if your endpoint needs no key)}"
: "${MOX_LLM_MODEL:=gpt-oss-120b}"
export MOX_LLM_BASE_URL MOX_LLM_API_KEY MOX_LLM_MODEL

AGENT="agents/herald"
if [ ! -d "$AGENT" ]; then
  echo "==> spawning a fresh agent so you watch the whole flow…"
  ./bin/spawn-agent herald "announces what the cohort shipped today, in one short note"
fi

echo ""
echo "================  WAKE  (model: $MOX_LLM_MODEL)  ================"
python3 runtime/mox_agent.py --agent "$AGENT" --once
echo ""
echo "================  WHAT IT WROTE TO DISK  ================"
echo "--- $AGENT/Tasks.md ---";   cat "$AGENT/Tasks.md"
echo ""; echo "--- $AGENT/journal/ ---"; cat "$AGENT"/journal/*.md 2>/dev/null
echo ""
echo "Run it again to see continuity — it reads the state above on the next wake."
