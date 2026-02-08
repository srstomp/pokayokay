# Authentication: JWT, HMAC & Secure Storage

JWT handling, HMAC webhook signatures, secure token storage, and auth error handling.

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
// localStorage - vulnerable to XSS
localStorage.setItem('token', accessToken);

// httpOnly cookie (set by server)
// Token stored in cookie, not accessible to JS

// In-memory only (lost on refresh, but secure)
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

// Encrypted storage (if must persist)
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
// Use secure storage
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
