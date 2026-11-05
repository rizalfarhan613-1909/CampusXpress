import { importPKCS8, SignJWT } from 'jose';
import type { Env } from './env';
import { HttpError } from './errors';

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id?: string;
}

export interface FirestoreDoc {
  id: string;
  data: Record<string, unknown>;
  updateTime: string;
}

export interface WriteOp {
  path: string;
  set?: Record<string, unknown>;
  mask?: string[];
  precondition?: string;
  mustNotExist?: boolean;
  serverTime?: string[];
  increments?: Record<string, number>;
}

export interface QueryWhere {
  field: string;
  op:
    | 'EQUAL'
    | 'LESS_THAN'
    | 'GREATER_THAN'
    | 'LESS_THAN_OR_EQUAL'
    | 'GREATER_THAN_OR_EQUAL';
  value: unknown;
}

export interface QueryOptions {
  where?: QueryWhere[];
  orderBy?: { field: string; direction: 'ASCENDING' | 'DESCENDING' };
  limit?: number;
  collectionGroup?: boolean;
}

export function enc(value: unknown): Record<string, unknown> {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map((item) => enc(item)) } };
  }
  const fields: Record<string, unknown> = {};
  for (const [key, item] of Object.entries(value as Record<string, unknown>)) {
    fields[key] = enc(item);
  }
  return { mapValue: { fields } };
}

export function dec(field: unknown): unknown {
  if (!field || typeof field !== 'object') return undefined;
  const value = field as Record<string, unknown>;
  if ('nullValue' in value) return null;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('stringValue' in value) return value.stringValue;
  if ('timestampValue' in value) return new Date(String(value.timestampValue));
  if ('arrayValue' in value) {
    const array = value.arrayValue as { values?: unknown[] };
    return (array.values ?? []).map((item) => dec(item));
  }
  if ('mapValue' in value) {
    const map = value.mapValue as { fields?: Record<string, unknown> };
    return decFields(map.fields ?? {});
  }
  return undefined;
}

export function decFields(
  fields: Record<string, unknown>,
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(fields)) out[key] = dec(value);
  return out;
}

let cachedToken: { token: string; exp: number } | null = null;

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.token;

  const key = await importPKCS8(sa.private_key.replace(/\\n/g, '\n'), 'RS256');
  const assertion = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/datastore',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) {
    throw new HttpError(500, 'FIRESTORE_AUTH_FAILED', await response.text());
  }
  const json = (await response.json()) as {
    access_token: string;
    expires_in: number;
  };
  cachedToken = { token: json.access_token, exp: now + json.expires_in };
  return json.access_token;
}

export class Firestore {
  private readonly base: string;
  private readonly sa: ServiceAccount;

  constructor(env: Env['Bindings']) {
    const raw = env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
    if (!raw) throw new HttpError(500, 'FIRESTORE_NOT_CONFIGURED');
    this.sa = JSON.parse(raw) as ServiceAccount;
    const projectId = env.FIREBASE_PROJECT_ID || this.sa.project_id;
    this.base =
      `https://firestore.googleapis.com/v1/projects/${projectId}` +
      '/databases/(default)/documents';
  }

  async get(path: string, txn?: string): Promise<FirestoreDoc | null> {
    const query = txn ? `?transaction=${encodeURIComponent(txn)}` : '';
    const response = await fetch(`${this.base}/${path}${query}`, {
      headers: { Authorization: `Bearer ${await accessToken(this.sa)}` },
    });
    if (response.status === 404) return null;
    if (!response.ok) {
      throw new HttpError(500, 'FIRESTORE_GET_FAILED', await response.text());
    }
    const doc = (await response.json()) as {
      name: string;
      fields?: Record<string, unknown>;
      updateTime: string;
    };
    return {
      id: doc.name.split('/').pop() ?? '',
      data: decFields(doc.fields ?? {}),
      updateTime: doc.updateTime,
    };
  }

