import { refinePromptWithClaude, submitAndPollUdio } from '../_shared/external.ts';
import {
  createAuthedClients,
  deriveTitle,
  handleOptions,
  json,
  sanitizeStringArray,
  sanitizeText,
  toErrorResponse,
} from '../_shared/http.ts';
import { getTierLimits, incrementUsage, touchRateLimit } from '../_shared/quota.ts';

Deno.serve(async (request) => {
  const optionsResponse = handleOptions(request);
  if (optionsResponse) {
    return optionsResponse;
  }

  try {
    const { user, adminClient } = await createAuthedClients(request);
    const payload = await request.json();
    const prompt = sanitizeText(payload.prompt, {
      field: 'prompt',
      maxLength: 500,
    });
    const tags = sanitizeStringArray(payload.tags, {
      field: 'tags',
      maxItems: 10,
      maxItemLength: 32,
    });
    const lyrics = sanitizeText(payload.lyrics, {
      field: 'lyrics',
      maxLength: 8000,
      required: false,
    });

    const profile = await adminClient
      .from('users')
      .select('subscription_tier')
      .eq('id', user.id)
      .single();
    const tier = getTierLimits(profile.data?.subscription_tier);

    await touchRateLimit(adminClient, user.id, tier.requestsPerMinute);

    const refinedPrompt = await refinePromptWithClaude({
      prompt,
      tags,
      lyrics,
      maxTokens: tier.claudeInputTokens,
    });
    const generated = await submitAndPollUdio({ prompt: refinedPrompt });

    const { data: song, error: insertError } = await adminClient
      .from('songs')
      .insert({
        user_id: user.id,
        title: generated.title || deriveTitle(prompt),
        prompt,
        audio_url: generated.audioUrl,
        thumbnail_url: generated.thumbnailUrl,
        genre: tags,
        mood: payload.mood ?? null,
        duration: generated.duration,
        is_public: false,
        content_kind: 'song',
        lyrics_title: lyrics ? deriveTitle(prompt) : null,
        lyrics_language: lyrics ? payload.language ?? 'Both' : null,
      })
      .select()
      .single();

    if (insertError || !song) {
      throw insertError ?? new Error('Failed to save the generated song.');
    }

    try {
      await incrementUsage(adminClient, user.id, 'songs', tier.songs);
    } catch (error) {
      await adminClient.from('songs').delete().eq('id', song.id);
      throw error;
    }

    return json({ song });
  } catch (error) {
    return toErrorResponse(error);
  }
});
