# Roadmap

What is left, roughly in order.

## Gaps in the examples repositories

These are not this repository's to fix; each is the examples repository's.

- **No standalone confirms example outside Java.** Only
  `acemq-java-amqp-examples/basic/01-publish-and-confirm` is about confirms.
  The path folds confirms into step 1 because every library confirms by
  default, but a step of its own on what a nack, a timeout and `mandatory` look
  like would need an example in the other four.
- **Twelve examples on the path have no README.md of their own**, so the step
  pages describe them with their row from the repository's table of examples:
  - .NET: `basic/01-publish-and-consume-csharp`, `basic/02-retries-and-dead-letters-csharp`,
    `basic/03-idempotent-consumer-csharp`, `basic/04-replay-csharp`,
    `basic/05-transactional-outbox-csharp`.
  - Go: `basic/01-publish-and-consume`, `basic/02-retries-and-dead-letters`,
    `basic/04-replay`, `intermediate/01-request-reply`,
    `intermediate/02-idempotent-consumer`, `intermediate/03-outbox`,
    `advanced/02-metrics-and-health`.
- **The examples repositories are not tagged.** The pins are commits, which
  works; a tag per library release in each examples repository would make
  `pins.env` read more plainly.

## Here

- **Bump on every library release.** `check-pins.sh` goes red when a library
  releases; set the version and the examples commit in `pins.env` and the image
  tags in README, docs and `compose.yaml`, then tag a release. Not automated yet
  — a scheduled job opening that pull request would be the next step.
- **The integrations.** The Spring Boot starter, .NET hosting, FastAPI and Rails
  integrations each have their own docs and examples; a step 8, "in your
  framework", would link them. Go has no integration.
- **Visual Basic.** .NET runs the C# example of each pair. A `TUTORIAL_VARIANT=vbnet`
  switch could run the VB twin instead, from the same image.
- **The broker version is not checked.** `RABBITMQ_IMAGE` in `pins.env` is moved
  by hand. The libraries support 3.13 and 4.x; the images carry 4.3.6.
- **Image size.** Each image is the broker plus a full toolchain (0.55–1.4
  GB). A slimmer runtime-only variant is possible for Java, .NET and Go, at the
  cost of `shell` no longer being able to rebuild an example.
- **A link from the landing page** at acemq.org to this site — the landing page
  is maintained separately.
