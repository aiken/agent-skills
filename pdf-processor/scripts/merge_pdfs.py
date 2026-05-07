#!/usr/bin/env python3
"""Merge multiple PDF files into one."""
import argparse
import sys
from pathlib import Path


def merge_with_pypdf2(input_files: list, output_file: Path) -> bool:
    try:
        from PyPDF2 import PdfMerger
        merger = PdfMerger()
        for pdf in input_files:
            merger.append(str(pdf))
        merger.write(str(output_file))
        merger.close()
        return True
    except Exception as e:
        print(f"PyPDF2 merge failed: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description='Merge multiple PDF files')
    parser.add_argument('input_files', nargs='+', help='PDF files to merge (in order)')
    parser.add_argument('-o', '--output', required=True, help='Output merged PDF path')
    args = parser.parse_args()

    files = [Path(f).resolve() for f in args.input_files]
    for f in files:
        if not f.exists():
            print(f"Error: File not found: {f}", file=sys.stderr)
            sys.exit(1)

    if len(files) < 2:
        print("Error: At least 2 PDF files are required for merging", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    success = merge_with_pypdf2(files, output_path)
    if success:
        print(f"Merged PDF saved to: {output_path}")
    else:
        print("Failed to merge PDFs. Please install Python with PyPDF2.", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
