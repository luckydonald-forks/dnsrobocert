#!/bin/sh
# docker-entrypoint.sh
set -x;

TEMPLATE_FILE=/config.template.yml
CONFIG_FILE=/etc/dnsrobocert/config.yml

# Replace any environment variable references in config.template.yml.
# (Assumes the image has the full GNU tool set.)
echo "Starting, replacing variables in the config template."
echo ""
echo "Variables to replace:"
env
echo ""
echo "Template to replace in:"
cat ${TEMPLATE_FILE}
echo
echo "Result:"
envsubst <"${TEMPLATE_FILE}" >"${CONFIG_FILE}"
cat ${CONFIG_FILE}
echo
echo "Diff:"
diff ${TEMPLATE_FILE} ${CONFIG_FILE}


# Run the standard container command.
echo "Launching [/run.sh]..."
echo "Note: Ignoring parameters [$@], if any."
exec /run.sh
