// SMTP email sender for EgbeAnom.
// Reads encrypted SMTP settings first, with plaintext fallback during migration.

// @ts-ignore Remote URL import is resolved by Supabase Edge Runtime (Deno).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';
declare const Deno: {
  env: { get: (name: string) => string | undefined };
  serve: (handler: (request: Request) => Response | Promise<Response>) => unknown;
};

type Json = Record<string, unknown>;

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const serviceClient = supabaseUrl && serviceRoleKey
  ? createClient(supabaseUrl, serviceRoleKey)
  : null;

Deno.serve(async (request: Request) => {
  const headers = corsHeadersFor(request);
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers });
  }
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed.' }, 405, headers);
  }

  try {
    if (!serviceClient) {
      throw new Error(
        'Email function is missing Supabase environment variables. Redeploy the function and confirm SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are available.',
      );
    }

    const body = asObject(await request.json());
    const kind = asString(body.kind).trim();
    const subject = asString(body.subject).trim();
    const htmlBody = asString(body.htmlBody);
    const textBody = asString(body.textBody);
    const recipients = asStringArray(body.recipients)
      .map((value) => value.trim().toLowerCase())
      .filter((value, index, array) => value.length > 0 && array.indexOf(value) === index);

    if (!subject) {
      return json({ error: 'subject is required.' }, 400, headers);
    }
    if (!htmlBody && !textBody) {
      return json({ error: 'htmlBody or textBody is required.' }, 400, headers);
    }
    if (recipients.length === 0) {
      return json({ error: 'At least one recipient is required.' }, 400, headers);
    }

    await enforceRateLimit(
      `send_email_${kind || 'unknown'}`,
      `${clientIp(request)}:${recipients.join(',')}`,
      60,
      kind === 'manual' ? 20 : 8,
    );

    if (kind === 'manual') {
      await requireBackendUser(request);
    } else if (kind === 'order_event') {
      await validateOrderRecipient(body, recipients);
    } else {
      return json({ error: 'Unsupported email kind.' }, 400, headers);
    }

    const settings = await fetchEmailSettings();
    const directSsl = shouldUseDirectSsl(settings);
    const nodemailer = await loadMailer();
    const transporter = nodemailer.createTransport({
      host: settings.smtpHost,
      port: settings.smtpPort,
      secure: directSsl,
      requireTLS: !directSsl,
      connectionTimeout: 12000,
      greetingTimeout: 12000,
      socketTimeout: 20000,
      auth: settings.username || settings.password
        ? {
            user: settings.username || settings.fromEmail,
            pass: settings.password,
          }
        : undefined,
    });

    const messages = kind === 'manual' && recipients.length > 1
      ? recipients.map((recipient) => [recipient])
      : [recipients];
    const results: Record<string, unknown>[] = [];

    for (const messageRecipients of messages) {
      const result = await transporter.sendMail({
        from: `"${settings.fromName}" <${settings.fromEmail}>`,
        to: messageRecipients,
        subject,
        html: htmlBody || undefined,
        text: textBody || undefined,
      });
      results.push(result);
    }

    return json({
      sent: recipients.length,
      messageId: results.map((result) => result.messageId ?? '').join(','),
      accepted: results.flatMap((result) =>
        Array.isArray(result.accepted) ? result.accepted : []
      ),
      rejected: results.flatMap((result) =>
        Array.isArray(result.rejected) ? result.rejected : []
      ),
    }, 200, headers);
  } catch (error) {
    return json(
      { error: errorMessage(error) || 'Email send failed.' },
      400,
      headers,
    );
  }
});

async function loadMailer(): Promise<{
  createTransport: (options: Record<string, unknown>) => {
    sendMail: (message: Record<string, unknown>) => Promise<Record<string, unknown>>;
  };
}> {
  try {
    // @ts-ignore npm import is resolved by Supabase Edge Runtime (Deno).
    const module = await import('npm:nodemailer@6.9.16');
    return (module.default ?? module) as {
      createTransport: (options: Record<string, unknown>) => {
        sendMail: (message: Record<string, unknown>) => Promise<Record<string, unknown>>;
      };
    };
  } catch (error) {
    throw new Error(
      `Email function could not load the SMTP mailer. Redeploy the function, then try again. Original error: ${errorMessage(error)}`,
    );
  }
}

