#!/usr/bin/env node
import * as p from '@clack/prompts';
import { readSettings, writeSettings, requireSettings } from './shared.ts';

// --- provider show ---

function providerShow() {
    const settings = requireSettings();
    const provider = settings.models?.provider || 'anthropic';
    const modelSection = (settings.models as Record<string, any>)?.[provider];
    const model = modelSection?.model || '';

    if (model) {
        p.log.info(`Global default: ${provider}/${model}`);
    } else {
        p.log.info(`Global default: ${provider}`);
    }

    const agents = settings.agents || {};
    const agentIds = Object.keys(agents);
    if (agentIds.length > 0) {
        p.log.message('');
        p.log.message('Per-agent models:');
        for (const id of agentIds) {
            p.log.message(`  @${id}: ${agents[id].provider}/${agents[id].model}`);
        }
    }
}

// --- provider set ---

function providerSet(providerName: string, args: string[]) {
    const settings = requireSettings();

    // Parse flags
    let modelArg = '';
    let authTokenArg = '';
    let baseUrlArg = '';
    for (let i = 0; i < args.length; i++) {
        if (args[i] === '--model' && args[i + 1]) {
            modelArg = args[++i];
        } else if (args[i] === '--auth-token' && args[i + 1]) {
            authTokenArg = args[++i];
        } else if (args[i] === '--base-url' && args[i + 1]) {
            baseUrlArg = args[++i];
        }
    }

    // Support anthropic, openai, groq, and custom providers
    if (providerName !== 'anthropic' && providerName !== 'openai' && providerName !== 'groq') {
        p.log.error('Usage: provider {anthropic|openai|groq} [--model MODEL] [--auth-token TOKEN]');
        process.exit(1);
    }

    const oldProvider = settings.models?.provider || 'anthropic';

    if (!settings.models) settings.models = { provider: providerName };
    settings.models.provider = providerName;

    if (modelArg) {
        if (!settings.models[providerName as keyof typeof settings.models]) {
            (settings.models as Record<string, any>)[providerName] = {};
        }
        (settings.models as Record<string, any>)[providerName].model = modelArg;

        // Propagate to agents matching old provider
        const agents = settings.agents || {};
        let updatedCount = 0;
        for (const [, agent] of Object.entries(agents)) {
            if (agent.provider === oldProvider) {
                agent.provider = providerName;
                agent.model = modelArg;
                updatedCount++;
            }
        }

        const providerLabel = providerName === 'anthropic' ? 'Anthropic' : providerName === 'openai' ? 'OpenAI/Codex' : 'Groq';
        p.log.success(`Switched to ${providerLabel} provider with model: ${modelArg}`);
        if (updatedCount > 0) {
            p.log.message(`  Updated ${updatedCount} agent(s) from ${oldProvider} to ${providerName}/${modelArg}`);
        }
    } else {
        const providerLabel = providerName === 'anthropic' ? 'Anthropic' : providerName === 'openai' ? 'OpenAI/Codex' : 'Groq';
        p.log.success(`Switched to ${providerLabel} provider`);
        if (providerName === 'openai') {
            p.log.message("Use 'zoobot model gpt-5.3-codex' to set the model.");
            p.log.message("Note: Make sure you have the 'codex' CLI installed.");
        } else if (providerName === 'groq') {
            p.log.message("Use 'zoobot model llama-3.3-70b-versatile' to set the model.");
            p.log.message("Groq is free and uses OpenAI-compatible API.");
        } else {
            p.log.message("Use 'zoobot model sonnet' or 'zoobot model opus' to set the model.");
        }
    }

    if (authTokenArg) {
        if (!settings.models[providerName as keyof typeof settings.models]) {
            (settings.models as Record<string, any>)[providerName] = {};
        }
        (settings.models as Record<string, any>)[providerName].auth_token = authTokenArg;
        p.log.success(`${providerName === 'anthropic' ? 'Anthropic' : providerName === 'groq' ? 'Groq' : 'OpenAI'} auth token saved`);
    }

    if (baseUrlArg) {
        if (!settings.models[providerName as keyof typeof settings.models]) {
            (settings.models as Record<string, any>)[providerName] = {};
        }
        (settings.models as Record<string, any>)[providerName].base_url = baseUrlArg;
        p.log.success(`Base URL set to: ${baseUrlArg}`);
    }

    writeSettings(settings);
}

