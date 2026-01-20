# Deployment Strategies Reference

Comprehensive guide to deployment strategies and their implementation.

## Strategy Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT STRATEGY MATRIX                       │
├────────────────┬──────────┬──────────┬──────────┬─────────────────┤
│ Strategy       │ Downtime │ Rollback │ Risk     │ Infrastructure  │
├────────────────┼──────────┼──────────┼──────────┼─────────────────┤
│ Direct/Basic   │ Yes      │ Slow     │ High     │ Minimal         │
│ Rolling        │ No       │ Medium   │ Medium   │ Normal          │
│ Blue-Green     │ No       │ Fast     │ Low      │ 2x resources    │
│ Canary         │ No       │ Fast     │ Lowest   │ +10-20%         │
│ Feature Flags  │ No       │ Instant  │ Lowest   │ Minimal         │
└────────────────┴──────────┴──────────┴──────────┴─────────────────┘
```

## Blue-Green Deployment

**Concept**: Maintain two identical production environments. Deploy to inactive, then switch traffic.

```
                    Load Balancer
                         │
              ┌──────────┴──────────┐
              │                     │
         ┌────▼────┐          ┌─────▼───┐
         │  Blue   │          │  Green  │
         │ (Live)  │          │ (Idle)  │
         │  v1.0   │          │  v1.1   │
         └─────────┘          └─────────┘
         
After switch:
                    Load Balancer
                         │
              ┌──────────┴──────────┐
              │                     │
         ┌────▼────┐          ┌─────▼───┐
         │  Blue   │          │  Green  │
         │ (Idle)  │          │ (Live)  │
         │  v1.0   │          │  v1.1   │
         └─────────┘          └─────────┘
```

### GitHub Actions Implementation

```yaml
name: Blue-Green Deploy

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1

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
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Get current environment
        id: current
        run: |
          CURRENT=$(aws elbv2 describe-rules \
            --listener-arn ${{ secrets.ALB_LISTENER_ARN }} \
            --query "Rules[?Priority=='1'].Actions[0].TargetGroupArn" \
            --output text)
          
          if [[ $CURRENT == *"blue"* ]]; then
            echo "current=blue" >> $GITHUB_OUTPUT
            echo "target=green" >> $GITHUB_OUTPUT
          else
            echo "current=green" >> $GITHUB_OUTPUT
            echo "target=blue" >> $GITHUB_OUTPUT
          fi
      
      - name: Deploy to ${{ steps.current.outputs.target }}
        run: |
          aws deploy create-deployment \
            --application-name myapp \
            --deployment-group-name ${{ steps.current.outputs.target }}-group \
            --s3-location bucket=myapp-artifacts,key=app.zip,bundleType=zip
      
      - name: Run smoke tests
        run: |
          TARGET_URL="https://${{ steps.current.outputs.target }}.myapp.internal"
          ./scripts/smoke-test.sh $TARGET_URL
      
      - name: Switch traffic
        run: |
          aws elbv2 modify-rule \
            --rule-arn ${{ secrets.ALB_RULE_ARN }} \
            --actions Type=forward,TargetGroupArn=${{ secrets.TG_ARN_PREFIX }}-${{ steps.current.outputs.target }}
      
      - name: Verify switch
        run: |
          sleep 30
          ./scripts/verify-production.sh
```

### Kubernetes Implementation

```yaml
# blue-green-switch.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: green  # Switch between 'blue' and 'green'
  ports:
    - port: 80
      targetPort: 8080
---
# Deploy new version to green
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
        - name: myapp
          image: myapp:v1.1
          ports:
            - containerPort: 8080
```

```bash
# Deployment script
#!/bin/bash
set -euo pipefail

CURRENT=$(kubectl get svc myapp -o jsonpath='{.spec.selector.version}')
TARGET=$([ "$CURRENT" = "blue" ] && echo "green" || echo "blue")

echo "Deploying to $TARGET environment..."

# Deploy new version
kubectl set image deployment/myapp-$TARGET myapp=myapp:$VERSION

# Wait for rollout
kubectl rollout status deployment/myapp-$TARGET

# Run smoke tests
./smoke-test.sh http://myapp-$TARGET.default.svc.cluster.local

# Switch traffic
kubectl patch svc myapp -p "{\"spec\":{\"selector\":{\"version\":\"$TARGET\"}}}"

echo "Switched traffic to $TARGET"
```

## Canary Deployment

**Concept**: Gradually shift traffic to new version while monitoring for issues.

```
Phase 1: 10% to canary
┌─────────────────────────────────────────────┐
│ █████████████████████████████████████████░░ │ ← 90% stable
│ ░░░░                                        │ ← 10% canary
└─────────────────────────────────────────────┘

Phase 2: 50% to canary (if healthy)
┌─────────────────────────────────────────────┐
│ █████████████████████░░░░░░░░░░░░░░░░░░░░░░ │ ← 50% stable
│ ░░░░░░░░░░░░░░░░░░░░░░                      │ ← 50% canary
└─────────────────────────────────────────────┘

