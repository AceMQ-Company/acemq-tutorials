#!/usr/bin/env bash
# The pins are the newest releases.
#
#   ./etc/check-pins.sh
#
# Two questions per language, both answered from GitHub and nothing local:
#
#   1. Is <LANG>_VERSION the newest vX.Y.Z tag of acemq-<lang>-amqp? A tutorial
#      image for a release nobody installs any more teaches the wrong thing in a
#      green build, which is worse than a red one.
#   2. Does the examples commit <LANG>_EXAMPLES pin that same release in its own
#      manifest? The image builds would also notice, but an hour later and once
#      per architecture; this notices in a second.
#
# It also says, without failing, when the examples repository's main has moved
# past the pinned commit -- often a README fix, which is worth picking up but is
# not wrong to be without.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
. ./pins.env

fail=0
for lang in java python ruby dotnet go; do
  upper="$(echo "$lang" | tr '[:lower:]' '[:upper:]')"
  version_var="${upper}_VERSION"; commit_var="${upper}_EXAMPLES"
  version="${!version_var}"; commit="${!commit_var}"

  newest="$(git ls-remote --tags "https://github.com/AceMQ-Company/acemq-$lang-amqp" \
    | sed 's#.*refs/tags/##' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^v//' | sort -V | tail -1)"
  if [ -z "$newest" ]; then
    echo "::error::$lang: no release tags found on acemq-$lang-amqp"; fail=1; continue
  fi
  if [ "$version" != "$newest" ]; then
    echo "::error::$lang: pins.env has $version_var=$version but the newest release is $newest. Set it to $newest, and $commit_var to the examples commit that tracks it."
    fail=1
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
    echo "::error::$lang: could not read $file at examples commit $commit -- is it pushed?"; fail=1; continue; }
  if grep -qF -- "$want" <<<"$body"; then
    [ "$version" = "$newest" ] && echo "$lang $version: newest release, examples@${commit:0:12} pins it"
  else
    echo "::error::$lang: acemq-$lang-amqp-examples@${commit:0:12} does not pin $version in $file (looked for '$want')."
    fail=1
  fi

  # Image tags written into prose and the compose file name the pinned version.
  while IFS= read -r hit; do
    echo "::error::$hit names an acemq-tutorials-$lang tag other than $version"; fail=1
  done < <(grep -rnoE "acemq-tutorials-$lang:[0-9]+\.[0-9]+\.[0-9]+" README.md compose.yaml docs \
             | grep -v ":$version\$" || true)

  head="$(git ls-remote "https://github.com/AceMQ-Company/acemq-$lang-amqp-examples" refs/heads/main | cut -f1)"
  if [ "$head" != "$commit" ]; then
    echo "::notice::$lang: acemq-$lang-amqp-examples main is at ${head:0:12}, pins.env has ${commit:0:12}."
  fi
done
exit "$fail"
