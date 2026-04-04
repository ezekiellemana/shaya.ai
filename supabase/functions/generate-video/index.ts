import { submitAndPollKling } from '../_shared/external.ts';
import {
  createAuthedClients,
  handleOptions,
  json,
  sanitizeText,
  toErrorResponse,
  HttpError,
} from '../_shared/http.ts';
import {
  assertVideoQualityAllowed,
  getTierLimits,
  incrementUsage,
  touchRateLimit,
} from '../_shared/quota.ts';

Deno.serve(async (request) => {
  const optionsResponse = handleOptions(request);
  if (optionsResponse) {
    return optionsResponse;
  }

  try {
    const { user, adminClient } = await createAuthedClients(request);
    const payload = await request.json();
    const songId = sanitizeText(payload.song_id, {
      field: 'song_id',
      maxLength: 64,
    });
    const visualPrompt = sanitizeText(payload.visual_prompt, {
      field: 'visual_prompt',
      maxLength: 300,
    });
    const quality = sanitizeText(payload.quality, {
      field: 'quality',
      maxLength: 10,
    });

    const profile = await adminClient
      .from('users')
      .select('subscription_tier')
      .eq('id', user.id)
      .single();
    const tier = getTierLimits(profile.data?.subscription_tier);
    assertVideoQualityAllowed(tier, quality);
    await touchRateLimit(adminClient, user.id, tier.requestsPerMinute);

    const { data: song, error: songError } = await adminClient
      .from('songs')
      .select('*')
      .eq('id', songId)
      .eq('user_id', user.id)
      .single();

    if (songError || !song) {
      throw new HttpError(404, 'Song not found.');
    }

    const result = await submitAndPollKling({
      prompt: `${song.title}. ${visualPrompt}`,
      quality,
    });

    const { data: updatedSong, error: updateError } = await adminClient
      .from('songs')
      .update({
        video_url: result.videoUrl,
      })
      .eq('id', songId)
      .eq('user_id', user.id)
      .select()
      .single();

    if (updateError || !updatedSong) {
      throw updateError ?? new Error('Failed to save the generated video.');
    }

    try {
      await incrementUsage(adminClient, user.id, 'videos', tier.videos);
    } catch (error) {
      await adminClient
        .from('songs')
        .update({ video_url: null })
        .eq('id', songId)
        .eq('user_id', user.id);
      throw error;
    }

    return json({ song: updatedSong });
  } catch (error) {
    return toErrorResponse(error);
  }
});
