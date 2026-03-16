---
name: security-audit
description: >
  Security review and vulnerability scanning for codebases.
  Use when the user asks for security review, audit, vulnerability check,
  or mentions "security", "vulnerabilities", "OWASP", "pentest", "CVE",
  "secrets scan", "dependency audit".
---

# Security Audit

Perform a structured security review of the codebase or specific changes.

## Review Areas

### Input Validation & Injection
- SQL injection (parameterized queries? ORM misuse?)
- XSS (user input rendered without sanitization?)
- Command injection (shell exec with user input?)
- Path traversal (user-controlled file paths?)

### Authentication & Authorization
- Auth bypass possibilities
- Missing authorization checks on endpoints
- Hardcoded credentials or API keys
- JWT issues (none algorithm, weak secret, no expiry)
- ASP.NET: `[Authorize]` coverage, policy-based auth correctness, cookie security flags

### Data Protection
- Sensitive data in logs or error messages
- PII exposure in API responses
- Missing encryption for data at rest / in transit
- Secrets in source code or config files
- ASP.NET: Data Protection API usage, connection string exposure, HTTPS enforcement

### Dependencies
- Known CVEs in dependencies (check package.json, *.csproj)
- Outdated packages with security patches available
- Typosquatting risk in package names

### Configuration
- Debug mode / detailed errors enabled in production
- CORS misconfiguration
- Missing security headers (CSP, HSTS, X-Frame-Options)
- Default credentials or open admin panels

## Output
For each finding:
- **Risk**: Critical / High / Medium / Low / Info
- **Location**: file:line
- **Issue**: what is vulnerable
- **Impact**: what an attacker could do
- **Remediation**: specific fix with code example
