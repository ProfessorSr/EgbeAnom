// IMAP inbox sync for EgbeAnom admin email.

// @ts-ignore Remote URL import is resolved by Supabase Edge Runtime (Deno).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';
// @ts-ignore npm import is resolved by Supabase Edge Runtime (Deno).
import { ImapFlow } from 'npm:imapflow@1.0.194';
// @ts-ignore npm import is resolved by Supabase Edge Runtime (Deno).
import { simpleParser } from 'npm:mailparser@3.7.2';

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
      throw new Error('Email fetch function is missing Supabase environment variables.');
    }
    await requireBackendUser(request);

    const body = asObject(await request.json().catch(() => ({})));
    let mailbox = asString(body.mailbox).trim() || 'INBOX';
    const requestedAccount = asString(body.account_id || body.account_email).trim();
    const action = asString(body.action).trim().toLowerCase();
    const limit = Math.min(Math.max(asNumber(body.limit) || 30, 1), 75);
    const settings = await fetchEmailSettings(requestedAccount);
    if (!settings.imapHost) {
      throw new Error('IMAP host is not configured.');
    }
    if (!settings.username && !settings.fromEmail) {
      throw new Error('Mailbox username is not configured.');
    }
    if (!settings.password) {
      throw new Error('Mailbox password or app password is not configured.');
    }

    const client = new ImapFlow({
      host: settings.imapHost,
      port: settings.imapPort,
      secure: settings.imapPort === 993 || settings.useSsl === true,
      auth: {
        user: settings.username || settings.fromEmail,
        pass: settings.password,
      },
      logger: false,
    });

    if (action === 'set_read') {
      let messageId = asString(body.message_id).trim();
      const rowId = asString(body.id).trim();
      const isRead = body.is_read === true;
      const requestedUid = asNumber(body.uid);
      if (!messageId) {
        messageId = rowId;
      }
      if (!messageId) {
        throw new Error('Message ID is required to update read status.');
      }
      await client.connect();
      const lock = await client.getMailboxLock(mailbox);
      try {
        const uid = requestedUid > 0
          ? requestedUid
          : await findMessageUid(client, mailbox, messageId, 75);
        if (uid !== null) {
          if (isRead) {
            await client.messageFlagsAdd(uid, ['\\Seen'], { uid: true });
          } else {
            await client.messageFlagsRemove(uid, ['\\Seen'], { uid: true });
          }
        }
      } finally {
        lock.release();
        await client.logout().catch(() => undefined);
      }
      return json({ updated: true, serverUpdated: true }, 200, headers);
    }

    await client.connect();
    const rows: Json[] = [];
    const lock = await client.getMailboxLock(mailbox);
    try {
      const mailboxInfo = client.mailbox;
      const exists = Number(mailboxInfo?.exists ?? 0);
      if (exists > 0) {
        const start = Math.max(1, exists - limit + 1);
        for await (const message of client.fetch(`${start}:*`, {
          uid: true,
          envelope: true,
          source: true,
          internalDate: true,
          flags: true,
        })) {
          const parsed = await simpleParser(message.source);
          const messageId =
            `${parsed.messageId || message.envelope?.messageId || ''}`.trim() ||
            `${mailbox}-${message.uid}`;
          const from = parsed.from?.value?.[0] ?? {};
          const to = parsed.to?.value?.[0] ?? {};
          const subject = `${parsed.subject || message.envelope?.subject || '(No subject)'}`.trim();
          const text = `${parsed.text || ''}`.trim();
          const html = typeof parsed.html === 'string' ? parsed.html : '';
          const preview = text
            .replace(/\s+/g, ' ')
            .trim()
            .slice(0, 240) || stripHtml(html).slice(0, 240);
          const orderNumber = orderNumberFromText(`${subject}\n${text}\n${html}`);
          rows.push({
            id: stableId(`${settings.id}:${messageId}`),
            account_id: settings.id,
            account_email: settings.fromEmail,
            mailbox,
            message_id: messageId,
            server_uid: message.uid,
            from_email: `${from.address || ''}`.trim().toLowerCase(),
            from_name: `${from.name || ''}`.trim(),
            to_email: `${to.address || settings.fromEmail}`.trim().toLowerCase(),
            subject,
            preview,
            text_body: text,
            html_body: html,
            received_at:
              (message.internalDate instanceof Date
                ? message.internalDate
                : parsed.date instanceof Date
                ? parsed.date
                : new Date()).toISOString(),
            is_read: hasFlag(message.flags, '\\Seen'),
            order_number: orderNumber,
          });
        }
      }
    } finally {
      lock.release();
      await client.logout().catch(() => undefined);
    }

    return json({ imported: rows.length, scanned: rows.length, messages: rows }, 200, headers);
  } catch (error) {
    return json({ error: errorMessage(error) || 'Inbox sync failed.' }, 400, headers);
  }
});

