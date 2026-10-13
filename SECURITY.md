# Reporting a vulnerability

Email **security@acemq.com** with what you found and how to reproduce it. Please do
not open a public issue for anything exploitable.

You should get an acknowledgement within two working days, and an assessment of
whether it is a vulnerability, what is affected, and a rough timeline within a week.

## What is in scope

The images this repository publishes and how they are built: `images/Dockerfile`,
the `tutorial` entrypoint, and the workflows that publish them.

## What is not

- **The broker's default `guest`/`guest` account.** These images are for learning
  on your own machine. Do not expose their ports to a network you do not control,
  and do not run them as a broker for anything real.
- **Vulnerabilities in a library or an example.** Report those to the library's own
  repository, where the code lives.
- **Vulnerabilities in RabbitMQ, a language toolchain, or a base image** — report
  those upstream. A rebuild here picks up their fixes.
