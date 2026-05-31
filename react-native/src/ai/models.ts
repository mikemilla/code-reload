export enum AiProvider {
  Anthropic = 'anthropic',
  OpenAI = 'openai',
}

export interface AiModel {
  id: string;
  displayName: string;
  provider: AiProvider;
}

/// Model catalog. The actual streaming runs natively (Swift) now; this is just
/// a convenience map so apps can pass a model to `registerBunbuApp`.
export const AI_MODELS: Record<string, AiModel> = {
  claude4Sonnet: {
    id: 'claude-sonnet-4-20250514',
    displayName: 'Claude 4 Sonnet',
    provider: AiProvider.Anthropic,
  },
  claude4Opus: {
    id: 'claude-opus-4-0-20250514',
    displayName: 'Claude 4 Opus',
    provider: AiProvider.Anthropic,
  },
  gpt4o: {
    id: 'gpt-4o',
    displayName: 'GPT-4o',
    provider: AiProvider.OpenAI,
  },
  gpt4oMini: {
    id: 'gpt-4o-mini',
    displayName: 'GPT-4o Mini',
    provider: AiProvider.OpenAI,
  },
};
