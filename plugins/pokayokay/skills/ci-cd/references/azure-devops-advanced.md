# Azure DevOps Pipelines: Templates, Environments, and Advanced Patterns

Templates, environments, deployments, conditions, service connections, containers, and complete examples.

## Templates

### Job Template
```yaml
# templates/build-job.yml
parameters:
  - name: nodeVersion
    type: string
    default: '20.x'

jobs:
  - job: Build
    steps:
      - task: NodeTool@0
        inputs:
          versionSpec: ${{ parameters.nodeVersion }}
      - script: npm ci
      - script: npm run build
```

### Using Templates
```yaml
# azure-pipelines.yml
stages:
  - stage: Build
    jobs:
      - template: templates/build-job.yml
        parameters:
          nodeVersion: '20.x'
```

### Stage Template
```yaml
# templates/deploy-stage.yml
parameters:
  - name: environment
    type: string
  - name: serviceConnection
    type: string

stages:
  - stage: Deploy_${{ parameters.environment }}
    jobs:
      - deployment: Deploy
        environment: ${{ parameters.environment }}
        strategy:
          runOnce:
            deploy:
              steps:
                - script: ./deploy.sh ${{ parameters.environment }}
```

### Variable Templates
```yaml
# templates/variables.yml
variables:
  buildConfiguration: 'Release'
  nodeVersion: '20.x'

# azure-pipelines.yml
variables:
  - template: templates/variables.yml
  - name: additionalVar
    value: 'value'
```

## Environments and Deployments

### Deployment Jobs
```yaml
stages:
  - stage: Deploy
    jobs:
      - deployment: DeployWeb
        displayName: 'Deploy to Production'
        environment: production
        strategy:
          runOnce:
            deploy:
              steps:
                - script: ./deploy.sh
```

### Deployment Strategies
```yaml
# Run Once
strategy:
  runOnce:
    deploy:
      steps:
        - script: ./deploy.sh

# Rolling
strategy:
  rolling:
    maxParallel: 2
    deploy:
      steps:
        - script: ./deploy.sh

# Canary
strategy:
  canary:
    increments: [10, 20]
    deploy:
      steps:
        - script: ./deploy.sh $(strategy.increment)
```

### Approvals and Checks
Configure in Environments (UI):
- Pre-deployment approvals
- Gates (Azure Monitor, REST API)
- Exclusive lock
- Business hours

## Conditions

### Basic Conditions
```yaml
steps:
  - script: echo "Always runs"
    condition: always()

  - script: echo "Only on success"
    condition: succeeded()

  - script: echo "Only on failure"
    condition: failed()

  - script: echo "Only on main"
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
```

### Complex Conditions
```yaml
stages:
  - stage: Deploy
    condition: |
      and(
        succeeded(),
        eq(variables['Build.SourceBranch'], 'refs/heads/main'),
        ne(variables['Build.Reason'], 'PullRequest')
      )
```

### Stage/Job Dependencies
```yaml
stages:
  - stage: Build
    jobs:
      - job: BuildJob

  - stage: Test
    dependsOn: Build
    condition: succeeded('Build')

  - stage: Deploy
    dependsOn:
      - Build
      - Test
    condition: |
      and(
        succeeded('Build'),
        succeeded('Test')
      )
```

## Service Connections

### Azure Resource Manager
```yaml
steps:
  - task: AzureCLI@2
    inputs:
      azureSubscription: 'my-azure-connection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az webapp deploy
```

### Docker Registry
```yaml
steps:
  - task: Docker@2
    inputs:
      containerRegistry: 'my-docker-connection'
      repository: 'myapp'
      command: 'buildAndPush'
```

## Container Jobs

```yaml
jobs:
  - job: Build
    container:
      image: node:20-alpine
      options: --user root
    steps:
      - script: npm ci
      - script: npm run build
```

### Container with Services
```yaml
resources:
  containers:
    - container: postgres
      image: postgres:15
      env:
        POSTGRES_USER: test
        POSTGRES_PASSWORD: test
      ports:
        - 5432:5432

jobs:
  - job: Test
    services:
      postgres: postgres
    steps:
      - script: npm test
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test
```

## Complete Example

```yaml
trigger:
  branches:
    include:
      - main
      - release/*
  paths:
    exclude:
      - docs/*
      - '*.md'

pr:
  branches:
    include:
      - main

variables:
  - name: nodeVersion
    value: '20.x'
  - name: npm_config_cache
    value: $(Pipeline.Workspace)/.npm
  - group: production-secrets

stages:
  # Build Stage
  - stage: Build
    jobs:
      - job: Build
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: $(nodeVersion)

          - task: Cache@2
            inputs:
              key: 'npm | "$(Agent.OS)" | package-lock.json'
              path: $(npm_config_cache)

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npm run build
            displayName: 'Build'

          - task: PublishPipelineArtifact@1
            inputs:
              targetPath: 'dist'
              artifact: 'drop'

  # Test Stage
  - stage: Test
    dependsOn: Build
    jobs:
      - job: Lint
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: $(nodeVersion)
          - script: npm ci
          - script: npm run lint

      - job: UnitTest
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: $(nodeVersion)
          - script: npm ci
          - script: npm test -- --coverage
          - task: PublishTestResults@2
            inputs:
              testResultsFormat: 'JUnit'
              testResultsFiles: '**/junit.xml'
          - task: PublishCodeCoverageResults@2
            inputs:
              summaryFileLocation: 'coverage/cobertura.xml'

  # Deploy Staging
  - stage: DeployStaging
    dependsOn: Test
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployStaging
        environment: staging
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadPipelineArtifact@2
                  inputs:
                    artifact: 'drop'
                    path: '$(Pipeline.Workspace)/drop'
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'staging-connection'
                    appName: 'myapp-staging'
                    package: '$(Pipeline.Workspace)/drop'

  # Deploy Production
  - stage: DeployProduction
    dependsOn: DeployStaging
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployProduction
        environment: production
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadPipelineArtifact@2
                  inputs:
                    artifact: 'drop'
                    path: '$(Pipeline.Workspace)/drop'
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'production-connection'
                    appName: 'myapp'
                    package: '$(Pipeline.Workspace)/drop'
```

## Validation

```bash
# Install Azure DevOps CLI extension
az extension add --name azure-devops

# Validate pipeline (requires authentication)
az pipelines validate --yaml-path azure-pipelines.yml --project MyProject

# Or use the web editor validation in Azure DevOps UI
```
