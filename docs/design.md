# How this is built

The design of this repository, written before it was built and kept up to date
since. The short version: **this repository owns the order, not the content.**
It decides which eight things a newcomer learns and in what order; the examples
repositories own the code, the library sites own the prose, and both are linked
at the exact version an image was built from.

## What a newcomer gets

- A path of eight steps, each in all five languages: Java, Python, Ruby, .NET
  and Go (step 8, the framework integrations, has nothing to run in Go, which
  has no integration).
- For every language, an image that runs any step with one command and nothing
  installed but Docker — library, tutorial code built, a runtime and a broker inside.
- A site listing the path, each step showing the five languages side by side
  and linking to the example at its pinned examples tag and to the library's
  own tutorial and guide pages.

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
| 8 | In your framework | the same messages through the Spring Boot starter, .NET hosting, FastAPI and Rails |

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

.NET runs the C# example of each pair by default. The .NET image also carries
the VB.NET twin of every example the path uses, built, and `TUTORIAL_VARIANT=vbnet` runs those instead —
`docker run --rm -e TUTORIAL_VARIANT=vbnet <image> step 3`. The path names the
C# directory; the twin is the `-vbnet` directory beside it, so nothing in
`path/` says anything twice.

### Step 8: the integrations

Spring Boot, the .NET Generic Host, FastAPI and Rails each have an AceMQ
integration of its own (`acemq-java-amqp-spring-boot-starter`,
`acemq-dotnet-amqp-hosting`, `acemq-python-amqp-fastapi`,
`acemq-ruby-amqp-rails`). Step 8 is the step 1 program written each framework's
way: the framework opens the connection and declares the topology, a handler
the framework resolves consumes, the application publishes, and stopping the
application drains. Each example then checks that three orders went out and
three came back, and exits non-zero otherwise, like every other step.