// --- model show ---

function modelShow() {
    const settings = requireSettings();
    const provider = settings.models?.provider || 'anthropic';
    const modelSection = (settings.models as Record<string, any>)?.[provider];
    const model = modelSection?.model || '';

    if (model) {
        p.log.info(`Global default: ${provider}/${model}`);
    } else {
        p.log.error('No model configured');
        process.exit(1);
    }

    const agents = settings.agents || {};
    const agentIds = Object.keys(agents);
    if (agentIds.length > 0) {
        p.log.message('');
        p.log.message('Per-agent models:');
        for (const id of agentIds) {
            p.log.message(`  @${id}: ${agents[id].provider}/${agents[id].model}`);
        }
    }
}

// --- model set ---

function modelSet(modelName: string) {
    const settings = requireSettings();

    // Determine provider from model name
    const anthropicModels = ['sonnet', 'opus', 'haiku', 'claude-sonnet-4-6', 'claude-opus-4-6'];
    const openaiModels = ['gpt-5.2', 'gpt-5.3-codex', 'gpt-4o', 'gpt-4o-mini'];
    const groqModels = ['llama-3.3-70b-versatile', 'llama-3.1-70b-versatile', 'mixtral-8x7b-32768', 'llama-3.2-90b-vision-preview', 'llama-3.2-11b-vision-preview', 'gemma2-9b-it'];

    let targetProvider: string;
    if (anthropicModels.includes(modelName)) {
        targetProvider = 'anthropic';
    } else if (openaiModels.includes(modelName)) {
        targetProvider = 'openai';
    } else if (groqModels.includes(modelName)) {
        targetProvider = 'groq';
    } else {
        // Try to detect from prefix
        if (modelName.startsWith('claude-')) {
            targetProvider = 'anthropic';
        } else if (modelName.startsWith('gpt-') || modelName.startsWith('o1') || modelName.startsWith('o3')) {
            targetProvider = 'openai';
        } else if (modelName.startsWith('llama-') || modelName.startsWith('mixtral-') || modelName.startsWith('gemma')) {
            targetProvider = 'groq';
        } else {
            p.log.error('Unknown model. Usage: model {MODEL_NAME}');
            p.log.message('');
            p.log.message('Anthropic models: sonnet, opus, haiku');
            p.log.message('OpenAI models: gpt-4o, gpt-4o-mini, gpt-5.3-codex');
            p.log.message('Groq models: llama-3.3-70b-versatile, mixtral-8x7b-32768, gemma2-9b-it');
            p.log.message('');
            p.log.message('Or use any OpenAI-compatible model with Groq.');
            process.exit(1);
        }
    }

    if (!settings.models) settings.models = { provider: targetProvider };
    const models = settings.models as Record<string, any>;
    if (!models[targetProvider]) models[targetProvider] = {};
    models[targetProvider].model = modelName;

    // Propagate to agents matching the provider
    const agents = settings.agents || {};
    let updatedCount = 0;
    for (const [, agent] of Object.entries(agents)) {
        if (agent.provider === targetProvider) {
            agent.model = modelName;
            updatedCount++;
        }
    }

    writeSettings(settings);

    const providerLabel = targetProvider === 'anthropic' ? 'Anthropic' : targetProvider === 'openai' ? 'OpenAI' : 'Groq';
    p.log.success(`Model switched to: ${modelName} (${providerLabel})`);
    if (updatedCount > 0) {
        p.log.message(`  Updated ${updatedCount} ${targetProvider} agent(s)`);
    }
    p.log.message('');
    p.log.message('Note: Changes take effect on next message.');
}

// --- CLI dispatch ---

const command = process.argv[2];
const args = process.argv.slice(3);

switch (command) {
    case 'show':
    case undefined:
        providerShow();
        break;
    case 'anthropic':
    case 'openai':
    case 'groq':
        providerSet(command, args);
        break;
    case 'model':
        if (!args[0]) {
            modelShow();
        } else {
            modelSet(args[0]);
        }
        break;
    default:
        p.log.error(`Unknown provider command: ${command}`);
        p.log.message('Usage: provider {show|anthropic|openai|groq} [--model MODEL] [--auth-token TOKEN]');
        p.log.message('       provider model [name]');
        process.exit(1);
}
