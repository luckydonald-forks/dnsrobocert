# Planned Improvements for DNSroboCert

This document outlines optimization opportunities and best practice improvements identified during the project review.

## 🟡 High Priority (Performance & Maintainability)

### 1. Dependency Version Pinning
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

## 🟡 Medium Priority (Code Quality & Developer Experience)

### 2. Docker Security Enhancements
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

### 3. Enhanced Type Hints
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

### 4. Constants Extraction
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

### 5. Structured Logging
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

### 6. Test Coverage Enhancement
**Location**: `test/` directory
**Current State**: Basic unit tests present
**Recommendations**:
- Add integration tests for DNS providers
- Security-focused tests (input validation, injection attacks)
- Error scenario testing
- Add pytest fixtures for common test data

## Implementation Priority

1. **Next Sprint**: Implement High Priority improvements:
   - Dependency version pinning (#1)
2. **Ongoing**: Gradually implement Medium Priority enhancements (#2-6)

## Notes

- All changes should maintain backward compatibility where possible
- Security improvements should be thoroughly tested before deployment
- Consider implementing changes incrementally to minimize disruption
- Update documentation as improvements are implemented
