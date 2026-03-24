# ZooOffice 🌐

<div align="center">
  <img src="../docs/assets/zoobot-office.png" alt="ZooOffice" width="700" />
</div>

ZooOffice is the web portal for ZooBot — manage agents, teams, tasks, and chat from any browser.

## Features

- **Dashboard** — Real-time queue overview and live event feed
- **Chat Console** — Send messages to any agent or team
- **Agents & Teams** — Create, edit, and remove
- **Kanban Board** — Drag tasks across stages, assign to agents/teams
- **Logs & Events** — Full streaming event log
- **Settings** — Edit ZooBot configuration via UI
- **Office View** — Visual simulation of agent interactions
- **Org Chart** — Hierarchical visualization of teams and agents
- **Chat Rooms** — Slack-style persistent chat rooms per team
- **Projects** — Project-level task management with filtered kanban boards

## Running ZooOffice

```bash
zoobot office   # Starts on http://localhost:3000
```

ZooOffice auto-detects when dependencies or builds are needed and starts the production server.

For development with hot-reload:

```bash
cd zoobot-office
npm install
npm run dev
```

If ZooBot API is on a different host/port:

```bash
cd zoobot-office
echo 'NEXT_PUBLIC_API_URL=http://localhost:3777' > .env.local
```

## Architecture

ZooOffice connects to your local ZooBot API at `http://localhost:3777`. It is a React/Next.js application with:

- **Recharts** — Dashboard charts and event visualization
- **Kanban** — Drag-and-drop task board with stage filtering
- **Agent Cards** — Configuration UI for each agent
- **Team Graph** — D3-based org chart and team visualizer
- **Chat Console** — Real-time messaging interface
- **Log Viewer** — SSE-based streaming log display

## File Structure

```
zoobot-office/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx           # Dashboard
│   │   ├── chat/
│   │   ├── agents/
│   │   ├── teams/
│   │   ├── tasks/             # Kanban board
│   │   ├── logs/
│   │   └── settings/
│   ├── components/
│   │   ├── Dashboard.tsx
│   │   ├── ChatConsole.tsx
│   │   ├── KanbanBoard.tsx
│   │   ├── AgentCard.tsx
│   │   ├── TeamGraph.tsx
│   │   └── LogViewer.tsx
│   └── lib/
│       └── api.ts             # ZooBot API client
├── public/
└── package.json
```

## API

ZooOffice communicates with ZooBot via the REST API at `localhost:3777`:

```bash
GET  /api/status           # System status
GET  /api/agents           # List agents
POST /api/agents            # Create agent
GET  /api/teams            # List teams
POST /api/teams            # Create team
GET  /api/queue            # Queue stats
POST /api/message          # Send message
GET  /api/logs             # Stream logs (SSE)
```

---

Built by [@KaiNovasWarm](https://x.com/KaiNovasWarm) · MIT License