async function fetchEmailSettings(): Promise<{
  fromName: string;
  fromEmail: string;
  smtpHost: string;
  smtpPort: number;
  username: string;
  password: string;
  useSsl: boolean;
}> {
  const encrypted = await fetchEncryptedCredential('email_server', 'default');
  if (encrypted) {
    return normalizeEmailSettings(encrypted);
  }

  const { data, error } = await serviceClient!
    .from('site_settings')
    .select('value')
    .eq('key', 'email_server_settings')
    .maybeSingle();
  if (error) {
    throw new Error(`Email settings lookup failed: ${error.message}`);
  }
  return normalizeEmailSettings(asObject(data?.value));
}

function normalizeEmailSettings(value: Json): {
  fromName: string;
  fromEmail: string;
  smtpHost: string;
  smtpPort: number;
  username: string;
  password: string;
  useSsl: boolean;
} {
  const smtpHost = asString(value.smtp_host).trim();
  const fromEmail = asString(value.from_email).trim();
  if (!smtpHost) {
    throw new Error('SMTP host is not configured.');
  }
  if (!fromEmail) {
    throw new Error('From email is not configured.');
  }
  return {
    fromName: asString(value.from_name).trim() || 'EgbeAnom',
    fromEmail,
    smtpHost,
    smtpPort: asNumber(value.smtp_port) || 587,
    username: asString(value.username).trim(),
    password: asString(value.password),
    useSsl: value.use_ssl === true,
  };
}

async function fetchEncryptedCredential(
  providerType: string,
  providerName: string,
): Promise<Json | null> {
  const encryptionKey = Deno.env.get('ENCRYPTION_KEY') ?? '';
  if (!encryptionKey.trim()) {
    return null;
  }
  const { data, error } = await serviceClient!
    .from('encrypted_credentials')
    .select('credentials_encrypted')
    .eq('provider_type', providerType)
    .eq('provider_name', providerName)
    .maybeSingle();
  if (error) {
    throw new Error(`Encrypted credential lookup failed: ${error.message}`);
  }
  if (!data) {
    return null;
  }
  const { data: decrypted, error: decryptError } = await serviceClient!.rpc(
    'decrypt_credential_value',
    {
      p_encrypted_data: data.credentials_encrypted,
      p_encryption_key_hex: encryptionKey.trim(),
    },
  );
  if (decryptError) {
    throw new Error(`Encrypted credential decrypt failed: ${decryptError.message}`);
  }
  return asObject(JSON.parse(asString(decrypted)));
}

function shouldUseDirectSsl(settings: {
  smtpHost: string;
  smtpPort: number;
  useSsl: boolean;
}): boolean {
  if (settings.smtpPort === 465) {
    return true;
  }
  if (settings.smtpPort === 587 || settings.smtpPort === 25) {
    return false;
  }
  return settings.useSsl;
}

async function requireBackendUser(request: Request): Promise<void> {
  const token = bearerToken(request);
  if (!token) {
    throw new Error('Admin login is required to send manual emails.');
  }
  const { data: userData, error: userError } = await serviceClient!.auth.getUser(token);
  if (userError || !userData.user?.email) {
    throw new Error('Admin login is required to send manual emails.');
  }
  const email = userData.user.email.toLowerCase();
  const { data, error } = await serviceClient!
    .from('backend_users')
    .select('id,email,is_active,is_blocked')
    .eq('email', email)
    .eq('is_active', true)
    .eq('is_blocked', false)
    .limit(1);
  if (error) {
    throw new Error(`Admin user lookup failed: ${error.message}`);
  }
  if (!Array.isArray(data) || data.length === 0) {
    throw new Error('Admin login is required to send manual emails.');
  }
}

