# Deployment Strategies: Rolling, Feature Flags, and Rollback

Rolling deployments, feature flags, rollback strategies, health checks, and strategy selection guide.

## Rolling Deployment

**Concept**: Gradually replace old instances with new ones.

```
Initial:    [v1] [v1] [v1] [v1] [v1]
Step 1:     [v2] [v1] [v1] [v1] [v1]
Step 2:     [v2] [v2] [v1] [v1] [v1]
Step 3:     [v2] [v2] [v2] [v1] [v1]
Step 4:     [v2] [v2] [v2] [v2] [v1]
Final:      [v2] [v2] [v2] [v2] [v2]
```

### Kubernetes Rolling Update

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # Max pods that can be unavailable
      maxSurge: 1            # Max pods over desired count
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:v1.1
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 10
```

### GitHub Actions with ECS

```yaml
name: Rolling Deploy to ECS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to ECR
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push
        run: |
          docker build -t ${{ secrets.ECR_REPO }}:${{ github.sha }} .
          docker push ${{ secrets.ECR_REPO }}:${{ github.sha }}

      - name: Update task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: myapp
          image: ${{ secrets.ECR_REPO }}:${{ github.sha }}

      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: myapp-service
          cluster: production
          wait-for-service-stability: true
```

## Feature Flags

**Concept**: Deploy code with features disabled, enable progressively.

### LaunchDarkly Integration

```yaml
name: Deploy with Feature Flags

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy code
        run: ./deploy.sh

      - name: Enable feature for internal users
        uses: launchdarkly/gha-flags@v0.2.0
        with:
          sdk-key: ${{ secrets.LD_SDK_KEY }}
          flag-key: new-checkout-flow
          flag-value: 'true'
          targets: 'internal-users'

      - name: Monitor (1 hour)
        run: sleep 3600

      - name: Enable for 10% of users
        uses: launchdarkly/gha-flags@v0.2.0
        with:
          sdk-key: ${{ secrets.LD_SDK_KEY }}
          flag-key: new-checkout-flow
          percentage: 10
```

### Simple Feature Flag Implementation

```javascript
// feature-flags.js
const flags = {
  'new-checkout': {
    enabled: process.env.FF_NEW_CHECKOUT === 'true',
    percentage: parseInt(process.env.FF_NEW_CHECKOUT_PCT || '0'),
  },
};

export function isEnabled(flagName, userId) {
  const flag = flags[flagName];
  if (!flag) return false;
  if (!flag.enabled) return false;

  // Deterministic percentage rollout based on user ID
  const hash = hashCode(userId + flagName);
  return (hash % 100) < flag.percentage;
}
```

```yaml
# Gradual rollout
name: Feature Flag Rollout

on:
  workflow_dispatch:
    inputs:
      percentage:
        description: 'Rollout percentage'
        required: true
        default: '10'

jobs:
  rollout:
    runs-on: ubuntu-latest
    steps:
      - name: Update feature flag
        run: |
          aws ssm put-parameter \
            --name "/app/feature-flags/new-checkout-pct" \
            --value "${{ inputs.percentage }}" \
            --type String \
            --overwrite

      - name: Trigger config reload
        run: |
          aws lambda invoke \
            --function-name reload-feature-flags \
            /dev/null
```

## Rollback Strategies

### Automatic Rollback

```yaml
# GitHub Actions
- name: Deploy
  id: deploy
  run: ./deploy.sh

- name: Verify deployment
  id: verify
  run: |
    ./health-check.sh || exit 1

- name: Rollback on failure
  if: failure() && steps.deploy.outcome == 'success'
  run: |
    ./rollback.sh
```

### Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/myapp

# Rollback to previous
kubectl rollout undo deployment/myapp

# Rollback to specific revision
kubectl rollout undo deployment/myapp --to-revision=3

# Check rollout status
kubectl rollout status deployment/myapp
```

### Blue-Green Instant Rollback

```bash
#!/bin/bash
# rollback.sh

CURRENT=$(aws elbv2 describe-rules \
  --listener-arn $ALB_LISTENER_ARN \
  --query "Rules[?Priority=='1'].Actions[0].TargetGroupArn" \
  --output text)

if [[ $CURRENT == *"green"* ]]; then
  ROLLBACK_TO=$BLUE_TG_ARN
else
  ROLLBACK_TO=$GREEN_TG_ARN
fi

aws elbv2 modify-rule \
  --rule-arn $ALB_RULE_ARN \
  --actions Type=forward,TargetGroupArn=$ROLLBACK_TO

echo "Rolled back to previous environment"
```

## Health Checks and Gates

### Deployment Gates

```yaml
# GitHub Actions
jobs:
  deploy:
    steps:
      - name: Deploy
        run: ./deploy.sh

      - name: Wait for healthy
        run: |
          for i in {1..30}; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://myapp.com/health)
            if [ "$STATUS" = "200" ]; then
              echo "Application healthy"
              exit 0
            fi
            echo "Waiting for healthy status... ($i/30)"
            sleep 10
          done
          echo "Health check failed"
          exit 1

      - name: Run smoke tests
        run: npm run test:smoke

      - name: Check error rate
        run: |
          ERROR_RATE=$(./scripts/get-error-rate.sh)
          if (( $(echo "$ERROR_RATE > 1" | bc -l) )); then
            echo "Error rate too high: $ERROR_RATE%"
            exit 1
          fi
```

### Progressive Delivery Checklist

```yaml
# deployment-checklist.yml
pre_deployment:
  - [ ] Feature flag disabled
  - [ ] Database migrations applied
  - [ ] Cache warmed
  - [ ] Monitoring dashboards ready

during_deployment:
  - [ ] Canary at 10% - 5 min soak
  - [ ] Error rate < 1%
  - [ ] Latency p99 < baseline + 10%
  - [ ] No critical alerts
  - [ ] Canary at 50% - 10 min soak
  - [ ] Full rollout

post_deployment:
  - [ ] Feature flag enabled
  - [ ] Smoke tests pass
  - [ ] Key metrics stable
  - [ ] Documentation updated
```

## Strategy Selection Guide

| Scenario | Recommended Strategy |
|----------|---------------------|
| First deploy to prod | Blue-Green |
| Database schema change | Blue-Green + Feature Flag |
| Minor bug fix | Rolling |
| New feature launch | Canary + Feature Flag |
| Performance optimization | Canary |
| Hotfix | Rolling (fast) |
| Major refactor | Blue-Green |
| API breaking change | Feature Flag + Canary |
