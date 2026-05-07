#!/usr/bin/env python3
"""Extract text from scanned PDFs using OCR."""
import argparse
import os
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='OCR text extraction from scanned PDFs')
    parser.add_argument('input_file', help='Path to the scanned PDF')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    parser.add_argument('-l', '--language', default='chi_sim+eng', help='OCR language(s)')
    parser.add_argument('-p', '--pages', help='Page range')
    parser.add_argument('--preserve-layout', action='store_true', default=True, help='Preserve layout')
    parser.add_argument('--no-preserve-layout', dest='preserve_layout', action='store_false')
    args = parser.parse_args()

    pdf_path = Path(args.input_file).resolve()
    if not pdf_path.exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    try:
        import fitz
        import pytesseract
        from PIL import Image
    except ImportError as e:
        print(f"Error: Missing dependency: {e}. Install with: pip install PyMuPDF pytesseract Pillow", file=sys.stderr)
        sys.exit(1)

    # Configure tesseract path for Windows
    tesseract_paths = [
        Path(r'C:\Program Files\Tesseract-OCR\tesseract.exe'),
        Path(r'C:\Program Files (x86)\Tesseract-OCR\tesseract.exe'),
    ]
    for tp in tesseract_paths:
        if tp.exists():
            pytesseract.pytesseract.tesseract_cmd = str(tp)
            break

    doc = fitz.open(str(pdf_path))
    print(f"Processing PDF with {len(doc)} pages...")

    if args.pages:
        page_nums = []
        for part in args.pages.split(','):
            if '-' in part:
                start, end = map(int, part.split('-'))
                page_nums.extend(range(start - 1, min(end, len(doc))))
            else:
                page_nums.append(int(part) - 1)
        page_nums = [p for p in page_nums if 0 <= p < len(doc)]
    else:
        page_nums = range(len(doc))

    all_text = []
    for page_num in page_nums:
        print(f"Processing page {page_num+1}...")
        page = doc[page_num]
        zoom = 300 / 72
        mat = fitz.Matrix(zoom, zoom)
        pix = page.get_pixmap(matrix=mat)
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

        config = '--psm 3' if args.preserve_layout else '--psm 6'
        text = pytesseract.image_to_string(img, lang=args.language, config=config)

        all_text.append(f"=== Page {page_num+1} ===")
        all_text.append(text)
        all_text.append("")

    doc.close()
    result = '\n'.join(all_text)

    print("\n" + "=" * 50)
    print("EXTRACTED TEXT:")
    print("=" * 50)
    print(result[:2000])
    if len(result) > 2000:
        print(f"\n... ({len(result) - 2000} more characters)")

    if args.output:
        Path(args.output).write_text(result, encoding='utf-8')
        print(f"\nSaved to: {args.output}")


if __name__ == '__main__':
    main()
