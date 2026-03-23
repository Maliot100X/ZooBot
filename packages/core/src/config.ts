import fs from 'fs';
import path from 'path';
import { jsonrepair } from 'jsonrepair';
import { Settings, AgentConfig, TeamConfig, MODEL_ALIASES } from './types';

export const SCRIPT_DIR = path.resolve(__dirname, '../../..');
export const ZOOBOT_HOME = process.env.ZOOBOT_HOME
    || process.env.TINYAGI_HOME  // Backwards compatibility
    || path.join(require('os').homedir(), '.zoobot');
export const LOG_FILE = path.join(ZOOBOT_HOME, 'logs/queue.log');
export const SETTINGS_FILE = path.join(ZOOBOT_HOME, 'settings.json');
export const CHATS_DIR = path.join(ZOOBOT_HOME, 'chats');
export const FILES_DIR = path.join(ZOOBOT_HOME, 'files');

// Backwards compatibility aliases
export const TINYAGI_HOME = ZOOBOT_HOME;
export const TINYAGI_CONFIG = SETTINGS_FILE;

export function getSettings(): Settings {
    try {
        const settingsData = fs.readFileSync(SETTINGS_FILE, 'utf8');
        let settings: Settings;

        try {
            settings = JSON.parse(settingsData);
        } catch (parseError) {
            // JSON is invalid — attempt auto-fix with jsonrepair
            console.error(`[WARN] settings.json contains invalid JSON: ${(parseError as Error).message}`);

            try {
                const repaired = jsonrepair(settingsData);
                settings = JSON.parse(repaired);

                // Write the fixed JSON back and create a backup
                const backupPath = SETTINGS_FILE + '.bak';
                fs.copyFileSync(SETTINGS_FILE, backupPath);
                fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2) + '\n');
                console.error(`[WARN] Auto-fixed settings.json (backup: ${backupPath})`);
            } catch {
                console.error(`[ERROR] Could not auto-fix settings.json — returning empty config`);
                return {};
            }
        }

        // Auto-detect provider if not specified
        if (!settings?.models?.provider) {
            if (settings?.models?.openai) {
                if (!settings.models) settings.models = {};
                settings.models.provider = 'openai';
            } else if (settings?.models?.opencode) {
                if (!settings.models) settings.models = {};
                settings.models.provider = 'opencode';
            } else if (settings?.models?.anthropic) {
                if (!settings.models) settings.models = {};
                settings.models.provider = 'anthropic';
            } else if (settings?.models?.groq) {
                if (!settings.models) settings.models = {};
                settings.models.provider = 'groq';
            } else if (settings?.custom_providers) {
                // Check custom providers for groq or openai-compatible
                const providerKeys = Object.keys(settings.custom_providers);
                if (providerKeys.length > 0) {
                    const firstProvider = settings.custom_providers[providerKeys[0]];
                    if (firstProvider.harness === 'groq') {
                        if (!settings.models) settings.models = {};
                        settings.models.provider = 'groq';
                    } else if (firstProvider.harness === 'openai-compatible') {
                        if (!settings.models) settings.models = {};
                        settings.models.provider = 'openai-compatible';
                    }
                }
            }
        }

        return settings;
    } catch {
        return {};
    }
}

/**
 * Build the default agent config from the legacy models section.
 * Used when no agents are configured, for backwards compatibility.
 */
export function getDefaultAgentFromModels(settings: Settings): AgentConfig {
    const provider = settings?.models?.provider || 'anthropic';
    let model = '';
    if (provider === 'openai') {
        model = settings?.models?.openai?.model || 'gpt-4o';
    } else if (provider === 'opencode') {
        model = settings?.models?.opencode?.model || 'sonnet';
    } else if (provider === 'groq') {
        model = settings?.models?.groq?.model || 'llama-3.3-70b-versatile';
    } else if (provider === 'openai-compatible') {
        model = settings?.models?.openai?.model || 'gpt-4o';
    } else {
        model = settings?.models?.anthropic?.model || 'sonnet';
    }

    // Get workspace path from settings or use default
    const workspacePath = settings?.workspace?.path || path.join(require('os').homedir(), 'zoo-bot-workspace');
    const defaultAgentDir = path.join(workspacePath, 'zoobot');

    return {
        name: 'ZooBot Agent',
        provider,
        model,
        working_directory: defaultAgentDir,
    };
}

/**
 * Get all configured agents. Falls back to a single "tinyagi" agent
 * derived from the legacy models section if no agents are configured.
 */
export function getAgents(settings: Settings): Record<string, AgentConfig> {
    if (settings.agents && Object.keys(settings.agents).length > 0) {
        return settings.agents;
    }
    // Fall back to default agent from models section
    return { tinyagi: getDefaultAgentFromModels(settings) };
}

/**
 * Get all configured teams.
 */
export function getTeams(settings: Settings): Record<string, TeamConfig> {
    return settings.teams || {};
}

/**
 * Resolve shorthand model aliases (e.g. 'sonnet' → 'claude-sonnet-4-6').
 * Unknown models pass through as-is to the CLI.
 */
export function resolveModel(model: string, provider: string): string {
    return MODEL_ALIASES[provider]?.[model] || model || '';
}
