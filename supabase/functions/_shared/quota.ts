import type { SupabaseClient } from 'jsr:@supabase/supabase-js@2';

import { HttpError } from './http.ts';

type TierName = 'free' | 'basic' | 'pro';
type FeatureName = 'songs' | 'videos' | 'lyrics';

export type TierLimits = {
  readonly name: TierName;
  readonly songs: number | null;
  readonly videos: number | null;
  readonly lyrics: number | null;
  readonly requestsPerMinute: number;
  readonly claudeInputTokens: number;
};

const tierMatrix: Record<TierName, TierLimits> = {
  free: {
    name: 'free',
    songs: 3,
    videos: 1,
    lyrics: 5,
    requestsPerMinute: 10,
    claudeInputTokens: 800,
  },
  basic: {
    name: 'basic',
    songs: 20,
    videos: 5,
    lyrics: null,
    requestsPerMinute: 30,
    claudeInputTokens: 1500,
  },
  pro: {
    name: 'pro',
    songs: null,
    videos: 20,
    lyrics: null,
    requestsPerMinute: 60,
    claudeInputTokens: 3000,
  },
};

export function getTierLimits(rawTier: string | null | undefined): TierLimits {
  if (rawTier === 'basic' || rawTier === 'pro') {
    return tierMatrix[rawTier];
  }
  return tierMatrix.free;
}

export function assertVideoQualityAllowed(tier: TierLimits, quality: string) {
  if (quality === '1080p' && tier.name !== 'pro') {
    throw new HttpError(403, 'Your plan does not include 1080p video.');
  }
  if (quality === '720p' && tier.name === 'free') {
    throw new HttpError(403, 'Upgrade to Basic or Pro for 720p video.');
  }
}

export async function touchRateLimit(
  adminClient: SupabaseClient,
  userId: string,
  requestsPerMinute: number,
) {
  const { error } = await adminClient.rpc('touch_rate_limit', {
    p_user_id: userId,
    p_requests_per_minute: requestsPerMinute,
  });

  if (!error) {
    return;
  }

  if (error.message.toLowerCase().includes('too many requests')) {
    throw new HttpError(429, 'Too many requests. Please wait and try again.');
  }

  throw new HttpError(500, 'Failed to enforce the request rate limit.', error);
}

export async function incrementUsage(
  adminClient: SupabaseClient,
  userId: string,
  feature: FeatureName,
  monthlyLimit: number | null,
) {
  const { error } = await adminClient.rpc('increment_usage', {
    p_user_id: userId,
    p_feature: feature,
    p_monthly_limit: monthlyLimit,
  });

  if (!error) {
    return;
  }

  if (error.message.toLowerCase().includes('quota')) {
    throw new HttpError(402, 'Monthly quota full. Upgrade to continue.');
  }

  throw new HttpError(500, 'Failed to increment usage.', error);
}
