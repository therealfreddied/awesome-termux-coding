# OpenCode v1 vs v2 Side-by-Side Guide

This guide covers running **OpenCode v1.x** (Classic) and **OpenCode v2.x** (Modern) concurrently on Android via Termux without file collisions.

---

## 1. Why Two Versions?

* **OpenCode 1.x:** Powered by a customized native Bun 1.2.13 build with WebKit/JavaScriptCore. Extremely stable, battle-tested terminal coding agent.
* **OpenCode 2.x:** Built on Bun 1.4.2 Android target and OpenTUI 0.5.10. Offers the next-generation interface, improved streaming, and enhanced tool-calling capabilities.

Both packages are designed to install and run **side-by-side**. Installing v2 never overwrites or alters your v1 setup.

---

## 2. Installation Commands

### Install OpenCode 1.x (Command: `opencode`)
```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/opencode-v1.sh | bash
```

### Install OpenCode 2.x (Command: `opencode2`)
```bash
curl -fsSL https://raw.githubusercontent.com/therealfreddied/awesome-termux-coding/main/install/harnesses/opencode-v2.sh | bash
```

---

## 3. Configuration & API Providers

Both versions look for standard environment variables:

### Anthropic Claude
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

### OpenAI / OpenRouter
```bash
export OPENAI_API_KEY="sk-..."
export OPENAI_BASE_URL="https://api.openai.com/v1" # or custom proxy
```

### DeepSeek
```bash
export OPENAI_API_KEY="sk-..."
export OPENAI_BASE_URL="https://api.deepseek.com/v1"
```

---

## 4. Running the Tools

* To start version 1:
  ```bash
  opencode
  ```
* To start version 2:
  ```bash
  opencode2
  ```
