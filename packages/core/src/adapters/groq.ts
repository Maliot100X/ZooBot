import { AgentAdapter, InvokeOptions } from './types';
import { log } from '../logging';

/**
 * Direct Groq API adapter - no CLI required.
 * Uses the Groq SDK for OpenAI-compatible API calls.
 */
export const groqAdapter: AgentAdapter = {
    providers: ['groq'],

    async invoke(opts: InvokeOptions): Promise<string> {
        const { agentId, message, systemPrompt, model, onEvent } = opts;
        log('DEBUG', `Using Groq provider (agent: ${agentId}, model: ${model})`);

        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) {
            throw new Error('GROQ_API_KEY environment variable is not set');
        }

        const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: model || 'llama-3.3-70b-versatile',
                messages: [
                    ...(systemPrompt ? [{ role: 'system', content: systemPrompt }] : []),
                    { role: 'user', content: message },
                ],
                stream: !!onEvent,
            }),
        });

        if (!response.ok) {
            const error = await response.text();
            throw new Error(`Groq API error: ${response.status} - ${error}`);
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

            return fullContent || 'Sorry, I could not generate a response from Groq.';
        }

        // Non-streaming mode
        const data = await response.json();
        return data.choices?.[0]?.message?.content || 'Sorry, I could not generate a response from Groq.';
    },
};
