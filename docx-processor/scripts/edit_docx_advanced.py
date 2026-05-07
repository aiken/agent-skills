#!/usr/bin/env python3
"""Advanced text replacement in .docx files with cross-node matching."""
import argparse
import re
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path


def escape_xml(text: str) -> str:
    return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')


def edit_docx_advanced(input_path: Path, output_path: Path, replacements: dict, backup: bool = False):
    if backup and output_path == input_path:
        backup_path = input_path.with_suffix(input_path.suffix + '.backup')
        shutil.copy2(input_path, backup_path)
        print(f"Backup created: {backup_path}")

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        with zipfile.ZipFile(input_path, 'r') as zf:
            zf.extractall(tmpdir_path)

        doc_xml = tmpdir_path / 'word' / 'document.xml'
        if not doc_xml.exists():
            raise ValueError("Invalid .docx file: document.xml not found")

        content = doc_xml.read_text(encoding='utf-8')

        for old, new in replacements.items():
            new_escaped = escape_xml(new)
            content = content.replace(old, new_escaped)

        for old, new in replacements.items():
            if new == "" or not old:
                continue
            chars = [re.escape(c) for c in old]
            pattern = '[^<]*(?:<[^>]+>[^<]*)?'.join(chars)
            new_escaped = escape_xml(new)
            content = re.sub(pattern, new_escaped, content)

        doc_xml.write_text(content, encoding='utf-8')

        if output_path.exists():
            output_path.unlink()
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
            for file_path in tmpdir_path.rglob('*'):
                if file_path.is_file():
                    arcname = str(file_path.relative_to(tmpdir_path)).replace('\\', '/')
                    zf.write(file_path, arcname)

    print(f"Document saved: {output_path}")


def parse_replacements(pairs: list) -> dict:
    result = {}
    for pair in pairs:
        if '=' not in pair:
            raise ValueError(f"Invalid replacement format (expected KEY=VALUE): {pair}")
        key, value = pair.split('=', 1)
        result[key] = value
    return result


def main():
    parser = argparse.ArgumentParser(description='Advanced edit text in a .docx file')
    parser.add_argument('input_file', help='Path to the .docx file')
    parser.add_argument('-o', '--output', help='Output file (default: overwrite input)')
    parser.add_argument('-r', '--replace', action='append', required=True,
                        help='Replacement in KEY=VALUE format (can be used multiple times)')
    parser.add_argument('-b', '--backup', action='store_true', help='Create a backup before editing')
    args = parser.parse_args()

    input_path = Path(args.input_file).resolve()
    if not input_path.exists():
        print(f"Error: File not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output).resolve() if args.output else input_path

    try:
        replacements = parse_replacements(args.replace)
        edit_docx_advanced(input_path, output_path, replacements, backup=args.backup)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
