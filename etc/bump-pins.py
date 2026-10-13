#!/usr/bin/env python3
"""Move the pins to the newest library releases whose examples are tagged.

    ./etc/bump-pins.py                                  # compute and rewrite
    ./etc/bump-pins.py --set java=0.7.14:examples-v0.7.14   # rewrite to exactly this

For each language: the newest vX.Y.Z tag of acemq-<lang>-amqp, and the newest
examples-v<that>[-r<n>] tag of acemq-<lang>-amqp-examples. When that pair is not
what pins.env holds, it rewrites pins.env, the image tags in the README, the
docs and compose.yaml, and adds a line to the CHANGELOG's [Unreleased]. A
release with no examples tag yet is reported and left alone: it means the
examples repository has not been verified on it, and nothing here can be.

It reads GitHub and writes files; it does not commit, build or check anything.
etc/check-pins.sh is what says the result is right, and the bump-pins workflow
runs that and every step before anything lands.

On GitHub Actions it also writes `langs` (a JSON array) and `title` to
$GITHUB_OUTPUT, and a table to $GITHUB_STEP_SUMMARY.
"""
import json, os, pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LANGS = {"java": "Java", "python": "Python", "ruby": "Ruby", "dotnet": ".NET", "go": "Go"}
ORG = "https://github.com/AceMQ-Company"


def tags(repo):
    out = subprocess.run(["git", "ls-remote", "--tags", f"{ORG}/{repo}"],
                         check=True, capture_output=True, text=True).stdout
    return {line.split("refs/tags/", 1)[1] for line in out.splitlines() if not line.endswith("^{}")}


def vkey(s):  # 0.7.15 < 0.7.15-r2 < 0.7.15-r10 < 0.7.16
    return [int(n) for n in re.findall(r"\d+", s)]


def pins():
    return dict(re.findall(r"^([A-Z_]+)=(.*)$", (ROOT / "pins.env").read_text(), re.M))


def rewrite(lang, version, tag, old_version):
    p = ROOT / "pins.env"
    s = p.read_text()
    s = re.sub(rf"^{lang.upper()}_VERSION=.*$", f"{lang.upper()}_VERSION={version}", s, flags=re.M)
    s = re.sub(rf"^{lang.upper()}_EXAMPLES=.*$", f"{lang.upper()}_EXAMPLES={tag}", s, flags=re.M)
    p.write_text(s)
    if version != old_version:
        pattern = re.compile(rf"(acemq-tutorials-{lang}:)\d+\.\d+\.\d+")
        for f in [ROOT / "README.md", ROOT / "compose.yaml", *sorted((ROOT / "docs").rglob("*.md"))]:
            t = f.read_text()
            n = pattern.sub(rf"\g<1>{version}", t)
            if n != t:
                f.write_text(n)


def changelog(lines):
    p = ROOT / "CHANGELOG.md"
    s = p.read_text()
    head = s.index("## [Unreleased]\n") + len("## [Unreleased]\n")
    end = s.find("\n## [", head)
    section = s[head:end if end != -1 else len(s)]
    bullets = "".join(f"- {line}\n" for line in lines)
    if "### Changed\n" in section:
        at = head + section.index("### Changed\n") + len("### Changed\n")
        # After the heading's blank line and any bullets already there.
        rest = s[at:]
        m = re.match(r"\n?((?:- .*\n(?:  .*\n)*)*)", rest)
        at += m.end()
        s = s[:at] + bullets + s[at:]
    else:
        s = s[:head] + f"\n### Changed\n\n{bullets}" + s[head:]
    p.write_text(s)


def main(argv):
    forced = {}
    while argv:
        if argv[0] == "--set" and len(argv) > 1:
            lang, _, pair = argv[1].partition("=")
            version, _, tag = pair.partition(":")
            if lang not in LANGS or not version or not tag:
                sys.exit(f"--set wants <lang>=<version>:<examples tag>, got {argv[1]}")
            forced[lang] = (version, tag)
            argv = argv[2:]
        else:
            sys.exit(__doc__)

    current = pins()
    moved, report, notes = [], [], []
    for lang, name in LANGS.items():
        have_v, have_t = current[f"{lang.upper()}_VERSION"], current[f"{lang.upper()}_EXAMPLES"]
        if forced:
            if lang not in forced:
                continue
            want_v, want_t = forced[lang]
        else:
            releases = [t[1:] for t in tags(f"acemq-{lang}-amqp") if re.fullmatch(r"v\d+\.\d+\.\d+", t)]
            if not releases:
                sys.exit(f"{lang}: no release tags on acemq-{lang}-amqp")
            want_v = max(releases, key=vkey)
            verified = [t for t in tags(f"acemq-{lang}-amqp-examples")
                        if re.fullmatch(rf"examples-v{re.escape(want_v)}(-r\d+)?", t)]
            if not verified:
                state = "current" if want_v == have_v else "**waiting**"
                report.append(f"| {name} | {have_v} | {want_v} | no `examples-v{want_v}` yet | {state} |")
                if want_v != have_v:
                    notes.append(f"{name} {want_v} is released but acemq-{lang}-amqp-examples has no "
                                 f"examples-v{want_v} tag yet, so it has not been verified on it. "
                                 f"Nothing was done for {name}.")
                continue
            want_t = max(verified, key=lambda t: vkey(t[len("examples-v"):]))
        if (want_v, want_t) == (have_v, have_t):
            report.append(f"| {name} | {have_v} | {want_v} | `{want_t}` | current |")
            continue
        rewrite(lang, want_v, want_t, have_v)
        label = f"{name} {want_v}" if want_v != have_v else f"{name} {want_t}"
        moved.append((lang, label, f"{name} {want_v}, examples `{want_t}` (was {have_v}, `{have_t}`)."))
        report.append(f"| {name} | {have_v} | {want_v} | `{want_t}` | **moves** |")

    if moved and not forced:
        changelog([f"Track {line}" for _, _, line in moved])

    title = "Track " + ", ".join(label for _, label, _ in moved) if moved else ""
    print(title or "every pin is current", file=sys.stderr)
    for n in notes:
        print(n, file=sys.stderr)
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"langs={json.dumps([lang for lang, _, _ in moved])}\ntitle={title}\n")
    if os.environ.get("GITHUB_STEP_SUMMARY") and report:
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
            f.write("| Language | Pinned | Newest release | Examples tag | |\n|---|---|---|---|---|\n")
            f.write("\n".join(report) + "\n\n" + "".join(f"> {n}\n>\n" for n in notes) + "\n")


if __name__ == "__main__":
    main(sys.argv[1:])
