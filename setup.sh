#!/usr/bin/env bash
set -euo pipefail

# GraphQL Training — Setup Script
# Checks prerequisites, initializes environment, and installs dependencies.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

ok()   { printf "${GREEN}[ok]${NC}    %s\n" "$1"; }
warn() { printf "${YELLOW}[warn]${NC}  %s\n" "$1"; }
fail() { printf "${RED}[miss]${NC}  %s\n" "$1"; }
info() { printf "${BOLD}==> %s${NC}\n" "$1"; }

errors=0

# --- Check prerequisites ---
info "Checking prerequisites"

# Node.js 18+
if command -v node &>/dev/null; then
  node_version=$(node -v | sed 's/v//')
  node_major=$(echo "$node_version" | cut -d. -f1)
  if [ "$node_major" -ge 18 ]; then
    ok "Node.js $node_version"
  else
    fail "Node.js $node_version found — need 18+ (brew install node)"
    errors=$((errors + 1))
  fi
else
  fail "Node.js not found (brew install node)"
  errors=$((errors + 1))
fi

# SQLite 3.35+
if command -v sqlite3 &>/dev/null; then
  sqlite_version=$(sqlite3 --version | awk '{print $1}')
  ok "SQLite $sqlite_version"
else
  fail "SQLite not found (brew install sqlite3)"
  errors=$((errors + 1))
fi

# golang-migrate
if command -v migrate &>/dev/null; then
  ok "golang-migrate"
else
  fail "golang-migrate not found (brew install golang-migrate)"
  errors=$((errors + 1))
fi

# go-task
if command -v task &>/dev/null; then
  ok "go-task"
else
  fail "go-task not found (brew install go-task)"
  errors=$((errors + 1))
fi

# Mockoon CLI (optional — only needed for stage 14+)
if command -v mockoon-cli &>/dev/null; then
  ok "Mockoon CLI"
else
  warn "Mockoon CLI not found — only needed for stage 14+ (npm install -g @mockoon/cli)"
fi

if [ "$errors" -gt 0 ]; then
  echo ""
  printf "${RED}${BOLD}%d required tool(s) missing. Install them and re-run this script.${NC}\n" "$errors"
  exit 1
fi

echo ""

# --- Initialize environment ---
info "Initializing environment"

if [ ! -f .env ]; then
  cp local.env .env
  ok "Created .env from local.env"
else
  ok ".env already exists"
fi

echo ""

# --- Install test runner ---
info "Installing test runner dependencies"

cd test-runner
if [ -d node_modules ]; then
  ok "test-runner/node_modules already exists — running npm install to update"
fi
npm install --no-fund --no-audit 2>&1 | tail -1
ok "Test runner dependencies installed"
cd ..

echo ""

# --- Optional: reset DB for a stage ---
if [ -n "${1:-}" ]; then
  stage="$1"
  info "Setting up database for stage $stage"
  task db:reset "STAGE=$stage"
  ok "Database ready for stage $stage"
  echo ""
fi

# --- Done ---
info "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Pick a stage:            task db:reset STAGE=02"
echo "  2. Read the concepts:       cat stages/02-types-and-enums/concepts.md"
echo "  3. Build your server at:    http://localhost:4000/graphql"
echo "  4. Run tests:               cd test-runner && npx cucumber-js --tags @stage:02"
