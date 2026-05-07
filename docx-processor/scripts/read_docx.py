#!/usr/bin/env python3
"""Extract plain text from a .docx file."""
import argparse
import sys
import tempfile
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


def extract_text(docx_path: Path) -> str:
    with tempfile.TemporaryDirectory() as tmpdir:
        with zipfile.ZipFile(docx_path, 'r') as zf:
            zf.extractall(tmpdir)
        doc_xml = Path(tmpdir) / 'word' / 'document.xml'
        if not doc_xml.exists():
            raise ValueError("Invalid .docx file: document.xml not found")

        tree = ET.parse(doc_xml)
        root = tree.getroot()
        paragraphs = []
        ns = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
        for p in root.iter(f'{ns}p'):
            texts = []
            for t in p.iter(f'{ns}t'):
                if t.text:
                    texts.append(t.text)
            para_text = ''.join(texts)
            if para_text:
                paragraphs.append(para_text)
        return '\n'.join(paragraphs)


def main():
    parser = argparse.ArgumentParser(description='Extract text from a .docx file')
    parser.add_argument('input_file', help='Path to the .docx file')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    args = parser.parse_args()

    docx_path = Path(args.input_file).resolve()
    if not docx_path.exists():
        print(f"Error: File not found: {docx_path}", file=sys.stderr)
        sys.exit(1)

    try:
        text = extract_text(docx_path)
        if args.output:
            out_path = Path(args.output)
            out_path.write_text(text, encoding='utf-8')
            print(f"Text extracted to: {out_path}")
        else:
            print(text)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
