# Authentication

Implementing auth flows for API integrations.

## Auth Method Overview

| Method | Use Case | Complexity |
|--------|----------|------------|
| API Key | Server-to-server, simple integrations | Low |
| Bearer Token | Token-based auth, JWTs | Medium |
| OAuth 2.0 | Third-party integrations, user consent | High |
| Basic Auth | Legacy systems, simple auth | Low |
| HMAC Signature | Webhook verification, secure APIs | Medium |

---

## API Key Authentication

### Header-Based

```typescript
class ApiKeyClient {
  constructor(
    private baseUrl: string,
    private apiKey: string,
    private headerName: string = 'X-API-Key'
  ) {}

  async request<T>(path: string, options?: RequestInit): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      ...options,
      headers: {
        ...options?.headers,
        [this.headerName]: this.apiKey,
      },
    });

    if (!response.ok) {
      throw await ApiError.fromResponse(response);
    }

    return response.json();
  }
}

// Usage
const client = new ApiKeyClient(
  'https://api.example.com',
  process.env.API_KEY!,
  'Authorization' // or 'X-API-Key', 'Api-Key', etc.
);
```

### Query Parameter (Less Secure)

```typescript
class QueryApiKeyClient {
  constructor(
    private baseUrl: string,
    private apiKey: string,
    private paramName: string = 'api_key'
  ) {}

  async request<T>(path: string): Promise<T> {
    const url = new URL(path, this.baseUrl);
    url.searchParams.set(this.paramName, this.apiKey);

    const response = await fetch(url.toString());

    if (!response.ok) {
      throw await ApiError.fromResponse(response);
    }

    return response.json();
  }
}
```

### API Key Best Practices

```typescript
// ✅ Load from environment
const apiKey = process.env.API_KEY;

// ✅ Validate at startup
if (!apiKey) {
  throw new Error('API_KEY environment variable is required');
}

// ✅ Don't log
console.log('Making request with key:', apiKey); // ❌ NEVER

// ✅ Rotate regularly
// Store rotation date, warn when approaching
const KEY_ROTATION_DAYS = 90;
```

---

## Bearer Token Authentication

### Static Token

```typescript
class BearerTokenClient {
  constructor(
    private baseUrl: string,
    private getToken: () => string | Promise<string>
  ) {}

  async request<T>(path: string, options?: RequestInit): Promise<T> {
    const token = await this.getToken();

    const response = await fetch(`${this.baseUrl}${path}`, {
      ...options,
      headers: {
        ...options?.headers,
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw await ApiError.fromResponse(response);
    }

    return response.json();
  }
}

// Static token
const client = new BearerTokenClient(
  'https://api.example.com',
  () => process.env.ACCESS_TOKEN!
);

// Dynamic token (from auth service)
const client = new BearerTokenClient(
  'https://api.example.com',
  () => authService.getAccessToken()
);
```

### Token Refresh

```typescript
interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresAt: number; // Unix timestamp
}

class TokenManager {
  private tokenPair: TokenPair | null = null;
  private refreshPromise: Promise<TokenPair> | null = null;

  constructor(
    private refreshEndpoint: string,
    private onTokenRefreshed?: (tokens: TokenPair) => void
  ) {}

  setTokens(tokens: TokenPair): void {
    this.tokenPair = tokens;
  }

  async getAccessToken(): Promise<string> {
    if (!this.tokenPair) {
      throw new AuthenticationError('No tokens available');
    }

    // Check if token is expired or about to expire (5 min buffer)
    const bufferMs = 5 * 60 * 1000;
    if (Date.now() >= this.tokenPair.expiresAt - bufferMs) {
      await this.refresh();
    }

    return this.tokenPair.accessToken;
  }

  private async refresh(): Promise<void> {
    // Deduplicate concurrent refresh requests
    if (this.refreshPromise) {
      await this.refreshPromise;
      return;
    }

    this.refreshPromise = this.doRefresh();

    try {
      this.tokenPair = await this.refreshPromise;
      this.onTokenRefreshed?.(this.tokenPair);
    } finally {
      this.refreshPromise = null;
    }
  }

  private async doRefresh(): Promise<TokenPair> {
    if (!this.tokenPair) {
      throw new AuthenticationError('No refresh token available');
    }

    const response = await fetch(this.refreshEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        refresh_token: this.tokenPair.refreshToken,
      }),
    });

    if (!response.ok) {
      throw new AuthenticationError('Token refresh failed');
    }

    const data = await response.json();

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresAt: Date.now() + data.expires_in * 1000,
    };
  }
}

// Usage
const tokenManager = new TokenManager(
  'https://api.example.com/oauth/token',
  (tokens) => {
    // Persist refreshed tokens
    localStorage.setItem('tokens', JSON.stringify(tokens));
  }
);

// Initialize from storage
const stored = localStorage.getItem('tokens');
if (stored) {
  tokenManager.setTokens(JSON.parse(stored));
}

const client = new BearerTokenClient(
  'https://api.example.com',
  () => tokenManager.getAccessToken()
);
```

