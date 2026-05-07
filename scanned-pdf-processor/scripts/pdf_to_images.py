#!/usr/bin/env python3
"""Convert PDF pages to images."""
import argparse
import os
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Convert PDF pages to images')
    parser.add_argument('input_file', help='Path to the PDF file')
    parser.add_argument('-o', '--output-dir', default='./pdf_images', help='Output directory')
    parser.add_argument('-d', '--dpi', type=int, default=300, help='Resolution in DPI')
    parser.add_argument('-f', '--format', choices=['png', 'jpg', 'tiff'], default='png', help='Image format')
    parser.add_argument('-p', '--pages', help='Page range, e.g. 1-5,7,10')
    args = parser.parse_args()

    pdf_path = Path(args.input_file).resolve()
    if not pdf_path.exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    try:
        import fitz  # PyMuPDF
    except ImportError:
        print("Error: PyMuPDF is required. Install with: pip install PyMuPDF", file=sys.stderr)
        sys.exit(1)

    out_dir = Path(args.output_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    doc = fitz.open(str(pdf_path))
    print(f"PDF has {len(doc)} pages")

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

    print(f"Processing {len(page_nums)} pages...")
    base_name = pdf_path.stem
    zoom = args.dpi / 72
    mat = fitz.Matrix(zoom, zoom)

    for page_num in page_nums:
        page = doc[page_num]
        pix = page.get_pixmap(matrix=mat)
        output_file = out_dir / f"{base_name}_page_{page_num+1:04d}.{args.format}"

        if args.format == 'png':
            pix.save(str(output_file))
        else:
            try:
                from PIL import Image
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                if args.format == 'jpg':
                    img.save(output_file, "JPEG", quality=95)
                else:
                    img.save(output_file, "TIFF")
            except ImportError:
                print("Error: Pillow is required for JPG/TIFF. Install with: pip install Pillow", file=sys.stderr)
                sys.exit(1)

        print(f"  Page {page_num+1} -> {output_file.name} ({pix.width}x{pix.height})")

    doc.close()
    print(f"\nConversion complete. Images saved to: {out_dir}")


if __name__ == '__main__':
    main()
