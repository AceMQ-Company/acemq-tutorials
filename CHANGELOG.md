# Changelog

All notable changes to this project are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

A release of this repository publishes the five tutorial images and nothing
else. Images are tagged with the library version they carry.

## [Unreleased]

### Changed

- Track Java 0.7.17, examples `examples-v0.7.17` (was 0.7.15, `examples-v0.7.15`).
- Track Python 0.7.14, examples `examples-v0.7.14` (was 0.7.12, `examples-v0.7.12`).
- Track Ruby 0.7.16, examples `examples-v0.7.16` (was 0.7.14, `examples-v0.7.14`).
- Track .NET 0.7.15, examples `examples-v0.7.15` (was 0.7.13, `examples-v0.7.13`).
- Track Go 0.9.11, examples `examples-v0.9.11` (was 0.9.9, `examples-v0.9.9`).
- Track Java 0.7.18, examples `examples-v0.7.18` (was 0.7.17, `examples-v0.7.17`).
- Track Python 0.7.15, examples `examples-v0.7.15` (was 0.7.14, `examples-v0.7.14`).
- Track Ruby 0.7.17, examples `examples-v0.7.17` (was 0.7.16, `examples-v0.7.16`).
- Track .NET 0.7.16, examples `examples-v0.7.16` (was 0.7.15, `examples-v0.7.15`).
- Track Go 0.9.12, examples `examples-v0.9.12` (was 0.9.11, `examples-v0.9.11`).
- Track Java 0.7.19, examples `examples-v0.7.19` (was 0.7.18, `examples-v0.7.18`).
- Track Python 0.7.16, examples `examples-v0.7.16` (was 0.7.15, `examples-v0.7.15`).
- Track Ruby 0.7.18, examples `examples-v0.7.18` (was 0.7.17, `examples-v0.7.17`).
- Track .NET 0.7.17, examples `examples-v0.7.17` (was 0.7.16, `examples-v0.7.16`).
- Track Go 0.9.13, examples `examples-v0.9.13` (was 0.9.12, `examples-v0.9.12`).
- Track Java 0.7.20, examples `examples-v0.7.20` (was 0.7.19, `examples-v0.7.19`).
- Track Python 0.7.17, examples `examples-v0.7.17` (was 0.7.16, `examples-v0.7.16`).
- Track Ruby 0.7.19, examples `examples-v0.7.19` (was 0.7.18, `examples-v0.7.18`).
- Track .NET 0.7.18, examples `examples-v0.7.18` (was 0.7.17, `examples-v0.7.17`).
- Track Go 0.9.14, examples `examples-v0.9.14` (was 0.9.13, `examples-v0.9.13`).

## [0.1.1] - 2026-10-13

### Changed

- Rebuilt on the same library versions — Java `0.7.15`, Python `0.7.12`, Ruby
  `0.7.14`, .NET `0.7.13`, Go `0.9.9` — from the examples tags below.
- The examples are pinned by tag, not by commit: `examples-v<library version>`
  in each examples repository, which names the release it was verified on and
  is never moved. `etc/check-pins.sh` checks that the tag is for the pinned
  release, exists and pins it; the build resolves it to its commit and records
  that in the image.
- The .NET and Go images carry the examples' newer READMEs, so the twelve
  examples on the path that had none are described on the step pages in their
  own README's words; every image carries its examples repository's *Versions*
  section saying how it is tagged.

### Added

- `bump-pins`, daily: moves the pins to the newest library releases whose
  examples are tagged, runs check-pins and every step of the moved languages,
  and lands the change on main. A release without an examples tag is reported
  and left alone.
- `RELEASING.md`.

## [0.1.0] - 2026-10-13

### Added

- The learning path: seven steps — your first message, never processing twice,
  surviving failure, request and reply, streams, outbox/saga/scheduler, and
  seeing what happens — each mapped to examples in all five examples
  repositories.
- `ghcr.io/acemq-company/acemq-tutorials-{java,python,ruby,dotnet,go}`, for
  `linux/amd64` and `linux/arm64`: the toolchain, the library, the examples at
  a pinned commit and a RabbitMQ 4.3.6 broker in one image, with a `tutorial`
  entrypoint (`list`, `step <n> [--keep]`, `all`, `shell`, `broker`,
  `version`). Tagged `<library version>`, `<library version>-t0.1.0` and
  `latest`:
  - Java `0.7.15`, Python `0.7.12`, Ruby `0.7.14`, .NET `0.7.13`, Go `0.9.9`.
- `compose.yaml`: one broker, and any of the images pointed at it.
- The site, at <https://acemq.org/acemq-tutorials/>: the path, one page per
  step with the five languages side by side, and the design.
- CI: every step of every image against its bundled broker; the pins are the
  newest releases; the site builds and its links resolve.
