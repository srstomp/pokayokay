---
description: Create or improve documentation
argument-hint: <documentation-task>
skill: documentation
---

# Documentation Workflow

Create documentation for: `$ARGUMENTS`

## Steps

### 1. Identify Documentation Type
From `$ARGUMENTS`, determine:
- **README**: Project overview and setup
- **API docs**: Endpoint reference
- **ADR**: Architecture Decision Record
- **User guide**: How-to instructions
- **Contributing**: Developer onboarding
- **Changelog**: Version history

### 2. Identify Audience
- Developers (internal team)
- External developers (API consumers)
- End users
- Operations team

### 3. Gather Information
- Read relevant code
- Interview stakeholders (if needed)
- Review existing docs
- Check issue tracker for common questions

### 4. Generate Documentation

**For README:**
- Project description
- Quick start
- Prerequisites
- Installation
- Usage examples
- Configuration
- Contributing link

**For API Docs:**
- Endpoint reference
- Request/response examples
- Authentication
- Error codes
- Rate limits

**For ADR:**
- Title and date
- Status (proposed/accepted/deprecated)
- Context (problem)
- Decision (solution)
- Consequences (trade-offs)

### 5. Review and Validate
- Technical accuracy
- Clarity for audience
- Complete examples
- Working code samples

### 6. Create Follow-up Tasks
```bash
npx @stevestomp/ohno-cli create "Docs: [specific doc]" -t docs
```

## Covers
- README creation
- API documentation
- Architecture Decision Records (ADR)
- User guides and tutorials
- Developer onboarding
- Changelog management

## Related Commands

- `/yokay:api` - Document API design
- `/yokay:arch` - Document architecture
- `/yokay:work` - Implement documentation

## Skill Integration

When documentation involves:
- **API reference** → Also load `api-design` skill
- **Architecture docs** → Also load `architecture-review` skill
- **Database docs** → Also load `database-design` skill
