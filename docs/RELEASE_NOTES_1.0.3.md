# Cut & Move 1.0.3

- Fix Launch at Login incorrectly reporting that an app installed in Applications must be moved there.
- Attempt login-item registration when macOS reports the service as missing, and show the actual registration error if it fails.
- Handle approval-required results, report unconfirmed registration, and clear stale errors when the service becomes enabled.
- Add regression coverage for missing-service registration, approval, errors, retries, and status recovery.

Requires macOS 26.1+. The local v1.0.3 build is Developer ID signed and Apple notarized. GitHub's published download remains v1.0.2 until v1.0.3 is explicitly published.
