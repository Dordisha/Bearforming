#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v gh >/dev/null || { echo "Install GitHub CLI (gh) and authenticate it on your Mac, then rerun."; exit 1; }
command -v git >/dev/null || { echo "Git is required."; exit 1; }
login=$(gh api user --jq .login)
if [[ "$login" != "Dordisha" ]]; then
  echo "Expected GitHub account Dordisha; currently signed in as $login. Switch accounts and rerun."
  exit 1
fi
if gh repo view Dordisha/bearforming --json name >/dev/null 2>&1; then
  echo "Dordisha/bearforming already exists. Stop here and share its link so we can inspect it before pushing."
  exit 1
fi
if [[ ! -d .git ]]; then
  git init -b main
fi
if [[ $(git branch --show-current) != main ]]; then
  echo "Expected branch main. Inspect this checkout before publishing."
  exit 1
fi
git add .
if ! git diff --cached --quiet; then
  git commit -m "Initialize Bearforming iPhone shell and workout persistence"
fi
gh repo create Dordisha/bearforming --private --description "Bearforming: native iPhone workout logger and personal fitness journey" --source . --remote origin --push
