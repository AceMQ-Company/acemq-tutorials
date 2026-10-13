# How this is built

The design of this repository, written before it was built and kept up to date
since. The short version: **this repository owns the order, not the content.**
It decides which seven things a newcomer learns and in what order; the examples
repositories own the code, the library sites own the prose, and both are linked
at the exact version an image was built from.

## What a newcomer gets

- A path of seven steps, each in all five languages: Java, Python, Ruby, .NET
  and Go.
- For every language, an image that runs any step with one command and nothing
  installed but Docker — toolchain, library, tutorial code and a broker inside.
- A site listing the path, each step showing the five languages side by side
  and linking to the example at its pinned commit and to the library's own
  tutorial and guide pages.

## The path

| Step | Subject | Why here |
|---|---|---|
| 1 | Your first message | connect, declare, publish **with a confirm**, consume |
| 2 | Never processing twice | redelivery happens from step 1 on; idempotency is what makes it safe |
| 3 | Surviving failure | the retry ladder, dead letters, and replaying them |
| 4 | Request and reply | the first pattern that is not fire-and-forget |
| 5 | Streams | a log rather than a queue |
| 6 | Outbox, saga and scheduler | the patterns built from everything above |
| 7 | Seeing what happens | metrics, health and traces over all of it |

The brief suggested "reliable publish / confirms" as step 2. It is folded into
step 1 instead: every AceMQ library confirms by default, so the first message
*is* a confirmed publish, and four of the five examples repositories have no
example that is about confirms alone — only Java's `basic/01` is named for them.
A step whose only content is "the thing you just did was already confirmed"
would be a step with nothing to run. Step 2 is idempotency, which is the other
half of the same delivery guarantee: at least once, from the publisher's side
and from the consumer's.

`path/steps.tsv` holds the steps and `path/examples.tsv` maps each step and
language to directories in the examples repository. A step runs one or more
examples in order; every one exits non-zero when what it demonstrates did not
happen, so a step that passes is a step that taught what it says.

.NET runs the C# example of each pair. The Visual Basic twin is the same
program, and is linked from the examples repository's README.

## Aggregation: pinned commits, fetched at build time

Three options were weighed.

| | Submodules | A sync script copying files in | **Fetch at build time** |
|---|---|---|---|
| a second copy of the code in this repository | no, but a pointer per repo and a `--recursive` every reader forgets | **yes** — exactly what the brief rules out | no |
| the pin is reviewable in one place | five gitlinks, invisible in a diff | yes | **yes — `pins.env`** |
| a newcomer browsing on GitHub sees the code | a link to another repository | yes | a link to another repository |
| CI and the site can read the pin without git | no | yes | **yes** |

**Fetch at build time** won. `pins.env` names, per language, the library
release and the commit of the examples repository that tracks it. The
Dockerfile `ADD`s that repository at that commit, BuildKit's git source, so the
image holds exactly what that repository's CI ran. The site builder reads the
same commit from `raw.githubusercontent.com` for each example's one-paragraph
description, and links to the tree at that commit.

Commits rather than tags because the examples repositories are not tagged:
each one moves its library pin in a commit and nothing more. A commit is as
immutable as a tag and needs no release process in five other repositories.

## The images

`ghcr.io/acemq-company/acemq-tutorials-<lang>`, built from one Dockerfile with
a target per language (`images/Dockerfile`). Each is:

1. **`rabbitmq:<version>-management` as the base.** The broker is the hard part
   to install well — Erlang, OpenSSL and the server are built together upstream
   — and the toolchains are not: Python, Ruby and their build tools are Ubuntu
   packages, and the JDK, Maven, the .NET SDK and Go are self-contained
   directories copied out of their own official images.
2. **The examples at the pinned commit**, built once at image build time —
   Maven compiles and copies each module's runtime classpath, the .NET projects
   are built in Release, Go builds a binary per example, Python gets a venv,
   Ruby gets its bundle. A step then starts a process rather than a build.
3. **A check that the library resolved is the pinned release**, in every
   language. The build fails otherwise. This matters most for Ruby, whose
   examples repository deliberately commits no lock and asks for `~> 0.7`.
4. **One entrypoint, `tutorial`**, shared by all five: `list`, `step <n>
   [--keep]`, `all`, `shell`, `broker`, `version`.

### The broker inside the image

The T59 note says images must ship a broker, and they do: `docker run … step 3`
needs nothing else running. The entrypoint starts RabbitMQ in the background as
the `rabbitmq` user, waits for the AMQP port to accept a connection — the
listener is the last thing a node opens — and runs the step. Its log goes to a
file, not the terminal, so the output is the example's.

The Erlang cookie is passed on the command line (`-setcookie`, through
`RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS` and `RABBITMQ_CTL_ERL_ARGS`) rather than
read from a file. A cookie file depends on the broker's `HOME` being writable
and owned just so, and when it is not the node dies with an `eacces` that does
not say why. On the command line there is nothing to get wrong.

The base image already lets `guest` log in from outside the container, so the
management UI on `-p 15672:15672` works from the host's browser.

### Compose, as well

`compose.yaml` runs one broker and points any of the five images at it with
`TUTORIAL_BROKER=external`, which keeps the image's own broker off. It is the
better shape for running several languages against one broker, or for watching
one broker's UI while stepping through languages. It is extra; the broker in the
image is the default.

### Versioning

| Tag | Moves? | Example |
|---|---|---|
| `<library version>` | when this repository releases again for the same library version | `0.7.12` |
| `<library version>-t<tutorials version>` | never | `0.7.12-t0.1.0` |
| `latest` | every release | |

Images are tagged with the **library** version because that is the number a
reader has in their head and in their build file. The tutorials repository has
its own semver (`v0.1.0`, …), which is what a release of this repository is
cut from; the immutable tag joins the two.

Releases are cut by tagging this repository. They publish images only — nothing
goes to any library feed.

## Keeping it honest

- **`etc/check-pins.sh` — the pins are the newest releases.** For each
  language: the pinned version is the newest `vX.Y.Z` tag of the library; the
  pinned examples commit's own manifest names that version; and every image tag
  written into the README, the docs or `compose.yaml` is the pinned one. It runs
  on every push and on a weekly schedule, because a library release moves
  underneath this repository without a commit landing here.
- **Every step runs in CI.** Each image is built and `tutorial all` runs every
  step against its bundled broker. A release builds both architectures on
  native runners and runs the same smoke test on each before anything is pushed.
- **The site's links are checked**: every internal link must resolve, and the
  build fails if an example has neither a README nor a row in its repository's
  table of examples to describe it.

## Layout

```
pins.env               every version: library releases, examples commits, broker
path/steps.tsv         the steps
path/examples.tsv      step × language → example directories
images/Dockerfile      one target per language
images/tutorial        the entrypoint
compose.yaml           one broker, five images pointed at it
docs/                  the site's hand-written pages
etc/build-image.sh     build one image from pins.env
etc/build-site.sh      render the site into site/
etc/check-pins.sh      the pins are the newest releases
```

## Updating for a library release

1. The library releases; its examples repository moves its pin in a commit.
2. `./etc/check-pins.sh` goes red and says what to set.
3. Set `<LANG>_VERSION` and `<LANG>_EXAMPLES` in `pins.env`, and the image tags
   it names.
4. CI builds and runs the image. Tag a release to publish it.
