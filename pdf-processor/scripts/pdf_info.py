#!/usr/bin/env python3
"""Display information about a PDF file."""
import argparse
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Show PDF metadata and info')
    parser.add_argument('input_file', help='Path to the PDF file')
    args = parser.parse_args()

    pdf_path = Path(args.input_file).resolve()
    if not pdf_path.exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    try:
        from PyPDF2 import PdfReader
    except ImportError:
        print("Error: PyPDF2 is required. Install with: pip install PyPDF2", file=sys.stderr)
        sys.exit(1)

    reader = PdfReader(str(pdf_path))
    info = reader.metadata

    print(f"文件: {pdf_path}")
    print(f"页数: {len(reader.pages)}")
    print("")

    if info:
        print("PDF 元数据:")
        if info.title:
            print(f"  标题: {info.title}")
        if info.author:
            print(f"  作者: {info.author}")
        if info.subject:
            print(f"  主题: {info.subject}")
        if info.creator:
            print(f"  创建者: {info.creator}")
        if info.producer:
            print(f"  生成器: {info.producer}")
        if info.creation_date:
            print(f"  创建日期: {info.creation_date}")
        if info.modification_date:
            print(f"  修改日期: {info.modification_date}")
    else:
        print("无元数据")

    if reader.is_encrypted:
        print("\n状态: 已加密")
    else:
        print("\n状态: 未加密")

    if len(reader.pages) > 0:
        try:
            first_text = reader.pages[0].extract_text()
            if first_text:
                preview = first_text[:200].replace('\n', ' ')
                print(f"\n第一页预览:\n{preview}...")
        except Exception:
            pass


if __name__ == '__main__':
    main()
