#!/usr/bin/env bash
# Build one language's image from the versions in pins.env.
#
#   ./etc/build-image.sh python                    # tags acemq-tutorials-python:<version>
#   ./etc/build-image.sh python --push -t extra    # any further docker build arguments
#
# Prints nothing of its own beyond docker's output; the image is tagged
# ghcr.io/acemq-company/acemq-tutorials-<lang>:<library version>.
set -euo pipefail
cd "$(dirname "$0")/.."

lang="${1:?usage: build-image.sh <java|python|ruby|dotnet|go> [docker build args...]}"
shift
# shellcheck disable=SC1091
. ./pins.env
upper="$(echo "$lang" | tr '[:lower:]' '[:upper:]')"
version_var="${upper}_VERSION"; commit_var="${upper}_EXAMPLES"
version="${!version_var:?no $version_var in pins.env}"
commit="${!commit_var:?no $commit_var in pins.env}"

# TAG= (empty) builds without a tag, for a push by digest.
tag="${TAG-ghcr.io/acemq-company/acemq-tutorials-$lang:$version}"
exec docker buildx build -f images/Dockerfile --target "$lang" \
  --build-arg RABBITMQ_IMAGE="$RABBITMQ_IMAGE" \
  --build-arg ACEMQ_VERSION="$version" \
  --build-arg EXAMPLES_COMMIT="$commit" \
  ${tag:+-t "$tag"} \
  "$@" .