Those repositories have no examples repository, so step 8's examples are the
one exception to "nothing is copied": they live in
[`integrations/`](https://github.com/AceMQ-Company/acemq-tutorials/tree/main/integrations)
here and are built into the image at `/tutorials/examples/integrations/`, so
`path/examples.tsv` names them like any other directory. Each integration's
release is pinned in `pins.env` as `<LANG>_INTEGRATION_VERSION`, beside the
library release it is built with; the image build holds both to their pins
(the library by naming it beside the integration, which normally carries it
already). Go has no integration and is not given one here: its row in
`path/examples.tsv` is `-` with a note, which `tutorial step 8` prints.

## Aggregation: pinned tags, fetched at build time

Three options were weighed.

| | Submodules | A sync script copying files in | **Fetch at build time** |
|---|---|---|---|
| a second copy of the code in this repository | no, but a pointer per repo and a `--recursive` every reader forgets | **yes** — exactly what the brief rules out | no |
| the pin is reviewable in one place | five gitlinks, invisible in a diff | yes | **yes — `pins.env`** |
| a newcomer browsing on GitHub sees the code | a link to another repository | yes | a link to another repository |
| CI and the site can read the pin without git | no | yes | **yes** |

**Fetch at build time** won. `pins.env` names, per language, the library
release and the tag of the examples repository verified against it.
`etc/build-image.sh` resolves the tag to its commit and the Dockerfile `ADD`s
that repository at that commit, BuildKit's git source, so the image holds
exactly what that repository's CI ran and `tutorial version` prints the commit.
The site builder reads the same tag from `raw.githubusercontent.com` for each
example's one-paragraph description, and links to the tree at that tag.

### Examples tags

The pins started as commits, because the examples repositories had no tags.
They have one now for every library release they are verified on:
`examples-v<library version>` — `examples-v0.7.15` on acemq-java-amqp-examples
is the commit whose `pom.xml` pins 0.7.15, tagged once its CI passed there. A
later fix worth having at the same release is `examples-v0.7.15-r2`, and the
highest revision wins. Each examples repository's README says so under
*Versions*.

- **Why a tag at all:** a commit says nothing about what it was verified
  against; a tag names the release, so `check-pins.sh` can refuse a pin whose
  examples are for another version, and a script can find the right one for a
  new release without reading five repositories' history.
- **Why `examples-v` and not `v`:** a plain `v0.7.15` in an examples
  repository reads as a release of that repository, which it is not, and in
  the Go one it *is* one to Go's module proxy, which caches a version for ever.
- **Immutable:** annotated, never moved, re-pointed or deleted. A mistake is
  corrected by the next `-r<n>`. The build still records the commit the tag
  named, so even a tag moved against the rule could not change what an image
  says it was built from.

## The images

`ghcr.io/acemq-company/acemq-tutorials-<lang>`, built from one Dockerfile with
a target per language (`images/Dockerfile`). Each is:

1. **`rabbitmq:<version>-management-alpine` as the base.** The broker is the
   hard part to install well — Erlang, OpenSSL and the server are built
   together upstream — and the runtimes are not: Python and Ruby are Alpine
   packages, and the Java runtime and the .NET runtime are self-contained
   directories copied out of their official Alpine images.
2. **The examples at the commit the pinned tag names**, built once at image
   build time, in a build stage of their own — Maven compiles and copies each
   module's runtime classpath, the .NET projects are published, Go builds a
   static binary per example, Python gets a venv, Ruby gets its bundle. A step
   then starts a process rather than a build. The image gets the build's output
   and a runtime, and no toolchain: no JDK, Maven, .NET SDK, Go, compiler or
   package cache. That is what took the images from 0.55–1.4 GB to 0.36–0.53 GB
   ([the images](images.md#size) has the numbers). The cost is that `shell` can
   no longer rebuild a Java, .NET or Go example after an edit; Python and Ruby
   run from source, so editing them still works. Changing a compiled example
   means its examples repository, or building the image yourself.
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
  pinned examples tag is one for that version, exists, and names a commit whose
  own manifest pins it; and every image tag written into the README, the docs
  or `compose.yaml` is the pinned one. Each integration pin is the newest
  `vX.Y.Z` tag of its repository. It runs on every push and on a weekly
  schedule, because a library release moves underneath this repository without
  a commit landing here.
- **`bump-pins.yml` — and they are moved for you.** Daily, it finds each
  language's newest release and the examples tag for it, and where those are
  not the pins it rewrites them, runs `check-pins.sh` and every step of the
  moved languages — `steps.yml`, the job CI runs — and fast-forwards main only
  if all of that passed. A release without an examples tag is named in the run
  summary and left alone. Integration releases are moved the same way; they
  need no examples tag, because their example is here.
- **Every step runs in CI.** Each image is built and `tutorial all` runs every
  step against its bundled broker. A release builds both architectures on
  native runners and runs the same smoke test on each before anything is pushed.
- **The site's links are checked**: every internal link must resolve, and the
  build fails if an example has neither a README nor a row in its repository's
  table of examples to describe it.

## Layout

```
pins.env               every version: library and integration releases, examples tags, broker
path/steps.tsv         the steps
path/examples.tsv      step × language → example directories
integrations/          step 8's examples, one per framework integration
images/Dockerfile      one target per language
images/tutorial        the entrypoint
compose.yaml           one broker, five images pointed at it
docs/                  the site's hand-written pages
etc/build-image.sh     build one image from pins.env
etc/build-site.sh      render the site into site/
etc/check-pins.sh      the pins are the newest releases
etc/bump-pins.py       move the pins to the newest tagged releases
.github/workflows/     ci, steps (called by ci and bump-pins), bump-pins, docs, release
```

## Updating for a library release

1. The library releases; its examples repository moves its pin in a commit
   and, once CI is green on it, tags it `examples-v<version>`.
2. `bump-pins.yml`, the next morning or on demand, moves `pins.env`, the image
   tags and the CHANGELOG, verifies, and lands it on main. Until the examples
   tag exists, `check-pins.sh` is red and says the tag is what is missing.
3. Cut a tutorials release to publish the images: [RELEASING.md](https://github.com/AceMQ-Company/acemq-tutorials/blob/main/RELEASING.md).
