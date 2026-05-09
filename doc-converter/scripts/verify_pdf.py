#!/usr/bin/env python3
"""
Verify PDF content and check for sensitive data leakage.

This script replaces unreliable binary grepping (findstr/Select-String)
with proper PDF text extraction via pdfminer.six.

Usage:
    python verify_pdf.py document.pdf --contains "模型配置" "model"
    python verify_pdf.py document.pdf --leak-check --forbid "file://" "D:\\coding" "ops_sts"
    python verify_pdf.py document.pdf --contains " expected text " --leak-check

Exit codes:
    0 - All checks passed
    1 - Missing required text OR forbidden text found
    2 - PDF read error or dependency missing
"""
from __future__ import annotations

import argparse
import sys
import os

try:
    from pdfminer.high_level import extract_text
except ImportError:
    print("ERROR: pdfminer.six is required. Install: python -m pip install pdfminer.six")
    sys.exit(2)


def extract_all_text(pdf_path: str) -> str:
    """Extract full text from a PDF file."""
    if not os.path.isfile(pdf_path):
        raise FileNotFoundError(f"PDF not found: {pdf_path}")
    return extract_text(pdf_path)


def check_contains(text: str, required: list[str]) -> list[str]:
    """Return list of required strings that are MISSING."""
    missing = []
    for phrase in required:
        if phrase not in text:
            missing.append(phrase)
    return missing


def check_forbidden(text: str, forbidden: list[str]) -> list[str]:
    """Return list of forbidden strings that ARE present."""
    found = []
    for phrase in forbidden:
        if phrase in text:
            found.append(phrase)
    return found


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify PDF content and detect information leakage."
    )
    parser.add_argument("pdf", help="Path to the PDF file")
    parser.add_argument(
        "--contains", nargs="+", metavar="TEXT",
        help="Strings that MUST be present in the PDF"
    )
    parser.add_argument(
        "--leak-check", action="store_true",
        help="Enable leakage detection (checks for local paths, URLs, etc.)"
    )
    parser.add_argument(
        "--forbid", nargs="+", metavar="TEXT",
        help="Additional forbidden strings (used with --leak-check)"
    )
    parser.add_argument(
        "--show-text", action="store_true",
        help="Print extracted text to stdout (for debugging)"
    )
    parser.add_argument(
        "--max-preview", type=int, default=500,
        help="Max characters to show with --show-text (default: 500)"
    )

    args = parser.parse_args()

    try:
        full_text = extract_all_text(args.pdf)
    except Exception as exc:
        print(f"ERROR reading PDF: {exc}")
        return 2

    if args.show_text:
        preview = full_text[:args.max_preview]
        print("=== Extracted text preview ===")
        print(preview)
        if len(full_text) > args.max_preview:
            print(f"\n... ({len(full_text)} total chars)")
        print("=== End preview ===\n")

    exit_code = 0

    # Check required content
    if args.contains:
        missing = check_contains(full_text, args.contains)
        if missing:
            print("FAIL: Required text NOT found in PDF:")
            for m in missing:
                print(f"  - '{m}'")
            exit_code = 1
        else:
            print("PASS: All required text found.")

    # Check leakage
    forbidden_patterns = []
    if args.leak_check:
        # Default leakage patterns
        forbidden_patterns.extend([
            "file:///",          # Local file URLs
            "D:/coding",         # Common local project path (adjust as needed)
            "D:\\coding",        # Windows backslash variant
            "C:/Users/",         # User home paths
            "C:\\Users\\",
            "pdf-style",         # Common temp CSS filename
            "ops_sts",           # Project name leakage
        ])
    if args.forbid:
        forbidden_patterns.extend(args.forbid)

    if forbidden_patterns:
        found = check_forbidden(full_text, forbidden_patterns)
        if found:
            print("FAIL: Forbidden/leaked text FOUND in PDF:")
            for f in found:
                print(f"  - '{f}'")
            exit_code = 1
        else:
            print("PASS: No forbidden text found.")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
