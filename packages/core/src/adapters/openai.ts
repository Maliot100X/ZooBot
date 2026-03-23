import { AgentAdapter, InvokeOptions } from './types';
import { log } from '../logging';

/**
 * OpenAI-Compatible API adapter - works with any LLM provider
 * that follows OpenAI's chat completions API format.
 * 
 * Supports: Groq, Together, Perplexity, Hyperbolic, and any other
 * OpenAI-compatible endpoint.
 */
export const openaiAdapter: AgentAdapter = {
    providers: ['openai', 'openai-compatible'],

    async invoke(opts: InvokeOptions): Promise<string> {
        const { agentId, message, systemPrompt, model, onEvent, envOverrides } = opts;
        log('DEBUG', `Using OpenAI-compatible provider (agent: ${agentId}, model: ${model})`);

        const apiKey = envOverrides?.OPENAI_API_KEY || process.env.OPENAI_API_KEY;
        const baseUrl = envOverrides?.OPENAI_BASE_URL || process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1';

        if (!apiKey) {
            throw new Error('OPENAI_API_KEY environment variable is not set');
        }

        const endpoint = `${baseUrl}/chat/completions`;
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: model || 'gpt-4o',
                messages: [
                    ...(systemPrompt ? [{ role: 'system', content: systemPrompt }] : []),
                    { role: 'user', content: message },
                ],
                stream: !!onEvent,
            }),
        });

        if (!response.ok) {
            const error = await response.text();
            throw new Error(`OpenAI-compatible API error: ${response.status} - ${error}`);
        }

        if (onEvent) {
            // Streaming mode
            const reader = (response.body as ReadableStream<Uint8Array>).getReader();
            const decoder = new TextDecoder();
            let fullContent = '';

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                const chunk = decoder.decode(value);
                const lines = chunk.split('\n');

                for (const line of lines) {
                    if (line.startsWith('data: ')) {
                        const data = line.slice(6);
                        if (data === '[DONE]') continue;

                        try {
                            const json = JSON.parse(data);
                            const content = json.choices?.[0]?.delta?.content;
                            if (content) {
                                fullContent += content;
                                onEvent(content);
                            }
                        } catch {
                            // Ignore parse errors for incomplete chunks
                        }
                    }
                }
            }

            return fullContent || 'Sorry, I could not generate a response.';
        }

        // Non-streaming mode
        const data = await response.json();
        return data.choices?.[0]?.message?.content || 'Sorry, I could not generate a response.';
    },
};