Phase 3: 100% to canary (promotion)
┌─────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ ← 100% canary
└─────────────────────────────────────────────┘
```

### GitHub Actions with AWS ALB

```yaml
name: Canary Deploy

on:
  push:
    branches: [main]

jobs:
  canary:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Deploy canary (10%)
        run: |
          aws elbv2 modify-rule \
            --rule-arn ${{ secrets.ALB_RULE_ARN }} \
            --actions '[
              {"Type":"forward","ForwardConfig":{
                "TargetGroups":[
                  {"TargetGroupArn":"${{ secrets.STABLE_TG }}","Weight":90},
                  {"TargetGroupArn":"${{ secrets.CANARY_TG }}","Weight":10}
                ]
              }}
            ]'
      
      - name: Monitor canary (5 min)
        run: |
          for i in {1..5}; do
            ERROR_RATE=$(aws cloudwatch get-metric-statistics \
              --namespace AWS/ApplicationELB \
              --metric-name HTTPCode_Target_5XX_Count \
              --dimensions Name=TargetGroup,Value=${{ secrets.CANARY_TG_NAME }} \
              --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
              --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
              --period 60 \
              --statistics Sum \
              --query 'Datapoints[0].Sum' --output text)
            
            if [ "$ERROR_RATE" != "None" ] && [ "$ERROR_RATE" -gt 10 ]; then
              echo "Error rate too high, rolling back"
              exit 1
            fi
            
            echo "Canary healthy, error rate: $ERROR_RATE"
            sleep 60
          done
      
      - name: Promote canary (50%)
        run: |
          aws elbv2 modify-rule \
            --rule-arn ${{ secrets.ALB_RULE_ARN }} \
            --actions '[
              {"Type":"forward","ForwardConfig":{
                "TargetGroups":[
                  {"TargetGroupArn":"${{ secrets.STABLE_TG }}","Weight":50},
                  {"TargetGroupArn":"${{ secrets.CANARY_TG }}","Weight":50}
                ]
              }}
            ]'
      
      - name: Monitor (5 min)
        run: ./scripts/monitor-canary.sh
      
      - name: Full promotion (100%)
        run: |
          aws elbv2 modify-rule \
            --rule-arn ${{ secrets.ALB_RULE_ARN }} \
            --actions '[
              {"Type":"forward","ForwardConfig":{
                "TargetGroups":[
                  {"TargetGroupArn":"${{ secrets.CANARY_TG }}","Weight":100}
                ]
              }}
            ]'
      
      - name: Rollback on failure
        if: failure()
        run: |
          aws elbv2 modify-rule \
            --rule-arn ${{ secrets.ALB_RULE_ARN }} \
            --actions '[
              {"Type":"forward","ForwardConfig":{
                "TargetGroups":[
                  {"TargetGroupArn":"${{ secrets.STABLE_TG }}","Weight":100}
                ]
              }}
            ]'
```

### Kubernetes with Istio

```yaml
# VirtualService for traffic splitting
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
    - myapp
  http:
    - route:
        - destination:
            host: myapp
            subset: stable
          weight: 90
        - destination:
            host: myapp
            subset: canary
          weight: 10
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp
spec:
  host: myapp
  subsets:
    - name: stable
      labels:
        version: stable
    - name: canary
      labels:
        version: canary
```

```bash
# Canary promotion script
#!/bin/bash
set -euo pipefail

WEIGHTS=(10 25 50 75 100)

for weight in "${WEIGHTS[@]}"; do
  stable_weight=$((100 - weight))
  
  echo "Setting canary to $weight%..."
  
  kubectl patch virtualservice myapp --type=json -p="[
    {\"op\": \"replace\", \"path\": \"/spec/http/0/route/0/weight\", \"value\": $stable_weight},
    {\"op\": \"replace\", \"path\": \"/spec/http/0/route/1/weight\", \"value\": $weight}
  ]"
  
  echo "Monitoring for 2 minutes..."
  sleep 120
  
  # Check error rate
  ERROR_RATE=$(kubectl exec -n istio-system deploy/prometheus -- \
    curl -s 'localhost:9090/api/v1/query?query=sum(rate(istio_requests_total{destination_service="myapp",response_code=~"5.."}[5m]))/sum(rate(istio_requests_total{destination_service="myapp"}[5m]))' \
    | jq -r '.data.result[0].value[1] // "0"')
  
  if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
    echo "Error rate $ERROR_RATE exceeds threshold, rolling back!"
    kubectl patch virtualservice myapp --type=json -p="[
      {\"op\": \"replace\", \"path\": \"/spec/http/0/route/0/weight\", \"value\": 100},
      {\"op\": \"replace\", \"path\": \"/spec/http/0/route/1/weight\", \"value\": 0}
    ]"
    exit 1
  fi
  
  echo "Canary at $weight% healthy (error rate: $ERROR_RATE)"
done

echo "Canary fully promoted!"
```

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
