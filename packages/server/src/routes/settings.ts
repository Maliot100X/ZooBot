import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';
import { Hono } from 'hono';
import { Settings } from '@zoobot/core';
import { SETTINGS_FILE, ZOOBOT_HOME, getSettings, ensureAgentDirectory, copyDirSync, SCRIPT_DIR } from '@zoobot/core';
import { log } from '@zoobot/core';

/** Read, mutate, and persist settings.json atomically. */
export function mutateSettings(fn: (settings: Settings) => void): Settings {
    const settings = getSettings();
    fn(settings);
    fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2) + '\n');
    return settings;
}

const app = new Hono();
function detectOpenAiAuth() {
    try {
        const output = execFileSync('codex', ['login', '--help'], {
            encoding: 'utf8',
            stdio: ['ignore', 'pipe', 'ignore'],
            timeout: 5000,
        });
        const authFile = path.join(ZOOBOT_HOME, '..', '.codex', 'auth.json');
        const expanded = path.resolve(authFile.replace('/../', '/'));
        return {
            cli_installed: true,
            auth_file_path: expanded,
            auth_file_exists: fs.existsSync(expanded),
            supports_device_auth: output.includes('--device-auth'),
        };
    } catch {
        const authFile = path.resolve(path.join(ZOOBOT_HOME, '..', '.codex', 'auth.json'));
        return {
            cli_installed: false,
            auth_file_path: authFile,
            auth_file_exists: fs.existsSync(authFile),
            supports_device_auth: false,
        };
    }
}


function expandHomePath(input?: string): string | undefined {
    if (!input) return input;
    const home = process.env.HOME || os.homedir();
    if (!home) return input;
    if (input === '~') return home;
    if (input.startsWith('~/')) return path.join(home, input.slice(2));
    if (input === '$HOME') return home;
    if (input.startsWith('$HOME/')) return path.join(home, input.slice(6));
    return input;
}

// GET /api/provider-auth-state
app.get('/api/provider-auth-state', (c) => {
    const settings = getSettings();
    return c.json({
        openai: {
            configured_api_key: !!settings.models?.openai?.auth_token,
            configured_base_url: settings.models?.openai?.base_url || null,
            codex: detectOpenAiAuth(),
        },
        groq: {
            configured_api_key: !!settings.models?.groq?.auth_token,
            configured_base_url: settings.models?.groq?.base_url || null,
        },
    });
});

// GET /api/settings
app.get('/api/settings', (c) => {
    return c.json(getSettings());
});

// PUT /api/settings
app.put('/api/settings', async (c) => {
    const body = await c.req.json();
    const current = getSettings();
    const merged = { ...current, ...body } as Settings;
    fs.writeFileSync(SETTINGS_FILE, JSON.stringify(merged, null, 2) + '\n');
    log('INFO', '[API] Settings updated');
    return c.json({ ok: true, settings: merged });
});

// POST /api/setup — run initial setup (write settings + create directories)
app.post('/api/setup', async (c) => {
    const settings = (await c.req.json()) as Settings;

    if (settings.workspace?.path) {
        settings.workspace.path = expandHomePath(settings.workspace.path);
    }
    if (settings.agents) {
        for (const agent of Object.values(settings.agents)) {
            if (agent.working_directory) {
                agent.working_directory = expandHomePath(agent.working_directory) || agent.working_directory;
            }
        }
    }

    // Write settings.json
    fs.mkdirSync(path.dirname(SETTINGS_FILE), { recursive: true });
    fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2) + '\n');
    log('INFO', '[API] Setup: settings.json written');

    // Create ZOOBOT_HOME directories
    fs.mkdirSync(path.join(ZOOBOT_HOME, 'logs'), { recursive: true });
    fs.mkdirSync(path.join(ZOOBOT_HOME, 'files'), { recursive: true });

    // Copy template files into ZOOBOT_HOME
    const templateItems = ['.claude', 'heartbeat.md', 'AGENTS.md'];
    for (const item of templateItems) {
        const srcPath = path.join(SCRIPT_DIR, item);
        const destPath = path.join(ZOOBOT_HOME, item);
        if (fs.existsSync(srcPath)) {
            if (fs.statSync(srcPath).isDirectory()) {
                copyDirSync(srcPath, destPath);
            } else {
                fs.copyFileSync(srcPath, destPath);
            }
        }
    }

    // Create workspace directory
    const workspacePath = settings.workspace?.path;
    if (workspacePath) {
        fs.mkdirSync(workspacePath, { recursive: true });
    }

    // Create agent directories
    if (settings.agents) {
        for (const agent of Object.values(settings.agents)) {
            ensureAgentDirectory(agent.working_directory);
        }
    }

    log('INFO', '[API] Setup complete');
    return c.json({ ok: true, settings });
});

export default app;
