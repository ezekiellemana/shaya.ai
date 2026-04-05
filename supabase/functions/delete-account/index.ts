import { type SupabaseClient, type User } from 'jsr:@supabase/supabase-js@2';
import {
  createAuthedClients,
  handleOptions,
  HttpError,
  json,
  requiredEnv,
  sanitizeText,
  toErrorResponse,
} from '../_shared/http.ts';

Deno.serve(async (request) => {
  const optionsResponse = handleOptions(request);
  if (optionsResponse) {
    return optionsResponse;
  }

  try {
    const { user, adminClient } = await createAuthedClients(request);
    const payload = await request.json();
    const confirmation = sanitizeText(payload.confirmation, {
      field: 'confirmation',
      maxLength: 16,
    });
    const password = sanitizeText(payload.password, {
      field: 'password',
      maxLength: 128,
      required: false,
    });

    if (confirmation != 'DELETE') {
      throw new HttpError(400, 'Type DELETE exactly to confirm this action.');
    }

    const provider = String(user.app_metadata?.provider ?? 'email').toLowerCase();
    if (provider == 'email') {
      await verifyCurrentPassword(user, password);
    }

    await removeAvatarObjects(adminClient, user.id);

    const { error } = await adminClient.auth.admin.deleteUser(user.id);
    if (error) {
      throw new HttpError(500, 'Failed to delete the auth user.', error);
    }

    return json({
      success: true,
      deleted_user_id: user.id,
    });
  } catch (error) {
    return toErrorResponse(error);
  }
});

async function verifyCurrentPassword(user: User, password: string) {
  if (password.length == 0) {
    throw new HttpError(400, 'Enter your current password to delete your account.');
  }
  if (!user.email) {
    throw new HttpError(400, 'Your account email is missing. Sign in again and retry.');
  }

  const response = await fetch(
    `${requiredEnv('SUPABASE_URL')}/auth/v1/token?grant_type=password`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: requiredEnv('SUPABASE_ANON_KEY'),
      },
      body: JSON.stringify({
        email: user.email,
        password,
      }),
    },
  );

  if (!response.ok) {
    throw new HttpError(401, 'Your current password is incorrect.');
  }
}

async function removeAvatarObjects(adminClient: SupabaseClient, userId: string) {
  const { data, error } = await adminClient.storage.from('avatars').list(userId, {
    limit: 100,
    offset: 0,
  });

  if (error) {
    throw new HttpError(500, 'Failed to inspect stored avatar files.', error);
  }

  if (!data || data.length == 0) {
    return;
  }

  const paths = data
    .map((entry) => entry.name)
    .where((name): name is string => typeof name == 'string' && name.length > 0)
    .map((name) => `${userId}/${name}`);

  if (paths.length == 0) {
    return;
  }

  const { error: removeError } = await adminClient.storage.from('avatars').remove(paths);
  if (removeError) {
    throw new HttpError(500, 'Failed to remove stored avatar files.', removeError);
  }
}
