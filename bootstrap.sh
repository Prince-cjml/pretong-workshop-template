#!/usr/bin/env bash
set -euo pipefail

COURSE_URL="${COURSE_URL:-https://github.com/Prince-cjml/pretong-workshop-upstream.git}"

require_clean_worktree() {
    if ! git diff --quiet; then
        printf '%s\n' \
          "ERROR: bootstrap requires a clean working tree."

        exit 1
    fi

    if [[ -n "$(git status --porcelain)" ]]; then
        printf '%s\n' \
          "ERROR: bootstrap requires a clean working tree."

        exit 1
    fi
}

if ! git remote get-url origin \
  >/dev/null 2>&1
then
    printf '%s\n' \
      "ERROR: this repository has no origin remote."

    exit 1
fi

ORIGIN_URL="$(git remote get-url origin)"

if [[ "$ORIGIN_URL" == "$COURSE_URL" ]]; then
    echo "ERROR: bootstrap must run in a personal assignment repository."
    exit 1
fi

require_clean_worktree

if git show-ref \
  --verify \
  --quiet \
  refs/heads/submission
then
    echo "ERROR: submission already exists."
    exit 1
fi

if git remote get-url course >/dev/null 2>&1; then
    git remote set-url course "$COURSE_URL"
else
    git remote add course "$COURSE_URL"
fi

git config --unset-all remote.course.fetch 2>/dev/null || true
git config --add remote.course.fetch "+refs/heads/course/*:refs/remotes/course/*"

git fetch \
  --force \
  --prune \
  course \
  "+refs/tags/course/*:refs/tags/course/*"

git fetch \
  --force \
  --prune \
  course

required_refs=(
  course/base-v3
  course/broken-start-v3
  course/native-integration-v3
  course/training-observability-v3
  course/recovery-data-v3
  course/bad-parallel-loader-v3
  course/immutable-v3
)

for ref in "${required_refs[@]}"; do
    if ! git rev-parse \
      --verify \
      "${ref}^{commit}" \
      >/dev/null 2>&1
    then
        echo "ERROR: missing course ref: $ref"
        exit 1
    fi
done

git switch \
  --create submission \
  course/broken-start-v3

git config \
  branch.submission.description \
  "Pretong workshop submission branch. Do not rewrite published history."

require_clean_worktree

git push \
  --set-upstream origin submission

cat <<'EOF'
Bootstrap complete.

Current branch:
  submission

Next commands:
  bash scripts/doctor.sh bootstrap
  conda create -y -n hybridml-rescue --file conda-linux-64.lock
  conda activate hybridml-rescue
  bash scripts/doctor.sh environment

Do not reset, rebase, delete, or force-push submission.
EOF