  async runQuery(
    collectionId: string,
    options: QueryOptions = {},
    txn?: string,
    parent?: string,
  ): Promise<FirestoreDoc[]> {
    const structuredQuery: Record<string, unknown> = {
      from: [
        {
          collectionId,
          ...(options.collectionGroup ? { allDescendants: true } : {}),
        },
      ],
    };

    if (options.where && options.where.length > 0) {
      structuredQuery.where = {
        compositeFilter: {
          op: 'AND',
          filters: options.where.map((item) => ({
            fieldFilter: {
              field: { fieldPath: item.field },
              op: item.op,
              value: enc(item.value),
            },
          })),
        },
      };
    }
    if (options.orderBy) {
      structuredQuery.orderBy = [
        {
          field: { fieldPath: options.orderBy.field },
          direction: options.orderBy.direction,
        },
      ];
    }
    if (options.limit) structuredQuery.limit = options.limit;

    const body: Record<string, unknown> = { structuredQuery };
    if (txn) body.transaction = txn;

    const endpoint = parent
      ? `${this.base}/${parent}:runQuery`
      : `${this.base}:runQuery`;
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${await accessToken(this.sa)}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      throw new HttpError(500, 'FIRESTORE_QUERY_FAILED', await response.text());
    }
    const rows = (await response.json()) as Array<{
      document?: {
        name: string;
        fields?: Record<string, unknown>;
        updateTime: string;
      };
    }>;
    return rows
      .filter((row) => row.document)
      .map((row) => {
        const doc = row.document as {
          name: string;
          fields?: Record<string, unknown>;
          updateTime: string;
        };
        return {
          id: doc.name.split('/').pop() ?? '',
          data: decFields(doc.fields ?? {}),
          updateTime: doc.updateTime,
        };
      });
  }

  async listLatest(
    collectionId: string,
    limit: number,
    options: { field?: string } = {},
  ): Promise<FirestoreDoc[]> {
    return this.runQuery(collectionId, {
      orderBy: { field: options.field ?? 'created_at', direction: 'DESCENDING' },
      limit,
    });
  }

  async begin(): Promise<string> {
    const response = await this.call(':beginTransaction', { method: 'POST', body: '{}' });
    const json = (await response.json()) as { transaction: string };
    return json.transaction;
  }

  async commit(ops: WriteOp[], txn?: string): Promise<void> {
    const writes = ops.map((op) => {
      const fields = op.set
        ? (enc(op.set) as { mapValue: { fields: Record<string, unknown> } }).mapValue
            .fields
        : {};
      const write: Record<string, unknown> = {
        update: { name: `${this.base}/${op.path}`, fields },
      };
      if (op.mask) write.updateMask = { fieldPaths: op.mask };
      if (op.mustNotExist) {
        write.currentDocument = { exists: false };
      } else if (op.precondition) {
        write.currentDocument = { updateTime: op.precondition };
      }
      const transforms = [
        ...(op.serverTime ?? []).map((fieldPath) => ({
          fieldPath,
          setToServerValue: 'REQUEST_TIME',
        })),
        ...Object.entries(op.increments ?? {}).map(([fieldPath, amount]) => ({
          fieldPath,
          increment: { integerValue: String(amount) },
        })),
      ];
      if (transforms.length > 0) write.updateTransforms = transforms;
      return write;
    });

    await this.call(':commit', {
      method: 'POST',
      body: JSON.stringify({ writes, ...(txn ? { transaction: txn } : {}) }),
    });
  }

  private async call(suffix: string, init: RequestInit): Promise<Response> {
    const response = await fetch(`${this.base}${suffix}`, {
      ...init,
      headers: {
        Authorization: `Bearer ${await accessToken(this.sa)}`,
        'Content-Type': 'application/json',
        ...(init.headers ?? {}),
      },
    });
    if (!response.ok) {
      throw new HttpError(500, 'FIRESTORE_WRITE_FAILED', await response.text());
    }
    return response;
  }
}