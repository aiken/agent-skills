#!/usr/bin/env python3
"""Convert images to a single PDF file."""
import argparse
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Convert images to a single PDF')
    parser.add_argument('input_files', nargs='+', help='Image files (in order)')
    parser.add_argument('-o', '--output', required=True, help='Output PDF path')
    parser.add_argument('-q', '--quality', type=int, default=85, help='JPEG quality 1-100 (default: 85)')
    args = parser.parse_args()

    try:
        from PIL import Image
    except ImportError:
        print("Error: Pillow is required. Install with: pip install Pillow", file=sys.stderr)
        sys.exit(1)

    images = []
    for f in args.input_files:
        img_path = Path(f).resolve()
        if not img_path.exists():
            print(f"Error: File not found: {img_path}", file=sys.stderr)
            sys.exit(1)
        img = Image.open(img_path)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        images.append(img)

    if not images:
        print("Error: No image files provided", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    images[0].save(
        output_path,
        save_all=True,
        append_images=images[1:],
        resolution=100.0,
        quality=args.quality
    )
    print(f"PDF created: {output_path}")


if __name__ == '__main__':
    main()
