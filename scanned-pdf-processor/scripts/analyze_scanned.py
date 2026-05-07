#!/usr/bin/env python3
"""Comprehensive analysis of scanned documents."""
import argparse
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Analyze scanned PDF documents')
    parser.add_argument('input_file', help='Path to the scanned PDF')
    parser.add_argument('-m', '--mode', choices=['visual', 'text', 'full', 'structure'], default='full',
                        help='Analysis mode')
    parser.add_argument('-o', '--output-dir', default='./scanned_analysis', help='Output directory')
    args = parser.parse_args()

    pdf_path = Path(args.input_file).resolve()
    if not pdf_path.exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    script_dir = Path(__file__).parent.resolve()
    analysis_dir = Path(args.output_dir).resolve() / pdf_path.stem
    analysis_dir.mkdir(parents=True, exist_ok=True)

    print(f"Analyzing scanned PDF...")
    print(f"Mode: {args.mode}")
    print(f"Output: {analysis_dir}")

    if args.mode == 'visual':
        print("\n[1/1] Converting to images...")
        subprocess.run([
            sys.executable, str(script_dir / 'pdf_to_images.py'),
            str(pdf_path), '-o', str(analysis_dir / 'images'), '-d', '300'
        ], check=False)

    elif args.mode == 'text':
        print("\n[1/1] Extracting text with OCR...")
        subprocess.run([
            sys.executable, str(script_dir / 'ocr_extract.py'),
            str(pdf_path), '-o', str(analysis_dir / 'extracted_text.txt'), '-l', 'chi_sim+eng'
        ], check=False)

    elif args.mode == 'full':
        print("\n[1/3] Converting to images...")
        subprocess.run([
            sys.executable, str(script_dir / 'pdf_to_images.py'),
            str(pdf_path), '-o', str(analysis_dir / 'images'), '-d', '300'
        ], check=False)

        print("\n[2/3] Extracting text with OCR...")
        subprocess.run([
            sys.executable, str(script_dir / 'ocr_extract.py'),
            str(pdf_path), '-o', str(analysis_dir / 'extracted_text.txt'), '-l', 'chi_sim+eng'
        ], check=False)

        print("\n[3/3] Generating analysis report...")
        report = f"""# Scanned Document Analysis Report

## File Information
- **Filename**: {pdf_path.stem}
- **Analysis Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **Mode**: Full Analysis

## Output Files
- **Images**: {analysis_dir / 'images'}
- **Extracted Text**: {analysis_dir / 'extracted_text.txt'}

## Notes
- Images are rendered at 300 DPI for optimal OCR accuracy
- OCR uses Chinese (Simplified) + English language model
- Review extracted text for accuracy, especially for:
  - Handwritten content
  - Low-quality scans
  - Complex layouts (tables, forms)

## Next Steps
1. Review images in the 'images' folder
2. Check extracted_text.txt for OCR results
3. Manually verify critical information
"""
        (analysis_dir / 'README.md').write_text(report, encoding='utf-8')

    elif args.mode == 'structure':
        print("\n[1/2] Converting to images for structure analysis...")
        subprocess.run([
            sys.executable, str(script_dir / 'pdf_to_images.py'),
            str(pdf_path), '-o', str(analysis_dir / 'images'), '-d', '200'
        ], check=False)
        print("\n[2/2] Analyzing document structure...")
        print("Structure analysis complete. Images available for manual review.")

    print(f"\n{'='*40}")
    print("Analysis Complete!")
    print(f"Results saved to: {analysis_dir}")
    print(f"{'='*40}")

    # Show directory contents
    for item in sorted(analysis_dir.rglob('*')):
        rel = item.relative_to(analysis_dir)
        indent = "  " * len(rel.parts)
        if item.is_dir():
            print(f"{indent}[{item.name}]")
        else:
            size = item.stat().st_size
            size_str = f"{size/1024/1024:.1f} MB" if size > 1024*1024 else f"{size/1024:.1f} KB"
            print(f"{indent}{item.name} ({size_str})")


if __name__ == '__main__':
    main()
