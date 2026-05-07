#!/usr/bin/env python3
"""Extract text content from PDF files."""
import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def extract_with_pdftotext(pdf_path: Path, out_path: Path, page_range: str = None) -> bool:
    pdftotext = shutil.which('pdftotext')
    if not pdftotext:
        for p in [
            Path(r'C:\Program Files\xpdf\pdftotext.exe'),
            Path(r'C:\Program Files (x86)\xpdf\pdftotext.exe'),
            Path.home() / 'AppData' / 'Local' / 'xpdf' / 'pdftotext.exe',
        ]:
            if p.exists():
                pdftotext = str(p)
                break
    if not pdftotext:
        return False

    args = [pdftotext, '-layout']
    if page_range:
        parts = page_range.split('-')
        args += ['-f', parts[0], '-l', parts[-1].split(',')[0]]
    args += [str(pdf_path), str(out_path)]
    try:
        subprocess.run(args, check=True, capture_output=True)
        return True
    except Exception:
        return False


def extract_with_python(pdf_path: Path, out_path: Path, page_range: str = None) -> bool:
    try:
        try:
            import pdfplumber
            use_plumber = True
        except ImportError:
            use_plumber = False

        if use_plumber:
            text_parts = []
            with pdfplumber.open(str(pdf_path)) as pdf:
                pages = _parse_pages(page_range, len(pdf.pages))
                for i in pages:
                    page_text = pdf.pages[i].extract_text()
                    if page_text:
                        text_parts.append(page_text)
            out_path.write_text('\n\n'.join(text_parts), encoding='utf-8')
        else:
            from PyPDF2 import PdfReader
            text_parts = []
            with open(pdf_path, 'rb') as f:
                reader = PdfReader(f)
                pages = _parse_pages(page_range, len(reader.pages))
                for i in pages:
                    page_text = reader.pages[i].extract_text()
                    if page_text:
                        text_parts.append(page_text)
            out_path.write_text('\n\n'.join(text_parts), encoding='utf-8')
        return True
    except Exception:
        return False


def _parse_pages(page_range: str, total: int) -> list:
    if not page_range:
        return list(range(total))
    pages = []
    for part in page_range.split(','):
        if '-' in part:
            start, end = map(int, part.split('-'))
            pages.extend(range(start - 1, min(end, total)))
        else:
            pages.append(int(part) - 1)
    return [p for p in pages if 0 <= p < total]


def main():
    parser = argparse.ArgumentParser(description='Extract text from a PDF file')
    parser.add_argument('input_file', help='Path to the PDF file')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    parser.add_argument('-p', '--pages', help='Page range, e.g. 1-5,7,10')
    args = parser.parse_args()

    pdf_path = Path(args.input_file).resolve()
    if not pdf_path.exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    import tempfile
    tmp = Path(tempfile.gettempdir()) / 'pdf_extract.txt'

    success = False
    if not success:
        success = extract_with_pdftotext(pdf_path, tmp, args.pages)
    if not success:
        success = extract_with_python(pdf_path, tmp, args.pages)

    if success:
        text = tmp.read_text(encoding='utf-8')
        if args.output:
            Path(args.output).write_text(text, encoding='utf-8')
            print(f"Text extracted to: {args.output}")
        else:
            print(text)
        tmp.unlink(missing_ok=True)
    else:
        print("Failed to extract text. Please install xpdf (pdftotext) or Python with PyPDF2/pdfplumber.", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
