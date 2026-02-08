# Azure DevOps Pipelines: Structure and Configuration

Pipeline structure, triggers, agents, variables, stages, jobs, tasks, caching, and artifacts.

## Pipeline Structure

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  nodeVersion: '20.x'

stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: $(nodeVersion)
          - script: npm ci
          - script: npm run build
```

## Triggers

### Branch Triggers
```yaml
trigger:
  branches:
    include:
      - main
      - release/*
    exclude:
      - feature/experimental/*
  paths:
    include:
      - src/*
    exclude:
      - docs/*
  tags:
    include:
      - v*
```

### PR Triggers
```yaml
pr:
  branches:
    include:
      - main
      - release/*
  paths:
    include:
      - src/*
  drafts: false
```

### Scheduled Triggers
```yaml
schedules:
  - cron: '0 2 * * *'
    displayName: Nightly build
    branches:
      include:
        - main
    always: true
```

### Disable Automatic Triggers
```yaml
trigger: none
pr: none
```

## Agent Pools

### Microsoft-Hosted Agents
```yaml
pool:
  vmImage: 'ubuntu-latest'        # Ubuntu 22.04
  # vmImage: 'ubuntu-20.04'       # Ubuntu 20.04
  # vmImage: 'macos-latest'       # macOS 13
  # vmImage: 'windows-latest'     # Windows Server 2022
```

### Self-Hosted Agents
```yaml
pool:
  name: 'MyAgentPool'
  demands:
    - docker
    - node
```

### Job-Specific Pool
```yaml
jobs:
  - job: Linux
    pool:
      vmImage: 'ubuntu-latest'

  - job: Windows
    pool:
      vmImage: 'windows-latest'
```

## Variables

### Pipeline Variables
```yaml
variables:
  buildConfiguration: 'Release'
  nodeVersion: '20.x'

# Or as list
variables:
  - name: buildConfiguration
    value: 'Release'
  - name: nodeVersion
    value: '20.x'
```

### Variable Groups
```yaml
variables:
  - group: my-variable-group        # From Library
  - name: localVar
    value: 'local value'
```

### Runtime Variables
```yaml
variables:
  - name: dynamicVar
    value: $[variables.staticVar]   # Runtime expression
```

### Predefined Variables
```yaml
steps:
  - script: |
      echo "Build ID: $(Build.BuildId)"
      echo "Source Branch: $(Build.SourceBranch)"
      echo "Commit SHA: $(Build.SourceVersion)"
      echo "Agent OS: $(Agent.OS)"
      echo "Pipeline Workspace: $(Pipeline.Workspace)"
```

### Secret Variables
```yaml
# Define in UI: Pipelines > Edit > Variables

steps:
  - script: |
      echo "Using secret..."
      ./deploy.sh
    env:
      API_KEY: $(apiKey)            # Map secret to env var
```

## Stages, Jobs, and Steps

### Multi-Stage Pipeline
```yaml
stages:
  - stage: Build
    displayName: 'Build Stage'
    jobs:
      - job: BuildJob
        steps:
          - script: npm run build

  - stage: Test
    displayName: 'Test Stage'
    dependsOn: Build
    jobs:
      - job: UnitTests
        steps:
          - script: npm test
      - job: IntegrationTests
        dependsOn: UnitTests
        steps:
          - script: npm run test:integration

  - stage: Deploy
    displayName: 'Deploy Stage'
    dependsOn: Test
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployProd
        environment: production
```

### Parallel Jobs
```yaml
jobs:
  - job: Lint
    steps:
      - script: npm run lint

  - job: Test
    steps:
      - script: npm test

  - job: Build
    dependsOn: []                   # No dependencies = parallel
    steps:
      - script: npm run build
```

### Matrix Strategy
```yaml
jobs:
  - job: Test
    strategy:
      matrix:
        Node18:
          nodeVersion: '18.x'
        Node20:
          nodeVersion: '20.x'
        Node22:
          nodeVersion: '22.x'
      maxParallel: 3
    steps:
      - task: NodeTool@0
        inputs:
          versionSpec: $(nodeVersion)
      - script: npm test
```

## Tasks

### Script Tasks
```yaml
steps:
  # Inline script
  - script: |
      echo "Building..."
      npm run build
    displayName: 'Build project'

  # Bash script
  - bash: |
      set -euo pipefail
      ./build.sh
    displayName: 'Run build script'

  # PowerShell
  - powershell: |
      Write-Host "Building..."
      npm run build
    displayName: 'Build (PowerShell)'
```

### Common Built-in Tasks
```yaml
steps:
  # Checkout
  - checkout: self
    fetchDepth: 0                   # Full history

  # Node.js
  - task: NodeTool@0
    inputs:
      versionSpec: '20.x'

  # npm
  - task: Npm@1
    inputs:
      command: 'ci'

  # .NET
  - task: DotNetCoreCLI@2
    inputs:
      command: 'build'
      projects: '**/*.csproj'

  # Docker
  - task: Docker@2
    inputs:
      command: 'buildAndPush'
      repository: 'myacr.azurecr.io/myapp'
      dockerfile: 'Dockerfile'
      tags: '$(Build.BuildId)'

  # Azure CLI
  - task: AzureCLI@2
    inputs:
      azureSubscription: 'my-subscription'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az webapp deploy --name myapp
```

## Caching

### Basic Caching
```yaml
variables:
  npm_config_cache: $(Pipeline.Workspace)/.npm

steps:
  - task: Cache@2
    inputs:
      key: 'npm | "$(Agent.OS)" | package-lock.json'
      restoreKeys: |
        npm | "$(Agent.OS)"
      path: $(npm_config_cache)
    displayName: 'Cache npm'

  - script: npm ci
```

### Multiple Caches
```yaml
steps:
  - task: Cache@2
    inputs:
      key: 'npm | package-lock.json'
      path: $(npm_config_cache)
    displayName: 'Cache npm'

  - task: Cache@2
    inputs:
      key: 'build | "$(Build.SourceVersion)"'
      path: dist
    displayName: 'Cache build'
```

## Artifacts

### Publish Artifacts
```yaml
steps:
  - script: npm run build

  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: 'dist'
      artifactName: 'drop'

  # Or newer task
  - task: PublishPipelineArtifact@1
    inputs:
      targetPath: 'dist'
      artifact: 'drop'
```

### Download Artifacts
```yaml
steps:
  - task: DownloadPipelineArtifact@2
    inputs:
      buildType: 'current'
      artifactName: 'drop'
      targetPath: '$(Pipeline.Workspace)/drop'
```
