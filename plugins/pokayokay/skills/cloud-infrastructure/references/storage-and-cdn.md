# Storage and CDN

S3 configuration, CloudFront distributions, and caching strategies.

## S3 Patterns

### Bucket Configuration

```typescript
const bucket = new s3.Bucket(this, 'Assets', {
  bucketName: `myapp-assets-${props.stage}`,
  encryption: s3.BucketEncryption.S3_MANAGED,
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
  versioned: true,
  lifecycleRules: [
    {
      // Move old versions to cheaper storage
      noncurrentVersionTransitions: [
        { storageClass: s3.StorageClass.INFREQUENT_ACCESS, transitionAfter: cdk.Duration.days(30) },
        { storageClass: s3.StorageClass.GLACIER, transitionAfter: cdk.Duration.days(90) },
      ],
      noncurrentVersionExpiration: cdk.Duration.days(365),
    },
    {
      // Clean up incomplete multipart uploads
      abortIncompleteMultipartUploadAfter: cdk.Duration.days(7),
    },
  ],
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});
```

### Storage Classes

| Class | Access Pattern | Cost (GB/mo) | Retrieval |
|-------|---------------|--------------|-----------|
| Standard | Frequent | $0.023 | Instant |
| IA | Infrequent (>30 days) | $0.0125 | Instant, per-request fee |
| Glacier Instant | Archive, instant access | $0.004 | Instant, higher retrieval |
| Glacier Flexible | Archive, hours | $0.0036 | 1-12 hours |
| Glacier Deep | Long-term archive | $0.00099 | 12-48 hours |

### Presigned URLs

```typescript
// Generate upload URL (server-side)
const command = new PutObjectCommand({
  Bucket: 'myapp-uploads',
  Key: `uploads/${userId}/${filename}`,
  ContentType: contentType,
});
const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });

// Generate download URL
const downloadCommand = new GetObjectCommand({
  Bucket: 'myapp-assets',
  Key: assetKey,
});
const downloadUrl = await getSignedUrl(s3Client, downloadCommand, { expiresIn: 300 });
```

### S3 Event Notifications

```typescript
// Trigger Lambda on upload
bucket.addEventNotification(
  s3.EventType.OBJECT_CREATED,
  new s3n.LambdaDestination(processorFn),
  { prefix: 'uploads/', suffix: '.jpg' }
);
```

## CloudFront

### Static Website Distribution

```typescript
const distribution = new cloudfront.Distribution(this, 'CDN', {
  defaultBehavior: {
    origin: new origins.S3Origin(bucket),
    viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
    cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
  },
  additionalBehaviors: {
    '/api/*': {
      origin: new origins.HttpOrigin(apiDomain),
      cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
      originRequestPolicy: cloudfront.OriginRequestPolicy.ALL_VIEWER_EXCEPT_HOST_HEADER,
      allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
    },
  },
  defaultRootObject: 'index.html',
  errorResponses: [
    // SPA routing: serve index.html for 404s
    {
      httpStatus: 404,
      responsePagePath: '/index.html',
      responseHttpStatus: 200,
      ttl: cdk.Duration.seconds(0),
    },
  ],
});
```

### Cache Policies

| Policy | TTL | Headers | Use When |
|--------|-----|---------|----------|
| CACHING_OPTIMIZED | 24h default | None | Static assets with cache-busting |
| CACHING_DISABLED | 0 | All | API calls, dynamic content |
| Custom | Varies | Selected | Fine-grained control |

### Cache Invalidation

```bash
# Invalidate specific paths
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/index.html" "/config.json"

# Invalidate everything (expensive at scale)
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/*"
```

**Better approach:** Use content-addressed filenames (e.g., `main.abc123.js`) and only invalidate `index.html`.

### Custom Domain with ACM

```typescript
const certificate = new acm.Certificate(this, 'Cert', {
  domainName: 'cdn.example.com',
  validation: acm.CertificateValidation.fromDns(hostedZone),
});

const distribution = new cloudfront.Distribution(this, 'CDN', {
  domainNames: ['cdn.example.com'],
  certificate,
  // ...
});

new route53.ARecord(this, 'CdnRecord', {
  zone: hostedZone,
  recordName: 'cdn',
  target: route53.RecordTarget.fromAlias(
    new targets.CloudFrontTarget(distribution)
  ),
});
```

## Caching Strategy

### Cache Hierarchy

```
Browser Cache (Cache-Control headers)
  ↓ miss
CloudFront Edge (regional PoP)
  ↓ miss
CloudFront Regional Cache
  ↓ miss
Origin (S3 / ALB / API Gateway)
```

### Cache-Control Headers

```typescript
// Immutable assets (hashed filenames)
'Cache-Control': 'public, max-age=31536000, immutable'

// HTML files (always revalidate)
'Cache-Control': 'no-cache'  // Still caches but always checks freshness

// API responses (short cache)
'Cache-Control': 'public, max-age=60, s-maxage=300'

// Private data (no CDN caching)
'Cache-Control': 'private, no-store'
```

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|-------------|---------|--------|
| Public S3 buckets | Security risk | CloudFront + OAC |
| No lifecycle rules | Infinite storage costs | IA after 30d, Glacier after 90d |
| Invalidate /* on every deploy | Expensive, defeats caching | Content-addressed filenames |
| No versioning on important buckets | Can't recover deleted files | Enable versioning |
| Serving API through CloudFront without CORS | Cross-origin failures | Configure CORS on origin |