---

## OAuth 2.0

### Authorization Code Flow (Web)

```typescript
interface OAuthConfig {
  clientId: string;
  clientSecret: string;
  authorizationUrl: string;
  tokenUrl: string;
  redirectUri: string;
  scopes: string[];
}

class OAuth2Client {
  constructor(private config: OAuthConfig) {}

  // Step 1: Generate authorization URL
  getAuthorizationUrl(state: string): string {
    const url = new URL(this.config.authorizationUrl);
    url.searchParams.set('client_id', this.config.clientId);
    url.searchParams.set('redirect_uri', this.config.redirectUri);
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('scope', this.config.scopes.join(' '));
    url.searchParams.set('state', state);
    return url.toString();
  }

  // Step 2: Exchange code for tokens
  async exchangeCode(code: string): Promise<TokenPair> {
    const response = await fetch(this.config.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: this.config.clientId,
        client_secret: this.config.clientSecret,
        redirect_uri: this.config.redirectUri,
        code,
      }),
    });

    if (!response.ok) {
      throw new AuthenticationError('Token exchange failed');
    }

    const data = await response.json();

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresAt: Date.now() + data.expires_in * 1000,
    };
  }

  // Step 3: Refresh tokens
  async refreshTokens(refreshToken: string): Promise<TokenPair> {
    const response = await fetch(this.config.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        client_id: this.config.clientId,
        client_secret: this.config.clientSecret,
        refresh_token: refreshToken,
      }),
    });

    if (!response.ok) {
      throw new AuthenticationError('Token refresh failed');
    }

    const data = await response.json();

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token ?? refreshToken,
      expiresAt: Date.now() + data.expires_in * 1000,
    };
  }
}
```

### PKCE Flow (Mobile/SPA)

```typescript
// PKCE helpers
function generateCodeVerifier(): string {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return base64UrlEncode(array);
}

async function generateCodeChallenge(verifier: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return base64UrlEncode(new Uint8Array(hash));
}

function base64UrlEncode(buffer: Uint8Array): string {
  return btoa(String.fromCharCode(...buffer))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

class PKCEOAuthClient {
  private codeVerifier: string | null = null;

  constructor(private config: Omit<OAuthConfig, 'clientSecret'>) {}

  async getAuthorizationUrl(state: string): Promise<string> {
    this.codeVerifier = generateCodeVerifier();
    const codeChallenge = await generateCodeChallenge(this.codeVerifier);

    const url = new URL(this.config.authorizationUrl);
    url.searchParams.set('client_id', this.config.clientId);
    url.searchParams.set('redirect_uri', this.config.redirectUri);
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('scope', this.config.scopes.join(' '));
    url.searchParams.set('state', state);
    url.searchParams.set('code_challenge', codeChallenge);
    url.searchParams.set('code_challenge_method', 'S256');

    return url.toString();
  }

  async exchangeCode(code: string): Promise<TokenPair> {
    if (!this.codeVerifier) {
      throw new Error('Code verifier not available');
    }

    const response = await fetch(this.config.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: this.config.clientId,
        redirect_uri: this.config.redirectUri,
        code,
        code_verifier: this.codeVerifier,
      }),
    });

    this.codeVerifier = null;

    if (!response.ok) {
      throw new AuthenticationError('Token exchange failed');
    }

    const data = await response.json();

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresAt: Date.now() + data.expires_in * 1000,
    };
  }
}
```

