import { HttpError, deriveTitle, requiredEnv } from './http.ts';

export async function refinePromptWithClaude({
  prompt,
  tags,
  lyrics,
  maxTokens,
}: {
  prompt: string;
  tags: string[];
  lyrics?: string;
  maxTokens: number;
}): Promise<string> {
  const apiKey = requiredEnv('ANTHROPIC_API_KEY');
  const model = Deno.env.get('ANTHROPIC_MODEL') ?? 'claude-3-5-haiku-latest';

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model,
      max_tokens: 256,
      system:
        `Rewrite the request into a concise music-generation prompt. ` +
        `Stay under ${maxTokens} input tokens. Preserve English or Swahili wording.`,
      messages: [
        {
          role: 'user',
          content:
            `Prompt: ${prompt}\n` +
            `Tags: ${tags.join(', ')}\n` +
            `Lyrics: ${lyrics ?? 'N/A'}\n` +
            'Return only the refined prompt.',
        },
      ],
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new HttpError(500, 'Claude refinement failed.', payload);
  }

  const text = payload?.content?.[0]?.text;
  if (typeof text !== 'string' || text.trim().length === 0) {
    throw new HttpError(500, 'Claude returned an empty refinement.');
  }
  return text.trim();
}

export async function submitAndPollUdio({
  prompt,
}: {
  prompt: string;
}): Promise<{
  title: string;
  audioUrl: string;
  thumbnailUrl: string;
  duration: number;
}> {
  const apiKey = requiredEnv('UDIO_API_KEY');

  const submitResponse = await fetch('https://udioapi.pro/api/generate', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ prompt }),
  });

  const submitPayload = await submitResponse.json();
  if (!submitResponse.ok) {
    throw new HttpError(500, 'udioapi.pro generation failed.', submitPayload);
  }

  const jobId = submitPayload.id ?? submitPayload.job_id;
  if (!jobId) {
    throw new HttpError(500, 'udioapi.pro did not return a job id.', submitPayload);
  }

  for (let attempt = 0; attempt < 24; attempt += 1) {
    const statusResponse = await fetch(`https://udioapi.pro/api/status/${jobId}`, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
      },
    });
    const statusPayload = await statusResponse.json();

    if (!statusResponse.ok) {
      throw new HttpError(500, 'udioapi.pro polling failed.', statusPayload);
    }

    const status = String(statusPayload.status ?? '').toLowerCase();
    const audioUrl = statusPayload.audio_url ?? statusPayload.url;
    if ((status === 'completed' || status === 'success') && typeof audioUrl === 'string') {
      return {
        title: statusPayload.title ?? deriveTitle(prompt),
        audioUrl,
        thumbnailUrl: statusPayload.thumbnail_url ?? '',
        duration: Number(statusPayload.duration ?? 0),
      };
    }

    if (status === 'failed' || status === 'error') {
      throw new HttpError(500, 'udioapi.pro reported a failed generation.', statusPayload);
    }

    await delay(5000);
  }

  throw new HttpError(500, 'udioapi.pro timed out before the song was ready.');
}

export async function submitAndPollKling({
  prompt,
  quality,
}: {
  prompt: string;
  quality: string;
}): Promise<{ videoUrl: string }> {
  const apiKey = requiredEnv('KLING_API_KEY');

  const submitResponse = await fetch('https://api.klingai.com/v1/videos/image2video', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt,
      quality,
    }),
  });

  const submitPayload = await submitResponse.json();
  if (!submitResponse.ok) {
    throw new HttpError(500, 'Kling AI generation failed.', submitPayload);
  }

  const jobId = submitPayload.id ?? submitPayload.job_id;
  if (!jobId) {
    throw new HttpError(500, 'Kling AI did not return a job id.', submitPayload);
  }

  for (let attempt = 0; attempt < 40; attempt += 1) {
    const statusResponse = await fetch(`https://api.klingai.com/v1/videos/${jobId}`, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
      },
    });
    const statusPayload = await statusResponse.json();

    if (!statusResponse.ok) {
      throw new HttpError(500, 'Kling AI polling failed.', statusPayload);
    }

    const status = String(statusPayload.status ?? '').toLowerCase();
    const videoUrl = statusPayload.video_url ?? statusPayload.url;
    if ((status === 'completed' || status === 'success') && typeof videoUrl === 'string') {
      return { videoUrl };
    }

    if (status === 'failed' || status === 'error') {
      throw new HttpError(500, 'Kling AI reported a failed generation.', statusPayload);
    }

    await delay(6000);
  }

  throw new HttpError(500, 'Kling AI timed out before the video was ready.');
}

export async function verifyStoreReceipt({
  platform,
  receipt,
}: {
  platform: 'apple' | 'google';
  receipt: string;
}): Promise<Record<string, unknown>> {
  if (platform === 'apple') {
    const response = await fetch('https://buy.itunes.apple.com/verifyReceipt', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receipt,
        password: Deno.env.get('APPLE_SHARED_SECRET') ?? '',
      }),
    });
    const payload = await response.json();
    if (!response.ok || payload.status !== 0) {
      throw new HttpError(500, 'Apple receipt verification failed.', payload);
    }
    return payload;
  }

  const googleAccessToken = requiredEnv('GOOGLE_PLAY_ACCESS_TOKEN');
  const response = await fetch(receipt, {
    headers: {
      Authorization: `Bearer ${googleAccessToken}`,
    },
  });
  const payload = await response.json();
  if (!response.ok) {
    throw new HttpError(500, 'Google receipt verification failed.', payload);
  }
  return payload;
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