function hasFlag(flags: unknown, expected: string): boolean {
  if (Array.isArray(flags)) {
    return flags.includes(expected);
  }
  if (flags && typeof flags === 'object' && Symbol.iterator in flags) {
    return Array.from(flags as Iterable<unknown>).includes(expected);
  }
  return false;
}

async function findMessageUid(
  client: ImapFlow,
  mailbox: string,
  messageId: string,
  scanLimit: number,
): Promise<number | null> {
  const mailboxInfo = client.mailbox;
  const exists = Number(mailboxInfo?.exists ?? 0);
  if (exists <= 0) {
    return null;
  }
  const start = Math.max(1, exists - scanLimit + 1);
  for await (const message of client.fetch(`${start}:*`, {
    uid: true,
    envelope: true,
  })) {
    const envelopeId = `${message.envelope?.messageId || ''}`.trim();
    const fallbackId = `${mailbox}-${message.uid}`;
    if (envelopeId === messageId || fallbackId === messageId) {
      return Number(message.uid);
    }
  }
  return null;
}

async function fetchEmailSettings(requestedAccount = ''): Promise<{
  id: string;
  fromEmail: string;
  imapHost: string;
  imapPort: number;
  username: string;
  password: string;
  useSsl: boolean;
}> {
  const encrypted = await fetchEncryptedCredential('email_server', 'default');
  if (encrypted) {
    return selectEmailAccount(encrypted, requestedAccount);
  }

  const { data, error } = await serviceClient!
    .from('site_settings')
    .select('value')
    .eq('key', 'email_server_settings')
    .maybeSingle();
  if (error) {
    throw new Error(`Email settings lookup failed: ${error.message}`);
  }
  return selectEmailAccount(asObject(data?.value), requestedAccount);
}

function normalizeEmailSettings(value: Json): {
  id: string;
  fromEmail: string;
  imapHost: string;
  imapPort: number;
  username: string;
  password: string;
  useSsl: boolean;
} {
  return {
    id: asString(value.id).trim() || accountIdFor(asString(value.from_email)),
    fromEmail: asString(value.from_email).trim(),
    imapHost: asString(value.imap_host).trim(),
    imapPort: asNumber(value.imap_port) || 993,
    username: asString(value.username).trim(),
    password: asString(value.password),
    useSsl: value.use_ssl === true,
  };
}

function selectEmailAccount(value: Json, requestedAccount = ''): {
  id: string;
  fromEmail: string;
  imapHost: string;
  imapPort: number;
  username: string;
  password: string;
  useSsl: boolean;
} {
  const accountsValue = Array.isArray(value.accounts) ? value.accounts : [];
  const accounts = accountsValue
    .map((account) => normalizeEmailSettings(asObject(account)))
    .filter((account) => account.fromEmail || account.username);
  if (accounts.length === 0) {
    return normalizeEmailSettings(value);
  }
  const requested = requestedAccount.trim().toLowerCase();
  if (requested) {
    const match = accounts.find((account) =>
      account.id.toLowerCase() === requested ||
      account.fromEmail.toLowerCase() === requested ||
      account.username.toLowerCase() === requested
    );
    if (match) {
      return match;
    }
  }
  const defaultId = asString(value.default_account_id).trim().toLowerCase();
  return accounts.find((account) => account.id.toLowerCase() === defaultId) ?? accounts[0];
}

function accountIdFor(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '') || 'default';
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

async function requireBackendUser(request: Request): Promise<void> {
  const token = bearerToken(request);
  if (!token) {
    throw new Error('Admin login is required to sync inbox.');
  }
  const { data: userData, error: userError } = await serviceClient!.auth.getUser(token);
  if (userError || !userData.user?.email) {
    throw new Error('Admin login is required to sync inbox.');
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
    throw new Error('Admin login is required to sync inbox.');
  }
}

function stableId(value: string): string {
  let hash = 0;
  for (let i = 0; i < value.length; i += 1) {
    hash = Math.imul(31, hash) + value.charCodeAt(i) | 0;
  }
  return `MAIL-${Math.abs(hash)}-${value.replace(/[^a-z0-9]/gi, '').slice(0, 18)}`;
}

function orderNumberFromText(value: string): string {
  return /(?:EA|ORDER|ORD)[-#]?[A-Z0-9-]{4,}/i.exec(value)?.[0] ?? '';
}

function stripHtml(value: string): string {
  return value.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
}

function bearerToken(request: Request): string {
  const header = request.headers.get('authorization') ?? '';
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  return match?.[1]?.trim() ?? '';
}

function asObject(value: unknown): Json {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Json;
  }
  return {};
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

function json(body: Json, status: number, headers: HeadersInit): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
}

function corsHeadersFor(request: Request): HeadersInit {
  const origin = request.headers.get('origin') || '*';
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    Vary: 'Origin',
  };
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return `${error}`;
}
