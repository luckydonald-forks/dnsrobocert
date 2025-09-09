FROM docker.io/python:3.11.12-alpine AS constraints

# Install build dependencies
RUN apk add --no-cache build-base libffi-dev libxml2-dev libxslt-dev

COPY src uv.lock pyproject.toml README.rst /tmp/dnsrobocert/

RUN pip install uv \
 && cd /tmp/dnsrobocert \
 && uv export --no-emit-project --no-hashes > /tmp/dnsrobocert/constraints.txt \
 # Remove dns-lexicon constraint since we're using git dependency
 && sed -i '/^dns-lexicon @ git+/d' /tmp/dnsrobocert/constraints.txt \
 # Pin some packages on armv7l arch to latest available and compatible versions from pipwheels.
 && [ "$(uname -m)" != "armv7l" ] || sed -i 's/cryptography==.*/cryptography==44.0.2/' /tmp/dnsrobocert/constraints.txt \
 && [ "$(uname -m)" != "armv7l" ] || sed -i 's/lxml==.*/lxml==5.3.1/' /tmp/dnsrobocert/constraints.txt \
 && uv build

# Alpine-based final stage for minimal size
FROM docker.io/python:3.11.12-alpine

COPY --from=constraints /tmp/dnsrobocert/constraints.txt /tmp/dnsrobocert/dist/*.whl /tmp/dnsrobocert/

ENV CONFIG_PATH=/etc/dnsrobocert/config.yml
ENV CERTS_PATH=/etc/letsencrypt

# Install only runtime dependencies
RUN apk add --no-cache \
       curl \
       git \
       libxslt \
       bash \
       docker-cli \
 # Install Python packages
 && PIP_EXTRA_INDEX_URL=https://www.piwheels.org/simple python3 -m pip install --no-cache-dir -c /tmp/dnsrobocert/constraints.txt /tmp/dnsrobocert/*.whl \
 # Create necessary directories
 && mkdir -p /etc/dnsrobocert /etc/letsencrypt \
 # Cleanup
 && rm -rf /tmp/dnsrobocert /root/.cache /tmp/* /var/tmp/* \
 && find /usr/local -depth \( -type d -a -name test -o -name tests -o -name __pycache__ \) -exec rm -rf '{}' + \
 && find /usr/local -name '*.pyc' -delete

# For retro-compatibility purpose
RUN mkdir -p /opt/dnsrobocert/bin \
 && ln -s /usr/local/bin/python /opt/dnsrobocert/bin/python

COPY docker/run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]