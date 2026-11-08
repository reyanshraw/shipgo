import pathlib
import sys

REPLACEMENTS = {
    "shipgo.sh": [
        (
            '[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"',
            '# shellcheck source=/dev/null\n[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"',
        ),
        (
            'git push origin ":refs/tags/$n" 2>/dev/null && ok "Remote deleted" || warn "Remote missing"',
            'if git push origin ":refs/tags/$n" 2>/dev/null; then ok "Remote deleted"; else warn "Remote missing"; fi',
        ),
        (
            '[ -n "$t" ] && gh pr create --title "$t" --body "" --web || gh pr create --fill --web; }',
            'if [ -n "$t" ]; then gh pr create --title "$t" --body "" --web; else gh pr create --fill --web; fi; }',
        ),
        (
            '[ -n "$t" ] && gh pr create --draft --title "$t" --body "" --web || gh pr create --draft --fill --web; }',
            'if [ -n "$t" ]; then gh pr create --draft --title "$t" --body "" --web; else gh pr create --draft --fill --web; fi; }',
        ),
        (
            '[ -n "$t" ] && glab mr create --title "$t" --web || glab mr create --fill --web; }',
            'if [ -n "$t" ]; then glab mr create --title "$t" --web; else glab mr create --fill --web; fi; }',
        ),
        (
            'info "Testing $u"; git ls-remote --heads "$u" >/dev/null 2>&1 && ok Reachable || warn Unreachable; }',
            'info "Testing $u"; if git ls-remote --heads "$u" >/dev/null 2>&1; then ok Reachable; else warn Unreachable; fi; }',
        ),
        (
            'cmd_init(){ local d="${1:-.}"; mkdir -p "$d" && cd "$d"||die "Cannot create $d"',
            'cmd_init(){ local d="${1:-.}"; mkdir -p "$d" || die "Cannot create $d"; cd "$d" || die "Cannot create $d"',
        ),
        (
            '[ -n "$d" ] && git clone "$u" "$d" || git clone "$u"; ok Cloned.; }',
            'if [ -n "$d" ]; then git clone "$u" "$d" || die "Clone failed"; else git clone "$u" || die "Clone failed"; fi; ok Cloned.; }',
        ),
    ],
    "scripts/dist-manifests.sh": [
        (
            'SUMS="$2"',
            '# shellcheck disable=SC2034  # consumed indirectly via $SUMS\nexport SUMS="$2"',
        ),
    ],
}


def patch(path: pathlib.Path, pairs):
    text = path.read_text()
    for old, new in pairs:
        if old not in text:
            print(f"  SKIP (not found): {old[:60]}...", file=sys.stderr)
            continue
        count = text.count(old)
        text = text.replace(old, new, 1)
        print(f"  patched ({count} match{'es' if count > 1 else ''}): {old[:60]}...")
    path.write_text(text)


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for rel, pairs in REPLACEMENTS.items():
        p = root / rel
        if not p.exists():
            print(f"MISSING: {p}", file=sys.stderr)
            continue
        print(f"{rel}:")
        patch(p, pairs)


if __name__ == "__main__":
    main()
