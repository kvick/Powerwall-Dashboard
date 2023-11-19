#!/bin/bash
#
# Convenience script for docker-compose
# Enables
#   - docker-compose and docker compose (v1, v2)
#   - moves multiple versions of unwieldy compose invocation to one place
#   - very convenient for starting and stopping containers when developing.
# Takes up to two arguments, typically "up -d", "start", and "stop"
# Always verifies docker and docker-compose, as it is run infrequently.
# by BuongiornoTexas 16 Oct 2022

# Stop on Errors
set -e

# Check for Arguments
if [ -z "$1" ]
  then
    echo "Powerwall-Dashboard helper script for docker-compose"
    echo ""
    echo "Usage:"
    echo "  ${0} [COMMAND] [ARG]"
    echo ""
    echo "Commands (see docker-compose for full list):"
    echo "  up -d              Create and start containers"
    echo "  start              Start services"
    echo "  stop               Stop services"
    exit 1
fi

# Docker Dependency Check
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: docker is not available or not running."
    echo "This script requires docker, please install and try again."
    exit 1
fi

# Load environment variables for compose
if [ ! -f "compose.env" ]; then
    echo "ERROR: Missing compose.env file."
    echo "Please run setup.sh or copy compose.env.sample to compose.env."
    exit 1
fi
set -a
. compose.env
set +a

# Docker Compose Extension Check
if [ -f "powerwall.extend.yml" ]; then
    echo "Including powerwall.extend.yml"
    pwextend="-f powerwall.extend.yml"
else
    pwextend=""
fi
# Compose Profiles Helper Functions
get_profile() {
    if [ ! -f ${COMPOSE_ENV_FILE} ]; then
        return 1
    else
        unset COMPOSE_PROFILES
        . "${COMPOSE_ENV_FILE}"
    fi
    # Check COMPOSE_PROFILES for profile
    IFS=',' read -a PROFILES <<< ${COMPOSE_PROFILES}
    for p in "${PROFILES[@]}"; do
        if [ "${p}" == "${1}" ]; then
            return 0
        fi
    done
    return 1
}

echo "Running Docker Compose..."
if docker-compose version > /dev/null 2>&1; then
    # Build Docker (v1)
    pwconfig="powerwall-v1.yml"
    if get_profile "solar-only"; then
        pwconfig="powerwall-v1-solar.yml"
    fi
    docker-compose -f $pwconfig $pwextend $@
else
    if docker compose version > /dev/null 2>&1; then
        # Build Docker (v2)
        docker compose -f powerwall.yml $pwextend $@
    else
        echo "ERROR: docker-compose/docker compose is not available or not running."
        echo "This script requires docker-compose or docker compose."
        echo "Please install and try again."
        exit 1
    fi
fi
