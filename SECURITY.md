# Security Policy

Do not open a public issue containing a credential, token, private hostname,
account identifier, or sensitive path. Use GitHub's private vulnerability
reporting for security-sensitive reports.

This repository intentionally excludes authentication state and secrets. If a
credential is committed, revoke it at the provider first, remove it from the
working tree, and treat Git-history cleanup as a separate containment step.
