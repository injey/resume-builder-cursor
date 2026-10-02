#!/usr/bin/env bash
# Export a markdown resume to shareable DOCX and PDF.   #
#
# Usage:
#   ./scripts/export-resume.sh [path/to/resume.md]
#
# Defaults to jey/revised/Jeykumar_Nagarajan_Cloud_Data_Architect.md
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_MD="$REPO_ROOT/jey/revised/Jeykumar_Nagarajan_Cloud_Data_Architect.md"
MD_FILE="${1:-$DEFAULT_MD}"
TEMPLATES="$REPO_ROOT/templates"
REFERENCE_DOCX="$TEMPLATES/resume-reference.docx"
CSS="$TEMPLATES/resume-pdf.css"

if [[ ! -f "$MD_FILE" ]]; then
  echo "Error: markdown file not found: $MD_FILE" >&2
  exit 1
fi

MD_FILE="$(cd "$(dirname "$MD_FILE")" && pwd)/$(basename "$MD_FILE")"
OUT_DIR="$(dirname "$MD_FILE")"
BASE="$(basename "$MD_FILE" .md)"
DOCX="$OUT_DIR/${BASE}.docx"
PDF="$OUT_DIR/${BASE}.pdf"

require_pandoc() {
  if command -v pandoc >/dev/null 2>&1; then
    return 0
  fi
  echo "pandoc not found. Running install-export-deps.sh..." >&2
  "$REPO_ROOT/scripts/install-export-deps.sh"
}

find_chrome() {
  for candidate in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

ensure_reference_docx() {
  if [[ ! -f "$REFERENCE_DOCX" ]]; then
    mkdir -p "$TEMPLATES"
    pandoc -o "$REFERENCE_DOCX" --print-default-data-file reference.docx
  fi
}

export_docx() {
  echo "→ DOCX: $DOCX"
  pandoc "$MD_FILE" \
    -o "$DOCX" \
    --from markdown \
    --to docx \
    --reference-doc="$REFERENCE_DOCX"
}

export_pdf() {
  local chrome html

  chrome="$(find_chrome)" || {
    echo "Error: Chrome/Chromium/Edge required for PDF export. Install Google Chrome or run install-export-deps.sh." >&2
    exit 1
  }

  html="$(mktemp -t resume-export).html"
  echo "→ PDF:  $PDF"

  if pandoc "$MD_FILE" -o "$html" --standalone --embed-resources --css="$CSS" 2>/dev/null; then
    :
  else
    pandoc "$MD_FILE" -o "$html" --standalone --css="$CSS"
  fi

  if ! "$chrome" \
    --headless \
    --disable-gpu \
    --no-pdf-header-footer \
    --print-to-pdf="$PDF" \
    "file://${html}" 2>/dev/null; then
    "$chrome" --headless --disable-gpu --print-to-pdf="$PDF" "file://${html}"
  fi

  rm -f "$html"
}

main() {
  require_pandoc
  ensure_reference_docx

  if [[ ! -f "$CSS" ]]; then
    echo "Error: missing CSS template: $CSS" >&2
    exit 1
  fi

  export_docx
  export_pdf

  echo ""
  echo "Export complete."
  echo "  Markdown: $MD_FILE"
  echo "  Word:     $DOCX  (upload to Google Drive → Open with Google Docs)"
  echo "  PDF:      $PDF   (share directly)"
}

main "$@"
