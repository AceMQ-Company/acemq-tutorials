#!/usr/bin/env bash
# The pins are the newest releases.
#
#   ./etc/check-pins.sh
#
# Three questions per language, all answered from GitHub and nothing local:
#
#   1. Is <LANG>_VERSION the newest vX.Y.Z tag of acemq-<lang>-amqp? A tutorial
#      image for a release nobody installs any more teaches the wrong thing in a
#      green build, which is worse than a red one.
#   2. Is <LANG>_EXAMPLES an examples tag for that same release
#      (examples-v<version>, or examples-v<version>-r<n>), does it exist, and
#      does the commit it names pin that release in its own manifest? The image
#      builds would also notice, but an hour later and once per architecture;
#      this notices in a second.
#   3. Does every image tag written into the README, the docs and compose.yaml
#      name the pinned version?
#
# It also says, without failing, when the examples repository's main has moved
# past the tagged commit -- often a README fix, which reaches the tutorials once
# that repository tags it as the next revision.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
. ./pins.env

fail=0
for lang in java python ruby dotnet go; do
  upper="$(echo "$lang" | tr '[:lower:]' '[:upper:]')"
  version_var="${upper}_VERSION"; tag_var="${upper}_EXAMPLES"
  version="${!version_var}"; tag="${!tag_var}"
  examples="https://github.com/AceMQ-Company/acemq-$lang-amqp-examples"

  newest="$(git ls-remote --tags "https://github.com/AceMQ-Company/acemq-$lang-amqp" \
    | sed 's#.*refs/tags/##' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^v//' | sort -V | tail -1)"
  if [ -z "$newest" ]; then
    echo "::error::$lang: no release tags found on acemq-$lang-amqp"; fail=1; continue
  fi
  if [ "$version" != "$newest" ]; then
    if git ls-remote --exit-code --tags "$examples" "refs/tags/examples-v$newest" >/dev/null; then
      echo "::error::$lang: pins.env has $version_var=$version but the newest release is $newest, and acemq-$lang-amqp-examples is tagged for it. The bump-pins workflow moves this; run it, or set both pins by hand."
    else
      echo "::error::$lang: pins.env has $version_var=$version but the newest release is $newest, which acemq-$lang-amqp-examples has not tagged yet. Tag it there (examples-v$newest) once its CI is green on the pin; the bump-pins workflow follows."
    fi
    fail=1
  fi

  # The tag names the pinned release, so the pin cannot say one version and
  # build from the examples of another.
  if ! [[ "$tag" =~ ^examples-v${version//./\\.}(-r[0-9]+)?$ ]]; then
    echo "::error::$lang: $tag_var=$tag is not an examples tag for $version (examples-v$version or examples-v$version-r<n>)."
    fail=1; continue
  fi
  # ^{} is the commit an annotated tag points at; a lightweight tag has only the
  # plain line, which is already the commit.
  commit="$(git ls-remote --tags "$examples" "refs/tags/$tag" "refs/tags/$tag^{}" | sort -k2 | tail -1 | cut -f1)"
  if [ -z "$commit" ]; then
    echo "::error::$lang: acemq-$lang-amqp-examples has no tag $tag."; fail=1; continue
  fi

  # The file in the examples repository that names the release, and how.
  case "$lang" in
    java)   file=pom.xml;              want="<acemq.version>$version</acemq.version>" ;;
    python) file=requirements.txt;     want="]==$version" ;;
    ruby)   file=Gemfile;              want="\">= $version\"" ;;
    dotnet) file=Directory.Build.props; want="<AceMqVersion>$version</AceMqVersion>" ;;
    go)     file=go.mod;               want="acemq-go-amqp v$version" ;;
  esac
  body="$(curl -fsSL "https://raw.githubusercontent.com/AceMQ-Company/acemq-$lang-amqp-examples/$commit/$file")" || {
    echo "::error::$lang: could not read $file at $tag (${commit:0:12})."; fail=1; continue; }
  if grep -qF -- "$want" <<<"$body"; then
    [ "$version" = "$newest" ] && echo "$lang $version: newest release, examples $tag (${commit:0:12}) pins it"
  else
    echo "::error::$lang: acemq-$lang-amqp-examples $tag (${commit:0:12}) does not pin $version in $file (looked for '$want')."
    fail=1
  fi

  # Image tags written into prose and the compose file name the pinned version.
  while IFS= read -r hit; do
    echo "::error::$hit names an acemq-tutorials-$lang tag other than $version"; fail=1
  done < <(grep -rnoE "acemq-tutorials-$lang:[0-9]+\.[0-9]+\.[0-9]+" README.md compose.yaml docs \
             | grep -v ":$version\$" || true)

  head="$(git ls-remote "$examples" refs/heads/main | cut -f1)"
  if [ "$head" != "$commit" ]; then
    echo "::notice::$lang: acemq-$lang-amqp-examples main is at ${head:0:12}, past $tag (${commit:0:12})."
  fi
done
exit "$fail"
