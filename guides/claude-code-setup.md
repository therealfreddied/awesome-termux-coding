# Claude Code & Custom Provider Setup Guide

Claude Code is Anthropic's official terminal coding agent. By default, it communicates directly with Anthropic's `/v1/messages` endpoint and requires Anthropic API billing.

This guide explains how to pair Claude Code with local companion proxies on Android / Termux so you can route requests to **any model or provider** (DeepSeek, Google Gemini, OpenRouter, Ollama, etc.).

---

## 1. Fast Installation

Install Claude Code natively on Termux (no PRoot, Bionic execution):

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/claude-code.sh | bash
```

Verify your installation:
```bash
claude --version
```

---

## 2. Using Claude Code Router (musistudio)

The cleanest way to route Claude Code to third-party models is using **Claude Code Router**:

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/companions/claude-code-router.sh | bash
```

### Launching the Router
```bash
# Start background router daemon
ccr start

# Or launch the configuration UI in your Android browser
ccr ui
```

### Directing Claude Code to the Router
Add these lines to `~/.bashrc` (or export them before running):
```bash
export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"
export ANTHROPIC_API_KEY="custom-or-mock-key"
```

Now start Claude Code:
```bash
claude
```
All prompts and tool operations will route through `claude-code-router` to your chosen backend.

---

## 3. Direct Provider Routing (Without a Local Proxy)

If you use a gateway that natively implements Anthropic's `/v1/messages` format (such as **OmniRoute** or **OpenRouter**):

### Via OpenRouter
```bash
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_API_KEY="sk-or-v1-..."
claude
```

### Via Local OmniRoute
```bash
export ANTHROPIC_BASE_URL="http://127.0.0.1:20128"
export ANTHROPIC_API_KEY="your-omniroute-token"
claude
```

---

## 4. Useful Claude Code Commands
- `/init` — Analyzes your codebase and creates `CLAUDE.md`.
- `/compact` — Compresses conversation history to preserve context length.
- `/cost` — Displays token consumption and session usage.
