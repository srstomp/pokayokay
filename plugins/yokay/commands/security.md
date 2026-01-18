---
description: Conduct security audit of code or configuration
argument-hint: <area-to-audit>
skill: security-audit
---

# Security Audit Workflow

Security audit: `$ARGUMENTS`

## Steps

### 1. Define Audit Scope
From `$ARGUMENTS`, identify:
- **Code audit**: Specific files/components
- **Dependency audit**: npm/pip packages
- **Configuration audit**: Environment, secrets, infra
- **Architecture audit**: Authentication, authorization flows

### 2. Run Automated Scans
```bash
# Dependency vulnerabilities
npm audit
# or
pnpm audit

# Secret detection
git secrets --scan
```

### 3. Manual Review Checklist

**OWASP Top 10:**
- [ ] Injection (SQL, NoSQL, OS commands)
- [ ] Broken authentication
- [ ] Sensitive data exposure
- [ ] XML external entities (XXE)
- [ ] Broken access control
- [ ] Security misconfiguration
- [ ] Cross-site scripting (XSS)
- [ ] Insecure deserialization
- [ ] Components with known vulnerabilities
- [ ] Insufficient logging/monitoring

### 4. Classify Findings

| Severity | Description | Action |
|----------|-------------|--------|
| Critical | Immediate exploit risk | Fix now |
| High | Significant vulnerability | Fix this sprint |
| Medium | Moderate risk | Plan fix |
| Low | Minor issue | Backlog |
| Info | Best practice | Consider |

### 5. Generate Report
Document findings with:
- Vulnerability description
- Location (file:line)
- Severity and CVSS score
- Remediation steps
- References (CWE, CVE)

### 6. Create Remediation Tasks
```bash
npx @stevestomp/ohno-cli create "Security: Fix [vulnerability]" -t bug -p P0
```

## Covers
- Code security review
- Dependency scanning
- Secret detection
- Authentication/authorization audit
- Input validation
- Output encoding
- OWASP compliance

## Related Commands

- `/yokay:api` - Secure API design
- `/yokay:cicd` - Security in pipelines
- `/yokay:work` - Implement fixes

## Skill Integration

When security audit involves:
- **API security** → Also load `api-design` skill
- **Database security** → Also load `database-design` skill
- **Infrastructure** → Also load `ci-cd-expert` skill
