# Planned Improvements for DNSroboCert

This document outlines optimization opportunities and best practice improvements identified during the project review.

## ✅ Recently Completed

### 1. Python Version Upgrade ✅ **COMPLETED**
**Location**: `pyproject.toml`, `Dockerfile`, CI/CD workflows
**Previous State**: Supported Python 3.9-3.13, but Python 3.9 constrained dependency upgrades
**Resolution**: Upgraded minimum Python requirement to 3.11+, unlocked latest dependency versions

**Key Findings from Dependency Analysis**:
- **acme/certbot v5.0+** require Python ≥3.10 (latest security/feature updates unavailable)
- **sphinx v8.0+** requires Python ≥3.10 (documentation tooling limited)
- **Several AWS/cloud SDKs** have urllib3 version conflicts with Python 3.9
- **Latest type hint improvements** in Python 3.10+ would enhance code quality

**Recommendation - Phased Approach**:
```toml
# Phase 1: Drop Python 3.9 support
requires-python = ">=3.10"

# Phase 2: Consider targeting Python 3.11+ for performance
requires-python = ">=3.11"  # 10-60% performance improvements
```

**Benefits of Upgrading**:
- **Security**: Access to latest acme/certbot versions with security fixes
- **Performance**: Python 3.11+ offers 10-60% speed improvements
- **Dependencies**: Unlock modern versions of cryptography, cloud SDKs, dev tools
- **Type System**: Enhanced type hints and better IDE support
- **Maintenance**: Reduce complexity of multi-version compatibility testing

**Migration Impact**:
- **Low Risk**: Python 3.9 approaching end-of-life, most users likely on 3.10+
- **Docker**: Already using Python 3.11.12 in Dockerfile
- **CI/CD**: Update test matrix to remove 3.9, add 3.12/3.13 focus
- **Dependencies**: Immediate access to latest security updates

**Completed Implementation**:
1. ✅ **Updated pyproject.toml**: Changed `requires-python = ">=3.11"`
2. ✅ **Updated CI/CD workflows**: Modified GitHub Actions to test with Python 3.11 and 3.13
3. ✅ **Upgraded dependencies**: Updated to acme/certbot v5.0+, sphinx v8.0+
4. ✅ **Regenerated lock file**: All dependencies updated to latest compatible versions
5. ✅ **Verified compatibility**: Project imports and runs successfully

**Results Achieved**:
- **Security**: Now using latest acme v5.0.0 and certbot v5.0.0 with security fixes
- **Performance**: Python 3.11+ performance improvements now available
- **Dependencies**: Access to modern versions (sphinx 8.2.3, cryptography 46.0.1, etc.)
- **Maintenance**: Simplified compatibility testing, removed Python 3.9 constraints

## 🟡 High Priority (Next Focus)

### 2. Docker Security Enhancements
**Location**: `Dockerfile`
**Current State**: Container runs as root user
**Recommendations**:
- Add non-root user for container execution
- Add health check for container monitoring
- Implement security best practices

**Implementation**:
```dockerfile
# Add specific user for security
RUN addgroup -g 1001 -S dnsrobocert && \
    adduser -u 1001 -S dnsrobocert -G dnsrobocert

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD python -c "import dnsrobocert; print('healthy')" || exit 1

USER dnsrobocert
```

### 3. Constants Extraction
**Location**: `src/dnsrobocert/core/background.py`, `src/dnsrobocert/core/hooks.py`
**Current State**: Minimal magic numbers present
**Identified Constants**:
- Schedule times: `"12:00"`, `"00:00"` 
- Random delay: `21600` seconds (12 hours)
- Default sleep time: `30` seconds

**Recommendation**: Create `constants.py`:
```python
# constants.py
DEFAULT_SLEEP_TIME = 30
RENEWAL_SCHEDULE_NOON = "12:00"
RENEWAL_SCHEDULE_MIDNIGHT = "00:00" 
RANDOM_DELAY_MAX_SECONDS = 21600  # 12 hours
```

### 4. Test Coverage Enhancement
**Location**: `test/` directory
**Current State**: Basic unit tests present
**Recommendations**:
- Add integration tests for DNS providers
- Security-focused tests (input validation, injection attacks)
- Error scenario testing
- Add pytest fixtures for common test data
- Improve test coverage for edge cases

## Implementation Priority

### **High Priority** (Next Focus):
1. Docker security enhancements (#2)

### **Medium Priority** (Future Development):
2. Constants extraction (#3)
3. Test coverage enhancement (#4)

## Notes

- All changes should maintain backward compatibility where possible
- Security improvements should be thoroughly tested before deployment
- Consider implementing changes incrementally to minimize disruption
- Update documentation as improvements are implemented

## Recent Updates

- **✅ Python Version Upgrade Completed**: Successfully upgraded to Python 3.11+ minimum requirement
- **✅ Dependencies Updated**: All packages upgraded to latest compatible versions (acme v5.0.0, certbot v5.0.0, sphinx v8.2.3)
- **✅ CI/CD Updated**: GitHub Actions workflows updated for Python 3.11+ testing
- **Codebase Review**: Confirmed that type hints, structured logging, and dependency pinning are well-implemented