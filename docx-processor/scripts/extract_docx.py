#!/usr/bin/env python3
"""Extract structured content from a .docx file with paragraph indexing."""
import argparse
import json
import sys
import tempfile
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


def extract_structured(docx_path: Path):
    with tempfile.TemporaryDirectory() as tmpdir:
        with zipfile.ZipFile(docx_path, 'r') as zf:
            zf.extractall(tmpdir)
        doc_xml = Path(tmpdir) / 'word' / 'document.xml'
        if not doc_xml.exists():
            raise ValueError("Invalid .docx file: document.xml not found")

        tree = ET.parse(doc_xml)
        root = tree.getroot()
        items = []
        idx = 0
        ns = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
        for p in root.iter(f'{ns}p'):
            texts = []
            for t in p.iter(f'{ns}t'):
                if t.text:
                    texts.append(t.text)
            para_text = ''.join(texts)
            if para_text:
                idx += 1
                items.append({'index': idx, 'text': para_text})
        return items


def main():
    parser = argparse.ArgumentParser(description='Extract structured content from a .docx file')
    parser.add_argument('input_file', help='Path to the .docx file')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    parser.add_argument('-f', '--format', choices=['text', 'list', 'json'], default='list',
                        help='Output format (default: list)')
    args = parser.parse_args()

    docx_path = Path(args.input_file).resolve()
    if not docx_path.exists():
        print(f"Error: File not found: {docx_path}", file=sys.stderr)
        sys.exit(1)

    try:
        items = extract_structured(docx_path)
        fmt = args.format.lower()
        if fmt == 'json':
            output = json.dumps(items, ensure_ascii=False, indent=2)
        elif fmt == 'list':
            lines = [f"{item['index']}: {item['text']}" for item in items]
            output = '\n'.join(lines)
        else:
            lines = [item['text'] for item in items]
            output = '\n'.join(lines)

        if args.output:
            out_path = Path(args.output)
            out_path.write_text(output, encoding='utf-8')
            print(f"Content extracted to: {out_path}")
        else:
            print(output)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
