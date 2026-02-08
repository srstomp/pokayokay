# Authentication: API Keys & Bearer Tokens

Implementing API key and bearer token auth for API integrations.

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
// Load from environment
const apiKey = process.env.API_KEY;

// Validate at startup
if (!apiKey) {
  throw new Error('API_KEY environment variable is required');
}

// Don't log
console.log('Making request with key:', apiKey); // NEVER

// Rotate regularly
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