async function validateOrderRecipient(body: Json, recipients: string[]): Promise<void> {
  const orderId = asString(body.orderId).trim();
  const event = asString(body.event).trim();
  if (!orderId) {
    throw new Error('orderId is required for order emails.');
  }
  if (!['payment_success', 'payment_failed', 'processing', 'label_created', 'sent'].includes(event)) {
    throw new Error('Unsupported order email event.');
  }
  const { data, error } = await serviceClient!
    .from('orders')
    .select('email,financial_status')
    .eq('order_number', orderId)
    .limit(1);
  if (error) {
    throw new Error(`Order lookup failed: ${error.message}`);
  }
  const order = Array.isArray(data) && data.length > 0 ? asObject(data[0]) : {};
  const orderEmail = asString(order.email).trim().toLowerCase();
  if (!orderEmail || recipients.length !== 1 || recipients[0] !== orderEmail) {
    throw new Error('Order emails can only be sent to the customer on the order.');
  }
  if (event !== 'payment_success' && event !== 'payment_failed') {
    const financialStatus = asString(order.financial_status).trim().toLowerCase();
    if (financialStatus !== 'paid') {
      throw new Error('Order status emails require a paid order.');
    }
  }
}

function bearerToken(request: Request): string {
  const header = request.headers.get('authorization') ?? '';
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  return match?.[1]?.trim() ?? '';
}

async function enforceRateLimit(
  scope: string,
  subject: string,
  windowSeconds: number,
  maxEvents: number,
): Promise<void> {
  const { data, error } = await serviceClient!.rpc('check_rate_limit', {
    p_scope: scope,
    p_subject: subject,
    p_window_seconds: windowSeconds,
    p_max_events: maxEvents,
  });
  if (error) {
    throw new Error(`Rate limit check failed: ${error.message}`);
  }
  if (data !== true) {
    throw new Error('Too many attempts. Please wait a minute and try again.');
  }
}

function clientIp(request: Request): string {
  return (
    request.headers.get('x-forwarded-for')?.split(',').shift()?.trim() ||
    request.headers.get('cf-connecting-ip') ||
    'unknown'
  );
}

function asObject(value: unknown): Json {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Json;
  }
  return {};
}

function asStringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.map((item) => (typeof item === 'string' ? item : ''))
    : [];
}

function asString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function asNumber(value: unknown): number {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function corsHeadersFor(request: Request): HeadersInit {
  const origin = request.headers.get('origin') ?? '*';
  const configured = (Deno.env.get('ALLOWED_ORIGINS') ?? Deno.env.get('ALLOWED_ORIGIN') ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
  const allowedOrigin = configured.length === 0 || configured.includes(origin) || configured.includes('*')
    ? origin
    : configured[0];
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
  };
}

function json(payload: Json, status = 200, headers: HeadersInit = corsHeadersFor(new Request('https://local.invalid'))): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
}

function errorMessage(error: unknown): string {
  const raw = error instanceof Error ? error.message : `${error}`;
  const lower = raw.toLowerCase();
  if (
    lower.includes('invalid login') ||
    lower.includes('invalid credentials') ||
    lower.includes('username and password not accepted') ||
    lower.includes('535')
  ) {
    return 'Gmail rejected the login. Use the full Gmail address as the username and a Google App Password, not the normal Gmail password.';
  }
  if (lower.includes('less secure') || lower.includes('application-specific')) {
    return 'Gmail requires a Google App Password for SMTP.';
  }
  if (lower.includes('etimedout') || lower.includes('timeout')) {
    return 'SMTP connection timed out. For Gmail use smtp.gmail.com, port 587, and leave direct SSL off.';
  }
  if (lower.includes('ssl') || lower.includes('wrong version number')) {
    return 'SMTP SSL setting looks wrong. For Gmail use port 587 with direct SSL off, or port 465 with direct SSL on.';
  }
  return raw;
}
