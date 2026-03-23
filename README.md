# ZooBot 🤖

**Open Source AI Agent Framework — Run free AI agents locally with any LLM provider**

[![GitHub Stars](https://img.shields.io/github/stars/zo-computer/ZooBot?style=social)](https://github.com/zo-computer/ZooBot)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)

---

## 🎯 What is ZooBot?

ZooBot is a powerful, open-source AI agent orchestration framework that lets you run multiple AI agents in parallel — each with their own workspace, memory, and personality. It's designed for individuals and small teams who want the power of multi-agent AI systems **without being locked into expensive proprietary services**.

Think of it as a **personal AI office** where you can hire specialized agents (coder, writer, reviewer, researcher) that work together on your projects.

### ✨ Key Features

- **🤖 Multi-Agent Teams** — Create agent teams that collaborate and hand off tasks
- **💬 Channel Integration** — Connect to Discord, Telegram, WhatsApp, and Web
- **🧠 Memory System** — Persistent hierarchical memory for each agent
- **📋 Skills System** — Extensible skill framework (browser automation, image generation, scheduling)
- **🔄 Queue-Based Processing** — SQLite-backed message queue with retry logic
- **🎨 TinyOffice Visual Dashboard** — Web portal for visual agent management
- **🔌 Plugin Architecture** — Easy to extend with custom functionality
- **💰 Free LLM Support** — Use Groq, OpenAI-compatible APIs, Anthropic, or Codex

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ 
- npm or yarn
- API keys for your preferred LLM provider (see below)

### Installation

```bash
# Clone the repository
git clone https://github.com/zo-computer/ZooBot.git
cd ZooBot

# Install dependencies
npm install

# Initialize configuration
npm run setup
```

### Configuration

Create `~/.zoobot/settings.json` (or set environment variables):

```json
{
  "workspace": {
    "path": "~/zoo-bot-workspace"
  },
  "models": {
    "provider": "groq",
    "groq": {
      "model": "llama-3.3-70b-versatile"
    }
  },
  "GROQ_API_KEY": "your-groq-api-key-here",
  "agents": {
    "assistant": {
      "name": "ZooBot Assistant",
      "provider": "groq",
      "model": "llama-3.3-70b-versatile",
      "working_directory": "~/zoo-bot-workspace/assistant",
      "system_prompt": "You are a helpful AI assistant."
    }
  }
}
```

Or use environment variables:

```bash
export GROQ_API_KEY="your-groq-api-key"
export ZOOBOT_PROVIDER="groq"
export ZOOBOT_MODEL="llama-3.3-70b-versatile"
```

---

## 💰 Supported LLM Providers

### Free Tier Providers ⭐

| Provider | Models | Cost | Speed |
|----------|--------|------|-------|
| **Groq** | Llama 3.1/3.2/3.3, Mixtral | FREE | ⚡⚡⚡ Very Fast |
| **OpenRouter** | replit, microsoft, quantummodels | FREE tier available | Fast |
| **Cerebras** | Llama 3.1 8B, 70B | Free credits | ⚡⚡⚡ Very Fast |

### Paid Providers

| Provider | Notes |
|----------|-------|
| Anthropic Claude | Uses Claude Code CLI |
| OpenAI | Uses Codex CLI |
| OpenCode | Uses OpenCode CLI |

---

## 📖 Documentation

- [Installation Guide](docs/INSTALL.md)
- [Agent Configuration](docs/AGENTS.md)
- [Team Collaboration](docs/TEAMS.md)
- [Channel Setup (Discord, Telegram, etc.)](docs/PLUGINS.md)
- [Message Patterns](docs/MESSAGE-PATTERNS.md)
- [Queue System](docs/QUEUE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

## 🛠️ Usage

### Single Agent Mode

```bash
# Start interactive chat with your agent
npm run chat

# Run a single command
npm run agent -- "Hello, help me write a Python script"
```

### Team Mode

```bash
# Create a team of agents
zoobot team create dev "coder,reviewer,tester"

# Send task to team
zoobot team message dev "Build a REST API for task management"
```

### Channel Mode

```bash
# Start Telegram bot
npm run telegram

# Start Discord bot  
npm run discord
```

### Web Dashboard (TinyOffice)

```bash
# Start TinyOffice web interface
npm run visualizer
```

---

## 🧩 Skills

ZooBot comes with built-in skills:

| Skill | Description |
|-------|-------------|
| `agent-browser` | Automate web browsers |
| `imagegen` | Generate images via AI |
| `memory` | Persistent memory management |
| `schedule` | Schedule tasks with cron |
| `tasks` | Task management |
| `skill-creator` | Create new skills |

---

## 🔧 API Reference

### Environment Variables

| Variable | Description |
|----------|-------------|
| `GROQ_API_KEY` | Your Groq API key |
| `OPENAI_API_KEY` | Your OpenAI API key |
| `ANTHROPIC_AUTH_TOKEN` | Your Anthropic auth token |
| `ZOOBOT_HOME` | Config directory (default: `~/.zoobot`) |
| `ZOOBOT_WORKSPACE` | Workspace directory |

### Programmatic Usage

```typescript
import { ZooBot } from '@zoobot/core';

const bot = new ZooBot({
  provider: 'groq',
  model: 'llama-3.3-70b-versatile',
  apiKey: process.env.GROQ_API_KEY
});

const response = await bot.invoke({
  agentId: 'assistant',
  message: 'Hello!'
});
```

---

## 🎨 Brand Assets

![ZooBot Logo](docs/assets/zoobot-logo.png)

Logo and brand assets are available in [`docs/assets/`](docs/assets/).

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

ZooBot is based on [TinyAGI](https://github.com/TinyAGI/TinyAGI) by TinyAGI contributors. We've extended it with direct API support for free LLM providers and additional features.

---

<p align="center">
  <strong>ZooBot</strong> — Your personal AI agent team, running free in the cloud ☁️
</p>
