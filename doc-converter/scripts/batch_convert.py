#!/usr/bin/env python3
"""Batch convert multiple documents."""
import argparse
import subprocess
import sys
from pathlib import Path

EXT_MAP = {
    'pdf': '.pdf',
    'html': '.html',
    'docx': '.docx',
    'md': '.md',
    'markdown': '.md',
}


def main():
    parser = argparse.ArgumentParser(description='Batch convert multiple documents')
    parser.add_argument('input_files', nargs='+', help='Input files')
    parser.add_argument('-f', '--format', required=True, choices=['pdf', 'html', 'docx', 'md', 'markdown'],
                        help='Target format')
    parser.add_argument('-o', '--output-dir', help='Output directory')
    parser.add_argument('--pdf-engine', default='auto',
                        choices=['auto', 'xelatex', 'pdflatex', 'lualatex'])
    args = parser.parse_args()

    script_dir = Path(__file__).parent.resolve()
    convert_script = script_dir / 'convert.py'

    out_ext = EXT_MAP[args.format]
    out_dir = Path(args.output_dir).resolve() if args.output_dir else None
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)

    success = failed = skipped = 0
    print("=" * 40)
    print(f"  Batch Conversion")
    print(f"  Format: {args.format}")
    print(f"  Files: {len(args.input_files)}")
    print("=" * 40)
    print()

    for input_file in args.input_files:
        in_path = Path(input_file).resolve()
        if not in_path.exists():
            print(f"⚠️  Skipping (not found): {in_path}")
            skipped += 1
            continue

        if out_dir:
            out_path = out_dir / (in_path.stem + out_ext)
        else:
            out_path = in_path.with_suffix(out_ext)

        if out_path.exists():
            if out_path.stat().st_mtime > in_path.stat().st_mtime:
                print(f"⏭️  Skipping (up to date): {in_path.name}")
                skipped += 1
                continue

        print(f"Converting: {in_path.name} -> {out_path.name}")
        try:
            cmd = [sys.executable, str(convert_script), str(in_path), str(out_path),
                   '--pdf-engine', args.pdf_engine]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0 and out_path.exists():
                success += 1
            else:
                print(f"❌ Failed: {result.stderr}")
                failed += 1
        except Exception as e:
            print(f"❌ Failed: {e}")
            failed += 1
        print()

    print("=" * 40)
    print("  Conversion Complete")
    print("=" * 40)
    print(f"✓ Success: {success}")
    if failed:
        print(f"✗ Failed: {failed}")
    if skipped:
        print(f"⏭️  Skipped: {skipped}")


if __name__ == '__main__':
    main()
