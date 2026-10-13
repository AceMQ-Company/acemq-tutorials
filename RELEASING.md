# Releasing

A release of this repository publishes the five images and nothing else. It is
cut by hand, by pushing a `vX.Y.Z` tag; `release.yml` does the rest.

## When

Whenever the images should change: a pin moved (the bump-pins workflow lands
those on main by itself), the path or the entrypoint changed, or the broker
did. A pin bump alone is a **patch** release.

Until it is cut, the README and the site name an image tag for the new library
version that is not published yet. Cut it the same day the bump lands.

## How

1. Main is green: `gh run list -R AceMQ-Company/acemq-tutorials -b main`.
2. In `CHANGELOG.md`, turn `## [Unreleased]` into `## [X.Y.Z] - <date>` and
   open a new empty `## [Unreleased]` above it. The bump-pins workflow has
   already written its "Track …" lines there.
3. `./etc/release-preflight.sh X.Y.Z` says *Clear to tag*.
4. Commit, push, then:

   ```bash
   git tag -a vX.Y.Z -m "acemq-tutorials X.Y.Z"
   git push origin vX.Y.Z
   ```

A tag is never moved or reused. A bad release is followed by the next patch.

## Why a bump does not release itself

It could: the bump workflow has already run every step, and `release.yml`
runs them again on both architectures before pushing anything. It does not
because a release moves `latest` and the `<library version>` tags that readers
pull, and here a version is tagged only when somebody decides to — the same
rule as for the libraries. A tag pushed with the workflow's own token would
also start no workflow, so it would need dispatching by hand anyway.
