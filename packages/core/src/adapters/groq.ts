import { AgentAdapter, InvokeOptions } from './types';
import { log } from '../logging';

/**
 * Direct Groq API adapter - no CLI required.
 * Supports llama-3.3-70b-versatile, llama-3.1-8b-instant, mixtral-8x7b-32768, etc.
 */
export const groqAdapter: AgentAdapter = {
    providers: ['groq'],
    async invoke(options: InvokeOptions): Promise<string> {
        const { message, systemPrompt, model = 'llama-3.3-70b-versatile', onEvent } = options;

        // Get API key from GROQ_API_KEY env var
        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) {
            throw new Error('GROQ_API_KEY environment variable is not set');
        }

        const url = 'https://api.groq.com/openai/v1/chat/completions';
        const headers: Record<string, string> = {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
        };

        const body: Record<string, unknown> = {
            model,
            messages: [
                ...(systemPrompt ? [{ role: 'system', content: systemPrompt }] : []),
                { role: 'user', content: message },
            ],
            stream: !!onEvent,
        };

        if (onEvent) {
            headers['Accept'] = 'text/event-stream';
        }

        const response = await fetch(url, {
            method: 'POST',
            headers,
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            const error = await response.text();
            throw new Error(`Groq API error ${response.status}: ${error}`);
        }

        if (onEvent) {
            const reader = response.body?.getReader();
            if (!reader) throw new Error('No response body');

            const decoder = new TextDecoder();
            let buffer = '';

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                buffer += decoder.decode(value, { stream: true });
                const lines = buffer.split('\n');
                buffer = lines.pop() || '';

                for (const line of lines) {
                    if (line.startsWith('data: ')) {
                        const data = line.slice(6);
                        if (data === '[DONE]') {
                            onEvent('[DONE]');
                        } else {
                            try {
                                const parsed = JSON.parse(data);
                                const content = parsed.choices?.[0]?.delta?.content;
                                if (content) onEvent(content);
                            } catch {}
                        }
                    }
                }
            }

            return '';
        }

        const data = await response.json() as { choices?: { message?: { content?: string } }[] };
        return data.choices?.[0]?.message?.content || 'Sorry, I could not generate a response from Groq.';
    },
};
