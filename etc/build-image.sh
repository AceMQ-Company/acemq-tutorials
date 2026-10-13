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
version_var="${upper}_VERSION"; tag_var="${upper}_EXAMPLES"
version="${!version_var:?no $version_var in pins.env}"
tag="${!tag_var:?no $tag_var in pins.env}"

# The pin is a tag; the build is given the commit it names, so the image records
# exactly what it was built from (tutorial version prints it) and BuildKit
# fetches by object rather than by name. ^{} is an annotated tag's commit.
commit="$(git ls-remote --tags "https://github.com/AceMQ-Company/acemq-$lang-amqp-examples" \
  "refs/tags/$tag" "refs/tags/$tag^{}" | sort -k2 | tail -1 | cut -f1)"
[ -n "$commit" ] || { echo "acemq-$lang-amqp-examples has no tag $tag" >&2; exit 1; }
echo "$lang: examples $tag is $commit" >&2

# TAG= (empty) builds without a tag, for a push by digest.
tag="${TAG-ghcr.io/acemq-company/acemq-tutorials-$lang:$version}"
exec docker buildx build -f images/Dockerfile --target "$lang" \
  --build-arg RABBITMQ_IMAGE="$RABBITMQ_IMAGE" \
  --build-arg ACEMQ_VERSION="$version" \
  --build-arg EXAMPLES_COMMIT="$commit" \
  ${tag:+-t "$tag"} \
  "$@" .
