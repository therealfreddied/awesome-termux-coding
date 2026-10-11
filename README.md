# ⚡ Awesome Termux Coding

<p align="center">
  <b>The curated guide and 1-shot native installers for AI coding harnesses, companion proxies, and routers on Android (Termux aarch64).</b><br/>
  <i>Zero PRoot overhead. Zero container bloat. Pure native Bionic execution.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Termux-brightgreen?style=flat-square&logo=android" alt="Platform" />
  <img src="https://img.shields.io/badge/Architecture-aarch64%20(Bionic)-blue?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/PRoot-Zero%20Overhead-success?style=flat-square" alt="PRoot Free" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="License" />
</p>

---

## 🎯 Why This Repo Exists

Most AI coding harnesses assume a desktop Linux or macOS machine with glibc and Docker. Running them in Termux via PRoot adds massive memory overhead, severe filesystem latency, and battery drain.

This repository provides **1-shot native installers** that execute directly on Android Bionic libc. Every script auto-detects dependencies, patches shebangs (`termux-fix-shebang`), and gives you copy-paste commands ready for your YouTube videos, mobile workflows, or daily terminal hacking.

---

## 📑 Table of Contents

- [🌟 Primary Coding Harnesses](#-primary-coding-harnesses)
  - [Claude Code (Anthropic)](#1-claude-code-anthropic)
  - [OpenAI Codex CLI](#2-openai-codex-cli)
  - [Google Antigravity CLI (agy)](#3-google-antigravity-cli-agy)
  - [OpenCode v1 & v2 (Side-by-Side)](#4-opencode-v1--v2-side-by-side)
  - [OpenClaude](#5-openclaude)
  - [DeepSeek Harness (dsh)](#6-deepseek-harness-dsh)
  - [Kiro / Kilo CLI](#7-kiro--kilo-cli)
- [🧩 Companion Tools & Proxies](#-companion-tools--proxies)
  - [Claude Code Router (Use ANY Model)](#claude-code-router)
  - [OpenCodex (Use Any Provider in Codex)](#opencodex)
  - [Antigravity Custom Models Wrapper](#antigravity-custom-models-wrapper)
  - [Free Claude Code (Free Tier Booster)](#free-claude-code-booster)
- [🔀 Local Routers & Gateways](#-local-routers--gateways)
  - [OmniRoute (Native Lite)](#omniroute)
  - [9router (Low RAM Gateway)](#9router)
  - [CLI Proxy API](#cli-proxy-api)
- [⚡ Termux Pro Tips & Performance](#-termux-pro-tips--performance)

---

## 🌟 Primary Coding Harnesses

### 1. Claude Code (Anthropic)
The official autonomous terminal coding agent from Anthropic, running natively on Android.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/claude-code.sh | bash
```

* **Launch:** `claude`
* **Optional Companion Tools:**
  * **[Claude Code Router](#claude-code-router):** Connect Claude Code to DeepSeek, Gemini, or OpenRouter instead of official Anthropic billing.
  * **[Free Tier Booster](#free-claude-code-booster):** Tap into 60+ free model providers with 1B+ monthly tokens.

---

### 2. OpenAI Codex CLI
OpenAI's autonomous coding CLI adapted for native Bionic execution.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/codex.sh | bash
```

* **Launch:** `codex`
* **Optional Companion Tools:**
  * **[OpenCodex](#opencodex):** Route Codex requests to any LLM provider (Claude, Gemini, DeepSeek, Ollama).

---

### 3. Google Antigravity CLI (`agy`)
Google's next-gen autonomous agent CLI for high-throughput code manipulation.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/antigravity.sh | bash
```

* **Launch:** `agy` or `antigravity`
* **Companion Engine:** Includes built-in agent-context injection so you can toggle between Gemini, Claude, and local Ollama models.

---

### 4. OpenCode v1 & v2 (Side-by-Side)
Terminal AI assistant compiled natively for Android aarch64. **v1 and v2 install side-by-side** without file conflicts!

#### OpenCode v1.x (Classic Edition)
```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/opencode-v1.sh | bash
```
* **Launch:** `opencode`

#### OpenCode v2.x (Modern Edition)
```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/opencode-v2.sh | bash
```
* **Launch:** `opencode2`

---

### 5. OpenClaude
Universal open-source coding agent CLI supporting OpenAI-compatible endpoints, Gemini, Codex OAuth, Ollama, and full streaming tool-use.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/openclaude.sh | bash
```

* **Launch:** `openclaude`

---

### 6. DeepSeek Harness (`dsh`)
Native client and harness built specifically for DeepSeek V3 and R1 reasoning models with real-time streaming and thinking-block toggling.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/deepseek.sh | bash
```

* **Launch:** `dsh`

---

### 7. Kiro / Kilo CLI
Fast, native terminal coding tool with precompiled ARM64 execution.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/kiro.sh | bash
```

* **Launch:** `kiro` (or `kilo`)

---

## 🧩 Companion Tools & Proxies

Companion tools extend your harnesses so you aren't locked into a single API vendor.

### Claude Code Router
A pure TypeScript/Node routing proxy (`musistudio/claude-code-router`). Translates Claude Code's native `/v1/messages` calls into OpenAI-compatible format, allowing Claude Code to run against **DeepSeek, Gemini, OpenRouter, or local Ollama**.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/companions/claude-code-router.sh | bash
```

* **Start the daemon:** `ccr start`
* **Web UI Dashboard:** `ccr ui`
* **Connect Claude Code:**
  ```bash
  export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"
  claude
  ```

---

### OpenCodex
Universal provider proxy for OpenAI Codex CLI (`lidge-jun/opencodex`). Allows Codex to route through Claude, Gemini, DeepSeek, Grok, or self-hosted models.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/companions/opencodex.sh | bash
```

* **Launch / Configure:** `ocx`

---

### Antigravity Custom Models Wrapper
Community wrapper for `agy` (`kelvinzer0/antigravity-cli`) that injects Antigravity's system context into third-party models so they understand internal tool calls.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/companions/agy-free-wrapper.sh | bash
```

* **Configure Provider:** `agy --provider openrouter --api-key <YOUR_KEY>`

---

### Free Claude Code Booster
Free-tier orchestrator (`Alishahryar1/free-claude-code`) giving Claude Code, Codex, and OpenCode access to over 60 ToS-friendly free model endpoints.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/companions/free-claude-code.sh | bash
```

* **Start server:** `fcc-server`

---

## 🔀 Local Routers & Gateways

Want full control of your local API keys, rate limits, and model failovers right on your phone?

### OmniRoute
Native lightweight backend for OmniRoute. Acts as a unified OpenAI/Anthropic/Gemini gateway on port `20128`.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/routers/omniroute.sh | bash
```

* **Run:** `omniroute`
* **Endpoint:** `http://127.0.0.1:20128/v1`

---

### 9router
Ultra-lightweight AI proxy daemon designed for extreme low-memory Android environments.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/routers/9router.sh | bash
```

* **Run:** `9router start`

---

### CLI Proxy API
Single compiled binary proxy translating CLI requests directly to target endpoints.

```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/routers/cliproxyapi.sh | bash
```

* **Run:** `cli-proxy-api`

---

## ⚡ Termux Pro Tips & Performance

1. **Keep Termux Awake (Wakelock):**
   Prevent Android from killing long agent sessions in the background:
   ```bash
   termux-wake-lock
   ```
2. **Increase Swap / Memory Headroom:**
   If running heavy TypeScript builds or local proxies, configure zram or Termux swap:
   ```bash
   pkg install -y zram-tools
   ```
3. **Storage Access:**
   Allow harnesses to edit code in your phone's shared storage:
   ```bash
   termux-setup-storage
   ```

---

## 🤝 Contributing & Updates

Have another great harness or Termux companion tool? Pull requests and recipe submissions are welcome!

```bash
# Test any installer locally before submitting
bash install/harnesses/<tool>.sh
```

Licensed under [MIT](LICENSE).
