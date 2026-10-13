#!/usr/bin/env bash
# Render the site into site/.
#
#   ./etc/build-site.sh
#
# Built the way the libraries build theirs -- pandoc over docs/*.md with the
# same stylesheet -- plus one page per step, generated from path/*.tsv and
# pins.env. A step page holds no tutorial prose of its own: it says what the
# step is, how to run it, and links to the example at the pinned examples tag and to
# each library's own tutorial. The one-paragraph lead of each example's README
# is quoted from that tag, so the page says what the example shows without
# anybody keeping a second copy of it.
#
# Needs pandoc, python3 and network access to raw.githubusercontent.com.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=site
GEN="$OUT/.gen"

command -v pandoc >/dev/null || { echo "pandoc is required" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/assets" "$GEN"
cp docs/assets/* "$OUT/assets/"
mv "$OUT/assets/style.css" "$OUT/style.css"

# The generated markdown: one page per step, and the path table that index.md
# includes where it says <!-- path -->.
python3 - "$GEN" <<'PY'
import re, sys, urllib.error, urllib.request

gen = sys.argv[1]
langs = [("java", "Java"), ("python", "Python"), ("ruby", "Ruby"), ("dotnet", ".NET"), ("go", "Go")]
pins = dict(l.strip().split("=", 1) for l in open("pins.env") if re.match(r"^[A-Z_]+=", l))

def rows(name):
    for line in open(f"path/{name}"):
        if line.strip() and not line.startswith("#"):
            yield line.rstrip("\n").split("\t")

steps = list(rows("steps.tsv"))
examples = list(rows("examples.tsv"))

def version(lang): return pins[f"{lang.upper()}_VERSION"]
def tag(lang): return pins[f"{lang.upper()}_EXAMPLES"]
def image(lang): return f"ghcr.io/acemq-company/acemq-tutorials-{lang}:{version(lang)}"
def tree(lang, d): return f"https://github.com/AceMQ-Company/acemq-{lang}-amqp-examples/tree/{tag(lang)}/{d}"
def docs(lang, page): return f"https://acemq.org/acemq-{lang}-amqp/{page}.html"

def fetch(lang, path):
    url = f"https://raw.githubusercontent.com/AceMQ-Company/acemq-{lang}-amqp-examples/{tag(lang)}/{path}"
    try:
        return urllib.request.urlopen(url, timeout=30).read().decode()
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise

def lead(lang, d):
    """What the example shows, in its own repository's words, at the pinned tag:
    the first paragraph of its README, or -- for an example without one -- its row
    in the table of examples in the repository's README."""
    text = fetch(lang, f"{d}/README.md")
    if text is not None:
        for p in (p.strip() for p in re.split(r"\n\s*\n", text)):
            if p and not p.startswith(("#", "[!", "```", "|", ">")):
                # Relative links in the README point inside that repository.
                return re.sub(r"\]\((?!https?://|#)([^)]+)\)", lambda m: f"]({tree(lang, d)}/{m.group(1)})", p)
    for line in (fetch(lang, "README.md") or "").splitlines():
        if line.startswith("|") and f"]({d})" in line:
            cells = [c.strip() for c in line.strip("|").split("|")]
            return " ".join(c for c in cells if c and "](" not in c).rstrip(".") + "."
    raise SystemExit(f"{lang} {d}: no README and no row in the repository's table of examples")

titles = {}
for n, title, summary, pages in steps:
    titles[n] = title
    out = [f"# Step {n} — {title}", "", f"**{summary}**", ""]
    prev = f"[← step {int(n)-1}](step-{int(n)-1}.md)" if int(n) > 1 else "[← the path](index.md)"
    nxt = f"[step {int(n)+1} →](step-{int(n)+1}.md)" if int(n) < len(steps) else "[the path →](index.md)"
    out += [f"{prev} · {nxt}", "", "## Run it", "",
            "One command, whichever language you came for. The image carries the toolchain, "
            "the library and RabbitMQ; the management UI is on <http://localhost:15672> "
            "(guest/guest) while it runs, and `--keep` holds it open afterwards.", "", "```bash"]
    for lang, name in langs:
        out.append(f"docker run --rm -p 15672:15672 {image(lang)} step {n}")
    out += ["```", "", "## Side by side", "",
            "| | " + " | ".join(name for _, name in langs) + " |",
            "|---|" + "---|" * len(langs)]
    cells = []
    for lang, _ in langs:
        ds = [e[2] for e in examples if e[0] == n and e[1] == lang]
        cells.append("<br>".join(f"[`{d.split('/')[-1]}`]({tree(lang, d)})" for d in ds) or "—")
    out.append("| Example | " + " | ".join(cells) + " |")
    for page in pages.split(","):
        label = page.replace("tutorial-", "tutorial: ").replace("-", " ")
        out.append(f"| {label.capitalize()} | " + " | ".join(f"[{name}]({docs(lang, page)})" for lang, name in langs) + " |")
    out.append("")
    for lang, name in langs:
        out += [f"## {name}", "", f"`acemq-{lang}-amqp` {version(lang)}, "
                f"[acemq-{lang}-amqp-examples {tag(lang)}](https://github.com/AceMQ-Company/acemq-{lang}-amqp-examples/tree/{tag(lang)}).", ""]
        for d in [e[2] for e in examples if e[0] == n and e[1] == lang]:
            out += [f"### [`{d}`]({tree(lang, d)})", "", lead(lang, d), ""]
    open(f"{gen}/step-{n}.md", "w").write("\n".join(out))

table = ["| Step | | What you learn |", "|---|---|---|"]
for n, title, summary, _ in steps:
    table.append(f"| {n} | [{title}](step-{n}.md) | {summary} |")
open(f"{gen}/path.md", "w").write("\n".join(table) + "\n")

images = ["| Language | Image | Library | Examples |", "|---|---|---|---|"]
for lang, name in langs:
    images.append(f"| {name} | `{image(lang)}` | [acemq-{lang}-amqp {version(lang)}](https://github.com/AceMQ-Company/acemq-{lang}-amqp/releases/tag/v{version(lang)}) "
                  f"| [`{tag(lang)}`](https://github.com/AceMQ-Company/acemq-{lang}-amqp-examples/tree/{tag(lang)}) |")
open(f"{gen}/images.md", "w").write("\n".join(images) + "\n")
print(f"generated {len(steps)} step pages")
PY

if pandoc --help 2>&1 | grep -q -- '--syntax-highlighting'; then
  HIGHLIGHT=(--syntax-highlighting=tango)
else
  HIGHLIGHT=(--highlight-style=tango)
fi

NAV='<nav class="top">
  <span class="brand"><img src="assets/acemq.png" alt="AceMQ"> tutorials</span>
  <a class="tutorials" href="index.html">The path</a>
  <div class="group">
    <button type="button" aria-haspopup="true">Steps</button>
    <div class="menu">'
while IFS=$'\t' read -r n title _; do
  NAV+="
      <a href=\"step-$n.html\">$n. $title</a>"
done < <(grep -v -e '^#' -e '^$' path/steps.tsv)
NAV+='
    </div>
  </div>
  <a href="images.html">The images</a>
  <a href="design.html">How this is built</a>
  <a class="enterprise" href="https://acemq.org/acemq-java-amqp/">Java</a>
  <a class="enterprise" href="https://acemq.org/acemq-python-amqp/">Python</a>
  <a class="enterprise" href="https://acemq.org/acemq-ruby-amqp/">Ruby</a>
  <a class="enterprise" href="https://acemq.org/acemq-dotnet-amqp/">.NET</a>
  <a class="enterprise" href="https://acemq.org/acemq-go-amqp/">Go</a>
</nav>
<main>'

FOOT='</main>
<footer>
  <a href="https://github.com/AceMQ-Company/acemq-tutorials">acemq-tutorials</a> &mdash;
  Apache-2.0, and provided without warranty &mdash; see the <a href="licence.html">licence</a>.
  The examples live in each library&rsquo;s examples repository and are linked at the tag the images were built from.
  RabbitMQ is a trademark of its owner. This project is not affiliated with it.
</footer>'

printf '%s' "$NAV" > "$GEN/nav.html"
printf '%s' "$FOOT" > "$GEN/foot.html"

render() {
  local source="$1" base="$2" title
  title="$(head -n1 "$source" | sed 's/^#\{1,6\} *//')"
  [ "$base" = index ] && title="AceMQ tutorials" || title="$title — AceMQ tutorials"
  pandoc "$source" --from=gfm --to=html5 --standalone \
    --metadata pagetitle="$title" "${HIGHLIGHT[@]}" --css=style.css \
    --include-before-body="$GEN/nav.html" --include-after-body="$GEN/foot.html" \
    --output "$OUT/$base.html"
  # Links between pages are written .md, so they also work read on GitHub.
  perl -pi -e 's{href="([^":#]*)\.md(#[^"]*)?"}{href="$1.html$2"}g' "$OUT/$base.html"
  echo "  rendered $base.html"
}

