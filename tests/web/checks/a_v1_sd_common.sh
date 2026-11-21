# Shared by the a-v1-start-docs checks: copy the product as a clean clone would have it.
# fresh_copy DIR: the files git tracks or would track (no .git, no ignored files) into DIR.
fresh_copy() {
  mkdir -p "$1"
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -C "$1" -xf -
  else
    tar --exclude=.git -cf - . | tar -C "$1" -xf -
  fi
}
