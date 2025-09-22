# Planned Improvements for DNSroboCert

This document outlines optimization opportunities and best practice improvements identified during the project review.

## 🔴 High Priority (Security & Stability)

### 1. Git Dependency Security Risk ✅ COMPLETED
**Location**: `pyproject.toml:39`
**Issue**: Dependency on git repository main branch is unstable
**Status**: ✅ Implemented - Pinned to specific commit hash bc109536ac26c541de7f98318f49a8660d014431
**Implementation**: `dns-lexicon[full] @ git+https://github.com/jonmeacham/dns-lexicon.git@bc109536ac26c541de7f98318f49a8660d014431`

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

### 3. Docker Build Process Optimization
**Location**: `Dockerfile`, build context
**Issue**: Build time and image size can be significantly optimized
**Current Metrics**:
- Image Size: 395MB
- Build Time: ~1m 38s
- Python packages: 317.4MB (80% of image)

**Recommendations (in priority order)**:

#### 3a. Add .dockerignore File (High Impact, Low Effort)
**Expected Impact**: 20-30% build time reduction
```dockerignore
.git
.github
docs/
test/
*.md
.pytest_cache
__pycache__
*.pyc
.mypy_cache
.coverage
junit/
```

#### 3b. Optimize Layer Caching (High Impact, Medium Effort)
**Expected Impact**: Better incremental builds, 15-20% build time reduction
```dockerfile
# Copy dependency files first (changes less frequently)
COPY uv.lock pyproject.toml README.rst /tmp/dnsrobocert/
RUN uv export --no-emit-project --no-hashes > constraints.txt

# Copy source code last (changes most frequently)
COPY src/ /tmp/dnsrobocert/src/
```

#### 3c. Remove Unnecessary Runtime Dependencies (Medium Impact, Low Effort)
**Expected Impact**: 10-20MB image size reduction
- Review necessity of `git`, `docker-cli`, `curl` in runtime image
- Keep only dependencies required for actual certificate operations

#### 3d. Enhanced Python Cleanup (Medium Impact, Low Effort)
**Expected Impact**: Additional 10-15MB reduction
```dockerfile
RUN find /usr/local -name "*.pyo" -delete \
 && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + \
 && find /usr/local -name "*.dist-info/WHEEL" -delete \
 && find /usr/local -name "*.dist-info/METADATA" -delete
```

#### 3e. Build Cache Optimization (Medium Impact, Medium Effort)
**Expected Impact**: Faster incremental builds
```dockerfile
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -c constraints.txt *.whl
```

**Expected Results After Implementation**:
- Image Size: 395MB → 320-350MB (12-19% reduction)
- Build Time: 1m 38s → 1m 0s-1m 10s (25-40% reduction)
- Better cache utilization for incremental builds

**Note**: While DNS provider dependencies (tencentcloud: 113MB, botocore: 111MB, oci: 19MB) consume ~62% of image size, these are retained to preserve the core value proposition of supporting all DNS providers through configuration alone. Alternative approaches like modular images would compromise this key feature.

### 4. Background Worker Optimization ✅ COMPLETED
**Location**: `src/dnsrobocert/core/background.py:48-57`
**Issue**: Inefficient shutdown using `time.sleep()`
**Status**: ✅ Implemented - Replaced time.sleep() with Event.wait() for immediate shutdown response
**Implementation**:
```python
def _launch_background_jobs(stop_thread: threading.Event, interval: int = 1) -> None:
    class ScheduleThread(threading.Thread):
        @classmethod
        def run(cls) -> None:
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

### 5. YAML Loading Security ✅ COMPLETED
**Location**: `src/dnsrobocert/core/config.py:31,41`
**Issue**: Direct use of `yaml.load()` with SafeLoader
**Status**: ✅ Implemented - Replaced yaml.load() with yaml.safe_load() for better code clarity
**Implementation**:
```python
# Before: yaml.load(raw_config, Loader=yaml.SafeLoader)
# After: yaml.safe_load(raw_config)
config = yaml.safe_load(raw_config)
schema = yaml.safe_load(file_h.read())
```

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

1. **Immediate**: Address High Priority security issues (~~#1 ✅~~, ~~#2 ✅~~)
2. **Next Sprint**: Implement Medium Priority improvements:
   - **High Impact, Low Effort**: Docker build optimizations (#3a: .dockerignore)
   - **Completed**: Background worker optimization (~~#4 ✅~~), Hash upgrade (~~#5 ✅~~), YAML security (~~#6 ✅~~)
   - **Remaining**: Docker layer caching (#3b), dependency version pinning (#7)
3. **Following Sprint**: Medium Impact Docker optimizations (#3c-3e)
4. **Ongoing**: Gradually implement Low Priority enhancements (#8-11)

## Notes

- All changes should maintain backward compatibility where possible
- Security improvements should be thoroughly tested before deployment
- Consider implementing changes incrementally to minimize disruption
- Update documentation as improvements are implemented
