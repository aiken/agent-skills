#!/usr/bin/env python3
"""Split a PDF file into multiple files."""
import argparse
import os
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Split a PDF into individual pages or page ranges')
    parser.add_argument('input_file', help='Path to the PDF file')
    parser.add_argument('-o', '--output-pattern', default='page_{}.pdf', help='Output filename pattern')
    parser.add_argument('-p', '--page-range', help='Page range, e.g. 1-5,7,10-12')
    parser.add_argument('-d', '--output-dir', help='Output directory (default: same as input)')
    args = parser.parse_args()

    pdf_path = Path(args.input_file).resolve()
    if not pdf_path.exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    try:
        from PyPDF2 import PdfReader, PdfWriter
    except ImportError:
        print("Error: PyPDF2 is required. Install with: pip install PyPDF2", file=sys.stderr)
        sys.exit(1)

    out_dir = Path(args.output_dir).resolve() if args.output_dir else pdf_path.parent
    out_dir.mkdir(parents=True, exist_ok=True)

    reader = PdfReader(str(pdf_path))
    total_pages = len(reader.pages)

    if args.page_range:
        pages = []
        for part in args.page_range.split(','):
            if '-' in part:
                start, end = map(int, part.split('-'))
                pages.extend(range(start - 1, min(end, total_pages)))
            else:
                pages.append(int(part) - 1)
        pages = [p for p in pages if 0 <= p < total_pages]
    else:
        pages = list(range(total_pages))

    for i, page_num in enumerate(pages):
        writer = PdfWriter()
        writer.add_page(reader.pages[page_num])
        out_path = out_dir / args.output_pattern.format(page_num + 1)
        with open(out_path, 'wb') as f:
            writer.write(f)

    print(f"Created {len(pages)} PDF file(s) in {out_dir}")


if __name__ == '__main__':
    main()
