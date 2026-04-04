import {
  createAuthedClients,
  handleOptions,
  HttpError,
  json,
  sanitizeText,
  toErrorResponse,
} from '../_shared/http.ts';
import { verifyStoreReceipt } from '../_shared/external.ts';

Deno.serve(async (request) => {
  const optionsResponse = handleOptions(request);
  if (optionsResponse) {
    return optionsResponse;
  }

  try {
    const { user, adminClient } = await createAuthedClients(request);
    const payload = await request.json();
    const platform = sanitizeText(payload.platform, {
      field: 'platform',
      maxLength: 12,
    }).toLowerCase();
    const receipt = sanitizeText(payload.receipt, {
      field: 'receipt',
      maxLength: 6000,
    });
    const productId = sanitizeText(payload.product_id, {
      field: 'product_id',
      maxLength: 120,
    }).toLowerCase();

    if (platform !== 'apple' && platform !== 'google') {
      throw new HttpError(400, 'platform must be apple or google.');
    }

    const verification = await verifyStoreReceipt({
      platform,
      receipt,
    });
    const tier = deriveTier(productId);

    const { data, error } = await adminClient
      .from('users')
      .update({
        subscription_tier: tier,
      })
      .eq('id', user.id)
      .select()
      .single();

    if (error || !data) {
      throw error ?? new Error('Failed to persist the subscription tier.');
    }

    return json({
      success: true,
      tier,
      verification,
      user: data,
    });
  } catch (error) {
    return toErrorResponse(error);
  }
});

function deriveTier(productId: string): 'basic' | 'pro' {
  if (productId.includes('pro')) {
    return 'pro';
  }
  if (productId.includes('basic')) {
    return 'basic';
  }
  throw new HttpError(400, 'Unable to derive the tier from product_id.');
}
