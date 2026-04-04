import {
  createAuthedClients,
  deriveTitle,
  handleOptions,
  HttpError,
  json,
  requiredEnv,
  sanitizeText,
  toErrorResponse,
} from '../_shared/http.ts';
import { getTierLimits, incrementUsage, touchRateLimit } from '../_shared/quota.ts';

type LyricSection = {
  heading: string;
  content: string;
};

Deno.serve(async (request) => {
  const optionsResponse = handleOptions(request);
  if (optionsResponse) {
    return optionsResponse;
  }

  try {
    const { user, adminClient } = await createAuthedClients(request);
    const payload = await request.json();
    const mode = sanitizeText(payload.mode ?? 'generate', {
      field: 'mode',
      maxLength: 40,
    });

    const profile = await adminClient
      .from('users')
      .select('subscription_tier')
      .eq('id', user.id)
      .single();
    const tier = getTierLimits(profile.data?.subscription_tier);
    await touchRateLimit(adminClient, user.id, tier.requestsPerMinute);

    const lyrics = await requestLyricsFromClaude(payload, mode, tier.claudeInputTokens);

    let savedSong: Record<string, unknown> | null = null;
    if (mode === 'generate') {
      const { data, error } = await adminClient
        .from('songs')
        .insert({
          user_id: user.id,
          title: lyrics.title,
          prompt: sanitizeText(payload.topic, { field: 'topic', maxLength: 160 }),
          audio_url: '',
          thumbnail_url: '',
          genre: [],
          mood: payload.mood ?? null,
          duration: 0,
          is_public: false,
          content_kind: 'lyrics',
          lyrics_title: lyrics.title,
          lyrics_language: lyrics.language,
          lyrics_sections: lyrics.sections,
        })
        .select()
        .single();

      if (error || !data) {
        throw error ?? new Error('Failed to save generated lyrics.');
      }
      savedSong = data;
    }

    try {
      await incrementUsage(adminClient, user.id, 'lyrics', tier.lyrics);
    } catch (error) {
      if (savedSong?.id) {
        await adminClient.from('songs').delete().eq('id', savedSong.id as string);
      }
      throw error;
    }

    return json({
      title: lyrics.title,
      language: lyrics.language,
      sections: lyrics.sections,
      ...(savedSong != null ? { song: savedSong } : {}),
    });
  } catch (error) {
    return toErrorResponse(error);
  }
});

async function requestLyricsFromClaude(
  payload: Record<string, unknown>,
  mode: string,
  maxTokens: number,
): Promise<{ title: string; language: string; sections: LyricSection[] }> {
  const apiKey = requiredEnv('ANTHROPIC_API_KEY');
  const model = Deno.env.get('ANTHROPIC_MODEL') ?? 'claude-3-5-haiku-latest';

  const prompt = buildLyricsPrompt(payload, mode, maxTokens);
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model,
      max_tokens: 700,
      system:
        'Return valid JSON only. Format: {"title":"...","language":"English|Swahili|Both","sections":[{"heading":"Verse 1","content":"..."}, ...]}.',
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new HttpError(500, 'Claude lyrics generation failed.', data);
  }

  const rawJson = data?.content?.[0]?.text;
  if (typeof rawJson !== 'string') {
    throw new HttpError(500, 'Claude did not return structured lyrics.');
  }

  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(rawJson);
  } catch (error) {
    throw new HttpError(500, 'Claude response was not valid JSON.', error);
  }

  const sections = Array.isArray(parsed.sections)
    ? parsed.sections.map((section) => ({
        heading: sanitizeText((section as Record<string, unknown>).heading, {
          field: 'heading',
          maxLength: 60,
        }),
        content: sanitizeText((section as Record<string, unknown>).content, {
          field: 'content',
          maxLength: 1200,
        }),
      }))
    : [];

  if (sections.length === 0) {
    throw new HttpError(500, 'No lyric sections were returned.');
  }

  return {
    title: sanitizeText(parsed.title ?? deriveTitle(prompt), {
      field: 'title',
      maxLength: 80,
    }),
    language: sanitizeText(parsed.language ?? 'English', {
      field: 'language',
      maxLength: 24,
    }),
    sections,
  };
}

function buildLyricsPrompt(
  payload: Record<string, unknown>,
  mode: string,
  maxTokens: number,
) {
  if (mode === 'improve_section') {
    return [
      `Improve one section inside this song while keeping the other sections consistent. Stay under ${maxTokens} input tokens.`,
      `Title: ${payload.title ?? 'Untitled'}`,
      `Language: ${payload.language ?? 'English'}`,
      `Target section index: ${payload.target_index ?? 0}`,
      `Sections: ${JSON.stringify(payload.sections ?? [])}`,
    ].join('\n');
  }

  if (mode === 'translate') {
    return [
      `Translate this full song while preserving structure. Stay under ${maxTokens} input tokens.`,
      `Title: ${payload.title ?? 'Untitled'}`,
      `Language: ${payload.language ?? 'English'}`,
      `Sections: ${JSON.stringify(payload.sections ?? [])}`,
    ].join('\n');
  }

  return [
    `Write a complete structured song with Title, Verse 1, Pre-Chorus, Chorus, Verse 2, Bridge, and Outro. Stay under ${maxTokens} input tokens.`,
    `Topic: ${sanitizeText(payload.topic, { field: 'topic', maxLength: 160 })}`,
    `Mood: ${sanitizeText(payload.mood, { field: 'mood', maxLength: 80 })}`,
    `Language: ${sanitizeText(payload.language, { field: 'language', maxLength: 24 })}`,
    `Keep the language natural for Tanzanian creators and radio-ready phrasing.`,
  ].join('\n');
}