### Client Credentials Flow (Server-to-Server)

```typescript
class ClientCredentialsAuth {
  private accessToken: string | null = null;
  private expiresAt: number = 0;
  private fetchPromise: Promise<string> | null = null;

  constructor(
    private tokenUrl: string,
    private clientId: string,
    private clientSecret: string,
    private scopes: string[] = []
  ) {}

  async getAccessToken(): Promise<string> {
    // Return cached token if valid
    if (this.accessToken && Date.now() < this.expiresAt - 60000) {
      return this.accessToken;
    }

    // Deduplicate concurrent requests
    if (this.fetchPromise) {
      return this.fetchPromise;
    }

    this.fetchPromise = this.fetchToken();

    try {
      return await this.fetchPromise;
    } finally {
      this.fetchPromise = null;
    }
  }

  private async fetchToken(): Promise<string> {
    const response = await fetch(this.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Authorization: `Basic ${btoa(`${this.clientId}:${this.clientSecret}`)}`,
      },
      body: new URLSearchParams({
        grant_type: 'client_credentials',
        scope: this.scopes.join(' '),
      }),
    });

    if (!response.ok) {
      throw new AuthenticationError('Failed to obtain access token');
    }

    const data = await response.json();

    this.accessToken = data.access_token;
    this.expiresAt = Date.now() + data.expires_in * 1000;

    return this.accessToken;
  }
}

// Usage
const auth = new ClientCredentialsAuth(
  'https://oauth.example.com/token',
  process.env.CLIENT_ID!,
  process.env.CLIENT_SECRET!,
  ['read', 'write']
);

const client = new BearerTokenClient(
  'https://api.example.com',
  () => auth.getAccessToken()
);
```

---

## JWT Handling

### JWT Structure

```typescript
interface JWTHeader {
  alg: string;
  typ: string;
}

interface JWTPayload {
  sub: string;          // Subject (user ID)
  iss: string;          // Issuer
  aud: string | string[]; // Audience
  exp: number;          // Expiration (Unix timestamp)
  iat: number;          // Issued at
  nbf?: number;         // Not before
  jti?: string;         // JWT ID
  [key: string]: unknown;
}

function decodeJWT(token: string): { header: JWTHeader; payload: JWTPayload } {
  const [headerB64, payloadB64] = token.split('.');

  return {
    header: JSON.parse(atob(headerB64)),
    payload: JSON.parse(atob(payloadB64)),
  };
}

function isTokenExpired(token: string, bufferSeconds: number = 0): boolean {
  const { payload } = decodeJWT(token);
  return Date.now() >= (payload.exp - bufferSeconds) * 1000;
}
```

### JWT Validation (Client-Side)

```typescript
// Note: Full JWT verification requires server-side validation
// Client-side can only check claims, not signature

function validateJWTClaims(
  token: string,
  options: {
    issuer?: string;
    audience?: string;
  }
): void {
  const { payload } = decodeJWT(token);

  // Check expiration
  if (Date.now() >= payload.exp * 1000) {
    throw new AuthenticationError('Token expired');
  }

  // Check not-before
  if (payload.nbf && Date.now() < payload.nbf * 1000) {
    throw new AuthenticationError('Token not yet valid');
  }

  // Check issuer
  if (options.issuer && payload.iss !== options.issuer) {
    throw new AuthenticationError('Invalid issuer');
  }

  // Check audience
  if (options.audience) {
    const audiences = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
    if (!audiences.includes(options.audience)) {
      throw new AuthenticationError('Invalid audience');
    }
  }
}
```

---

## HMAC Signature (Webhooks)

### Verifying Webhook Signatures

```typescript
async function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): Promise<boolean> {
  const encoder = new TextEncoder();

  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signatureBuffer = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(payload)
  );

  const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  // Constant-time comparison to prevent timing attacks
  return timingSafeEqual(signature, expectedSignature);
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;

  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

// Usage in webhook handler
app.post('/webhook', async (req, res) => {
  const signature = req.headers['x-signature'] as string;
  const payload = JSON.stringify(req.body);

  const isValid = await verifyWebhookSignature(
    payload,
    signature,
    process.env.WEBHOOK_SECRET!
  );

  if (!isValid) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  // Process webhook...
});
```

