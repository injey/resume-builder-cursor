#!/usr/bin/env bash
# Install dependencies for resume PDF/DOCX export.
set -euo pipefail

echo "Checking resume export dependencies..."

if ! command -v pandoc >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing pandoc via Homebrew..."
    brew install pandoc
  else
    echo "Error: pandoc is required. Install from https://pandoc.org/installing.html" >&2
    exit 1
  fi
else
  echo "pandoc: $(pandoc --version | head -1)"
fi

if ! command -v pandoc >/dev/null 2>&1; then
  echo "Error: pandoc installation failed." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE_DOCX="$REPO_ROOT/templates/resume-reference.docx"

if [[ ! -f "$REFERENCE_DOCX" ]]; then
  echo "Creating default Word reference template at templates/resume-reference.docx"
  pandoc -o "$REFERENCE_DOCX" --print-default-data-file reference.docx
  echo "Tip: open templates/resume-reference.docx in Word or Google Docs once to set Arial 11pt body styles."
fi

CHROME=""
for candidate in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"; do
  if [[ -x "$candidate" ]]; then
    CHROME="$candidate"
    break
  fi
done

if [[ -z "$CHROME" ]]; then
  echo "Warning: Chrome/Chromium/Edge not found. PDF export will fail; DOCX export will still work."
else
  echo "PDF engine: $CHROME"
fi

echo "Done. Run: ./scripts/export-resume.sh"
