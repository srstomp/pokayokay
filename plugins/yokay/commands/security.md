---
description: Conduct security audit of code or configuration
argument-hint: <area-to-audit>
skill: security-audit
---

# Security Audit Workflow

Security audit: `$ARGUMENTS`

## Agent Delegation

**Delegate the security scanning to the `yokay-security-scanner` agent** for isolated execution. This keeps verbose scan output separate and enforces read-only constraints.

```
Use the yokay-security-scanner agent to scan: $ARGUMENTS
Return the severity summary and critical/high findings to this conversation.
```

The agent will:
1. Scan for OWASP Top 10 vulnerabilities
2. Check for secrets exposure, injection risks, XSS
3. Review authentication/authorization patterns
4. Return findings classified by severity (Critical/High/Medium/Low)

After receiving the agent's findings, continue with remediation task creation below.

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

- `/pokayokay:api` - Secure API design
- `/pokayokay:cicd` - Security in pipelines
- `/pokayokay:work` - Implement fixes

## Skill Integration

When security audit involves:
- **API security** → Also load `api-design` skill
- **Database security** → Also load `database-design` skill
- **Infrastructure** → Also load `ci-cd-expert` skill
