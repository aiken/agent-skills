#!/usr/bin/env python3
"""Convert documents between various formats."""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

FORMAT_MAP = {
    '.md': 'markdown',
    '.markdown': 'markdown',
    '.docx': 'docx',
    '.pdf': 'pdf',
    '.html': 'html',
    '.htm': 'html',
    '.txt': 'plain',
    '.rst': 'rst',
}


def detect_pdf_engine():
    for engine in ['xelatex', 'lualatex', 'pdflatex']:
        if shutil.which(engine):
            return engine
    return None


def docx_to_pdf_with_word(input_path: Path, output_path: Path) -> bool:
    """Windows-only: use Microsoft Word COM automation."""
    if sys.platform != 'win32':
        return False
    try:
        import win32com.client as wc
        word = wc.Dispatch('Word.Application')
        word.Visible = False
        doc = word.Documents.Open(str(input_path))
        doc.SaveAs(str(output_path), FileFormat=17)  # 17 = PDF
        doc.Close()
        word.Quit()
        return output_path.exists()
    except Exception:
        return False


def docx_to_pdf_with_libreoffice(input_path: Path, output_path: Path) -> bool:
    soffice = shutil.which('soffice') or shutil.which('libreoffice')
    if not soffice:
        return False
    out_dir = output_path.parent
    try:
        subprocess.run([
            soffice, '--headless', '--convert-to', 'pdf',
            '--outdir', str(out_dir), str(input_path)
        ], check=True, capture_output=True)
        expected = input_path.with_suffix('.pdf')
        if expected.exists() and expected != output_path:
            shutil.move(str(expected), str(output_path))
        return output_path.exists()
    except Exception:
        return False


def convert_with_pandoc(input_path: Path, output_path: Path, pdf_engine: str = None):
    input_ext = input_path.suffix.lower()
    output_ext = output_path.suffix.lower()
    input_fmt = FORMAT_MAP.get(input_ext)
    output_fmt = FORMAT_MAP.get(output_ext)

    if not input_fmt:
        raise ValueError(f"Unsupported input format: {input_ext}")
    if not output_fmt:
        raise ValueError(f"Unsupported output format: {output_ext}")

    print(f"Converting: {input_path} ({input_fmt}) -> {output_path} ({output_fmt})")

    # DOCX -> PDF
    if input_fmt == 'docx' and output_fmt == 'pdf':
        print("DOCX to PDF conversion...")
        if docx_to_pdf_with_word(input_path, output_path):
            print(f"Conversion successful using Microsoft Word: {output_path}")
            return
        if docx_to_pdf_with_libreoffice(input_path, output_path):
            print(f"Conversion successful using LibreOffice: {output_path}")
            return
        # Fallback: DOCX -> Markdown -> PDF
        print("Converting via Markdown intermediate...")
        with tempfile.NamedTemporaryFile(suffix='.md', delete=False) as tmp:
            tmp_md = Path(tmp.name)
        try:
            subprocess.run(['pandoc', str(input_path), '-o', str(tmp_md), '--wrap=none'],
                           check=True, capture_output=True)
            input_path = tmp_md
            input_fmt = 'markdown'
        except subprocess.CalledProcessError:
            raise RuntimeError("Failed to convert DOCX to intermediate format")
        finally:
            if tmp_md.exists():
                tmp_md.unlink()

    # Markdown/text -> PDF
    if output_fmt == 'pdf' and input_fmt in ('markdown', 'plain', 'rst', 'html'):
        if pdf_engine == 'auto' or not pdf_engine:
            pdf_engine = detect_pdf_engine()

        if not pdf_engine:
            print("Warning: No LaTeX installation found!")
            html_output = output_path.with_suffix('.html')
            subprocess.run(['pandoc', str(input_path), '-o', str(html_output), '--standalone'],
                           check=True, capture_output=True)
            print(f"HTML generated (print to PDF in browser): {html_output}")
            print("To install LaTeX for direct PDF conversion:")
            print("  Windows: https://yihui.org/tinytex/")
            return

        print(f"Using PDF engine: {pdf_engine}")
        cmd = ['pandoc', str(input_path), '-o', str(output_path), f'--pdf-engine={pdf_engine}']
        if pdf_engine == 'xelatex':
            cmd += ['-V', 'mainfont=Times New Roman', '-V', 'CJKmainfont=SimSun', '-V', 'geometry:margin=1in']
        subprocess.run(cmd, check=True)
    else:
        subprocess.run(['pandoc', str(input_path), '-o', str(output_path)], check=True)

    if output_path.exists():
        print(f"Conversion successful: {output_path}")
    else:
        raise RuntimeError("Conversion failed - output file not created")


def main():
    parser = argparse.ArgumentParser(description='Convert documents between formats')
    parser.add_argument('input_file', help='Source file path')
    parser.add_argument('output_file', help='Target file path')
    parser.add_argument('--pdf-engine', default='auto',
                        choices=['auto', 'xelatex', 'pdflatex', 'lualatex'],
                        help='PDF engine for PDF output')
    args = parser.parse_args()

    input_path = Path(args.input_file).resolve()
    output_path = Path(args.output_file).resolve()

    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        convert_with_pandoc(input_path, output_path, args.pdf_engine)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
