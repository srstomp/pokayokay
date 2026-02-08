# CI/CD Debugging: Error Categories

Systematic approach to diagnosing pipeline failures, organized by error category.

## Debugging Framework

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEBUGGING WORKFLOW                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. READ THE ERROR       ->  Full message, scroll up            │
│         |                                                       │
│  2. IDENTIFY CATEGORY    ->  Build? Test? Deploy? Environment?  │
│         |                                                       │
│  3. REPRODUCE LOCALLY    ->  Same commands, same env            │
│         |                                                       │
│  4. ISOLATE THE ISSUE    ->  Minimal reproduction               │
│         |                                                       │
│  5. FIX AND VERIFY       ->  Apply fix, confirm in CI           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Error Categories

### 1. Environment Errors

**Symptoms**: "Command not found", "Package not found", version mismatches

**Common causes**:
- Missing system dependencies
- Wrong runtime version
- Missing environment variables
- PATH not configured

**Debug steps**:
```yaml
# Print environment info
- name: Debug environment
  run: |
    echo "PATH: $PATH"
    echo "Node: $(node --version 2>/dev/null || echo 'not found')"
    echo "Python: $(python --version 2>/dev/null || echo 'not found')"
    echo "Docker: $(docker --version 2>/dev/null || echo 'not found')"
    env | sort
```

**Fixes**:
```yaml
# GitHub Actions - Ensure tool version
- uses: actions/setup-node@v4
  with:
    node-version: '20'

# GitLab CI - Specify image with tools
image: node:20

# Install missing tools
- name: Install dependencies
  run: |
    apt-get update
    apt-get install -y jq curl
```

### 2. Permission Errors

**Symptoms**: "Permission denied", "EACCES", "403 Forbidden"

**Common causes**:
- File not executable
- Secret not accessible
- Token expired/wrong scope
- Directory not writable

**Debug steps**:
```yaml
- name: Debug permissions
  run: |
    echo "Current user: $(whoami)"
    echo "File permissions:"
    ls -la
    echo "Script permissions:"
    ls -la scripts/
    echo "Directory permissions:"
    stat .
```

**Fixes**:
```yaml
# Make script executable
- run: chmod +x ./scripts/deploy.sh

# Check secret is set
- run: |
    if [ -z "$API_KEY" ]; then
      echo "ERROR: API_KEY not set"
      exit 1
    fi
  env:
    API_KEY: ${{ secrets.API_KEY }}

# Fix npm permissions
- run: npm config set cache /tmp/.npm
```

### 3. Network Errors

**Symptoms**: "Connection refused", "Timeout", "ECONNRESET", "SSL error"

**Common causes**:
- Service not ready
- Wrong host/port
- Firewall blocking
- SSL certificate issues

**Debug steps**:
```yaml
- name: Debug network
  run: |
    # Check DNS
    nslookup $HOST || echo "DNS failed"

    # Check port
    nc -zv $HOST $PORT || echo "Port not reachable"

    # Check HTTP
    curl -v $URL || echo "HTTP failed"

    # Check SSL
    openssl s_client -connect $HOST:443 </dev/null
```

**Fixes**:
```yaml
# Wait for service
- name: Wait for DB
  run: |
    for i in {1..30}; do
      pg_isready -h localhost -p 5432 && exit 0
      sleep 2
    done
    exit 1

# Use health check in Docker
services:
  postgres:
    image: postgres:15
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

### 4. Resource Errors

**Symptoms**: "Out of memory", "No space left", "Killed"

**Common causes**:
- Memory limit exceeded
- Disk full
- CPU timeout
- Too many open files

**Debug steps**:
```yaml
- name: Debug resources
  run: |
    echo "Memory:"
    free -h

    echo "Disk:"
    df -h

    echo "Processes:"
    ps aux | head -20
```

**Fixes**:
```yaml
# GitHub Actions - Use larger runner
runs-on: ubuntu-latest-4-cores

# CircleCI - Use larger resource class
resource_class: large

# Clear space before build
- name: Free disk space
  run: |
    sudo rm -rf /usr/share/dotnet
    sudo rm -rf /opt/ghc
    docker system prune -af

# Node.js memory
- run: NODE_OPTIONS="--max-old-space-size=4096" npm run build
```

### 5. Timing Errors

**Symptoms**: "Timeout exceeded", "Build hung", flaky tests

**Common causes**:
- Long-running process
- Deadlock
- Waiting for unavailable resource
- Race condition

**Debug steps**:
```yaml
- name: Debug timing
  run: |
    # Run with timeout and trace
    timeout 300 bash -c '
      set -x
      npm test
    ' || {
      echo "Process timed out or failed"
      # Get process tree
      ps auxf
    }
```

**Fixes**:
```yaml
# Increase timeout
- name: Long test
  run: npm test
  timeout-minutes: 30

# Add explicit timeouts in tests
# jest.config.js
module.exports = {
  testTimeout: 30000,
};

# Split slow tests
- name: Fast tests
  run: npm test -- --testPathIgnorePatterns integration

- name: Slow tests
  run: npm test -- --testPathPattern integration
  timeout-minutes: 20
```

### 6. Caching Errors

**Symptoms**: "Stale dependencies", "Works locally but not CI", inconsistent builds

**Common causes**:
- Cache key collision
- Corrupted cache
- Cache not restored
- Wrong paths cached

**Debug steps**:
```yaml
- name: Debug cache
  run: |
    echo "Cache contents:"
    ls -la node_modules/ 2>/dev/null || echo "node_modules not found"
    ls -la ~/.npm/ 2>/dev/null || echo ".npm not found"

    echo "Package lock:"
    head -20 package-lock.json
```

**Fixes**:
```yaml
# Force cache bust (change version)
- uses: actions/cache@v4
  with:
    path: node_modules
    key: v2-deps-${{ hashFiles('package-lock.json') }}  # Changed v1 to v2

# Verify cache hit
- uses: actions/cache@v4
  id: cache
  with:
    path: node_modules
    key: deps-${{ hashFiles('package-lock.json') }}

- if: steps.cache.outputs.cache-hit != 'true'
  run: npm ci
```

### 7. Docker Errors

**Symptoms**: "Image not found", "Build failed", "Container exited"

**Common causes**:
- Registry auth failed
- Image tag wrong
- Build context issue
- Container crashed

**Debug steps**:
```yaml
- name: Debug Docker
  run: |
    docker info
    docker images
    docker ps -a
    docker logs $CONTAINER_ID 2>/dev/null || echo "No logs"
```

**Fixes**:
```yaml
# Login to registry
- uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

# Check build context
- run: |
    echo "Build context files:"
    cat .dockerignore
    ls -la

# Debug failed build
- run: docker build --progress=plain .
```