# index.md and images.md pull in a generated table where they say so.
for f in docs/*.md; do
  base="$(basename "${f%.md}")"
  perl -pe '
    if (/^<!-- (\w+) -->$/) { local $/; open my $h, "<", "'"$GEN"'/$1.md" or die "no $1.md"; $_ = <$h>; }
  ' "$f" > "$GEN/$base.src.md"
  if [ "$base" = licence ]; then
    { echo; echo '```'; cat LICENSE; echo '```'; } >> "$GEN/$base.src.md"
  fi
  render "$GEN/$base.src.md" "$base"
done
for f in "$GEN"/step-*.md; do render "$f" "$(basename "${f%.md}")"; done

# Every internal link resolves.
python3 - <<'PY'
import os, re, sys
pages = [f for f in os.listdir("site") if f.endswith(".html")]
broken = [f"{f} -> {h}" for f in pages
          for h in re.findall(r'href="([^"]+)"', open("site/" + f).read())
          if not h.startswith(("http://", "https://", "#", "mailto:"))
          and h.split("#")[0] and not os.path.exists("site/" + h.split("#")[0])]
if broken:
    print("::error::the site links to pages that do not exist:", *broken, sep="\n  ")
    sys.exit(1)
print(f"{len(pages)} pages, every internal link resolves")
PY

rm -rf "$GEN"
touch "$OUT/.nojekyll"
echo "Site written to $OUT/index.html"
