import { createClient, type SupabaseClient, type User } from 'jsr:@supabase/supabase-js@2';

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly details?: unknown,
  ) {
    super(message);
  }
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

export function handleOptions(request: Request): Response | null {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  return null;
}

export function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new HttpError(500, `Missing required environment variable ${name}.`);
  }
  return value;
}

export function sanitizeText(
  value: unknown,
  {
    field,
    maxLength,
    required = true,
  }: {
    field: string;
    maxLength: number;
    required?: boolean;
  },
): string {
  if (typeof value !== 'string') {
    if (required) {
      throw new HttpError(400, `${field} must be a string.`);
    }
    return '';
  }

  const trimmed = value.trim();
  if (required && trimmed.length == 0) {
    throw new HttpError(400, `${field} is required.`);
  }
  if (trimmed.length > maxLength) {
    throw new HttpError(400, `${field} exceeds ${maxLength} characters.`);
  }
  return trimmed;
}

export function sanitizeStringArray(
  value: unknown,
  {
    field,
    maxItems,
    maxItemLength,
  }: {
    field: string;
    maxItems: number;
    maxItemLength: number;
  },
): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  const sanitized = value
    .filter((entry) => typeof entry === 'string')
    .map((entry) => entry.trim())
    .filter(Boolean)
    .slice(0, maxItems)
    .map((entry) => {
      if (entry.length > maxItemLength) {
        throw new HttpError(400, `${field} items exceed ${maxItemLength} characters.`);
      }
      return entry;
    });

  return [...new Set(sanitized)];
}

export function deriveTitle(source: string): string {
  const normalized = source
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 48);
  return normalized.length > 0 ? normalized : 'Untitled Shaya Creation';
}

export async function createAuthedClients(request: Request): Promise<{
  user: User;
  userClient: SupabaseClient;
  adminClient: SupabaseClient;
}> {
  const supabaseUrl = requiredEnv('SUPABASE_URL');
  const supabaseAnonKey = requiredEnv('SUPABASE_ANON_KEY');
  const serviceRoleKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
  const authorization = request.headers.get('Authorization');

  if (!authorization) {
    throw new HttpError(401, 'Not logged in.');
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authorization,
      },
    },
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const {
    data: { user },
    error,
  } = await userClient.auth.getUser();

  if (error || !user) {
    throw new HttpError(401, 'Not logged in.');
  }

  return {
    user,
    userClient,
    adminClient,
  };
}

export async function fetchProfile(adminClient: SupabaseClient, userId: string) {
  const { data, error } = await adminClient
    .from('users')
    .select('*')
    .eq('id', userId)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, 'Failed to fetch profile.', error);
  }
  if (!data) {
    throw new HttpError(403, 'User profile not found.');
  }
  return data;
}

export function toErrorResponse(error: unknown): Response {
  if (error instanceof HttpError) {
    return json(
      {
        error: error.message,
        details: error.details,
      },
      error.status,
    );
  }

  return json(
    {
      error: 'Unexpected server error.',
    },
    500,
  );
}