### Signing Requests

```typescript
async function signRequest(
  method: string,
  path: string,
  body: string,
  secret: string,
  timestamp: number = Date.now()
): Promise<string> {
  const message = `${timestamp}.${method}.${path}.${body}`;

  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(message)
  );

  return Array.from(new Uint8Array(signature))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

// Usage
const timestamp = Date.now();
const signature = await signRequest('POST', '/orders', JSON.stringify(body), secret, timestamp);

fetch('/orders', {
  method: 'POST',
  headers: {
    'X-Timestamp': timestamp.toString(),
    'X-Signature': signature,
  },
  body: JSON.stringify(body),
});
```

---

## Secure Token Storage

### Browser Storage

```typescript
// ❌ localStorage - vulnerable to XSS
localStorage.setItem('token', accessToken);

// ✅ httpOnly cookie (set by server)
// Token stored in cookie, not accessible to JS

// ✅ In-memory only (lost on refresh, but secure)
class InMemoryTokenStore {
  private token: string | null = null;

  set(token: string): void {
    this.token = token;
  }

  get(): string | null {
    return this.token;
  }

  clear(): void {
    this.token = null;
  }
}

// ✅ Encrypted storage (if must persist)
class EncryptedTokenStore {
  private key: CryptoKey | null = null;

  async init(): Promise<void> {
    this.key = await crypto.subtle.generateKey(
      { name: 'AES-GCM', length: 256 },
      true,
      ['encrypt', 'decrypt']
    );
  }

  async set(token: string): Promise<void> {
    if (!this.key) throw new Error('Store not initialized');

    const iv = crypto.getRandomValues(new Uint8Array(12));
    const encoded = new TextEncoder().encode(token);

    const encrypted = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv },
      this.key,
      encoded
    );

    const data = {
      iv: Array.from(iv),
      data: Array.from(new Uint8Array(encrypted)),
    };

    sessionStorage.setItem('encryptedToken', JSON.stringify(data));
  }

  async get(): Promise<string | null> {
    if (!this.key) throw new Error('Store not initialized');

    const stored = sessionStorage.getItem('encryptedToken');
    if (!stored) return null;

    const { iv, data } = JSON.parse(stored);

    const decrypted = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: new Uint8Array(iv) },
      this.key,
      new Uint8Array(data)
    );

    return new TextDecoder().decode(decrypted);
  }
}
```

### React Native / Mobile

```typescript
// ✅ Use secure storage
import * as SecureStore from 'expo-secure-store';

// Or react-native-keychain
import * as Keychain from 'react-native-keychain';

class SecureTokenStore {
  async setTokens(tokens: TokenPair): Promise<void> {
    await SecureStore.setItemAsync('tokens', JSON.stringify(tokens));
  }

  async getTokens(): Promise<TokenPair | null> {
    const stored = await SecureStore.getItemAsync('tokens');
    return stored ? JSON.parse(stored) : null;
  }

  async clearTokens(): Promise<void> {
    await SecureStore.deleteItemAsync('tokens');
  }
}
```

---

## Auth Error Handling

### 401 Interceptor with Refresh

```typescript
function createAuthInterceptor(
  tokenManager: TokenManager,
  onAuthFailure: () => void
) {
  let isRefreshing = false;
  let refreshSubscribers: Array<(token: string) => void> = [];

  function subscribeTokenRefresh(callback: (token: string) => void) {
    refreshSubscribers.push(callback);
  }

  function onTokenRefreshed(token: string) {
    refreshSubscribers.forEach(callback => callback(token));
    refreshSubscribers = [];
  }

  return async (response: Response, retry: () => Promise<Response>): Promise<Response> => {
    if (response.status !== 401) {
      return response;
    }

    if (!isRefreshing) {
      isRefreshing = true;

      try {
        await tokenManager.refresh();
        const newToken = await tokenManager.getAccessToken();
        isRefreshing = false;
        onTokenRefreshed(newToken);
        return retry();
      } catch (error) {
        isRefreshing = false;
        onAuthFailure();
        throw error;
      }
    }

    // Wait for token refresh
    return new Promise((resolve) => {
      subscribeTokenRefresh(async () => {
        resolve(retry());
      });
    });
  };
}
```
