# Planned Improvements for DNSroboCert

This document outlines optimization opportunities and best practice improvements identified during the project review.

## 🔴 High Priority (Security & Stability)

### 1. Git Dependency Security Risk
**Location**: `pyproject.toml:39`
**Issue**: Dependency on git repository main branch is unstable
**Current**: `dns-lexicon[full] @ git+https://github.com/jonmeacham/dns-lexicon.git@main`
**Recommendation**: Pin to specific commit hash or use published version

### 2. File Permission Validation ✅ COMPLETED
**Location**: `src/dnsrobocert/core/utils.py:65-102`
**Issue**: No validation of permission values
**Status**: ✅ Implemented - Added comprehensive permission validation with error messages
**Implementation**:
```python
# Validate permission ranges
if files_mode > 0o777 or files_mode < 0:
    raise ValueError(f"Invalid files_mode permission value: {oct(files_mode)}. Must be between 0 and 0o777")
if dirs_mode > 0o777 or dirs_mode < 0:
    raise ValueError(f"Invalid dirs_mode permission value: {oct(dirs_mode)}. Must be between 0 and 0o777")
```

## 🟡 Medium Priority (Performance & Maintainability)

### 3. Background Worker Optimization
**Location**: `src/dnsrobocert/core/background.py:48-57`
**Issue**: Inefficient shutdown using `time.sleep()`
**Recommended Fix**:
```python
def _launch_background_jobs(stop_thread: threading.Event, interval: int = 1) -> None:
    def run():
        while not stop_thread.is_set():
            # Use wait() with timeout instead of sleep for faster shutdown
            if stop_thread.wait(timeout=interval):
                break
            schedule.run_pending()
```

### 4. Cryptographic Hash Upgrade ✅ COMPLETED
**Location**: `src/dnsrobocert/core/utils.py:128-136`
**Issue**: MD5 usage for file digests (security concern)
**Status**: ✅ Implemented - Upgraded from MD5 to SHA-256 with chunked reading for memory efficiency
**Implementation**:
```python
def digest(path: str) -> bytes | None:
    if not os.path.exists(path):
        return None
    
    hasher = hashlib.sha256()
    with open(path, "rb") as file_h:
        for chunk in iter(lambda: file_h.read(4096), b""):
            hasher.update(chunk)
    return hasher.digest()
```

### 5. YAML Loading Security
**Location**: `src/dnsrobocert/core/config.py:42`
**Issue**: Direct use of `yaml.load()` with SafeLoader
**Recommended**: Use `yaml.safe_load()` directly for clarity

### 6. Dependency Version Pinning
**Location**: `pyproject.toml`
**Issue**: Loose version constraints for critical security dependencies
**Recommendation**:
```toml
dependencies = [
    "acme>=2.0,<3.0",
    "certbot>=2.0,<3.0",
    "cryptography>=41.0,<42.0",  # More specific for security
    # ... other dependencies
]
```

## 🟢 Low Priority (Code Quality & Developer Experience)

### 7. Docker Security Enhancements
**Location**: `Dockerfile`
**Recommendations**:
- Add non-root user for container execution
- Add health check for container monitoring
```dockerfile
# Add specific user for security
RUN addgroup -g 1001 -S dnsrobocert && \
    adduser -u 1001 -S dnsrobocert -G dnsrobocert

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD python -c "import dnsrobocert; print('healthy')" || exit 1

USER dnsrobocert
```

### 8. Enhanced Type Hints
**Location**: Various files
**Issue**: Some functions lack comprehensive type hints
**Example Enhancement**:
```python
from typing import Dict, List, Optional, Union

def get_certificate(
    config: Dict[str, Any], 
    lineage: str
) -> Optional[Dict[str, Any]]:
    # ... implementation
```

### 9. Constants Extraction
**Location**: Various files
**Issue**: Magic numbers and strings scattered throughout code
**Recommendation**: Create `constants.py`:
```python
# constants.py
DEFAULT_SLEEP_TIME = 30
DEFAULT_MAX_CHECKS = 10
DNS_CHALLENGE_PREFIX = "_acme-challenge"
RANDOM_DELAY_MAX_SECONDS = 21600  # 12 hours
```

### 10. Structured Logging
**Location**: Various files
**Issue**: Basic logging without context
**Recommendation**: Implement structured logging:
```python
import structlog

logger = structlog.get_logger(__name__)

# Usage
logger.info("Certificate processing started", 
           lineage=lineage, 
           domains=domains, 
           profile=profile_name)
```

### 11. Test Coverage Enhancement
**Location**: `test/` directory
**Current State**: Basic unit tests present
**Recommendations**:
- Add integration tests for DNS providers
- Security-focused tests (input validation, injection attacks)
- Error scenario testing
- Add pytest fixtures for common test data

## Implementation Priority

1. **Immediate**: Address High Priority security issues (#1, ~~#2 ✅~~)
2. **Next Sprint**: Implement Medium Priority improvements (#3, ~~#4 ✅~~, #5-6)
3. **Ongoing**: Gradually implement Low Priority enhancements (#7-11)

## Notes

- All changes should maintain backward compatibility where possible
- Security improvements should be thoroughly tested before deployment
- Consider implementing changes incrementally to minimize disruption
- Update documentation as improvements are implemented
