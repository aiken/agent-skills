#!/usr/bin/env python3
"""Check document conversion dependencies."""
import shutil
import subprocess
import sys


def check_tool(name: str, args=None):
    exe = shutil.which(name)
    if not exe:
        return None
    try:
        result = subprocess.run([exe] + (args or ['--version']), capture_output=True, text=True)
        first_line = result.stdout.strip().split('\n')[0] if result.stdout else 'available'
        return first_line
    except Exception:
        return 'available'


def main():
    print("=" * 40)
    print("  Document Converter Dependencies")
    print("=" * 40)
    print()

    pandoc = check_tool('pandoc')
    if pandoc:
        print(f"✓ Pandoc: {pandoc}")
    else:
        print("✗ Pandoc: Not found")
        print("  Install from: https://pandoc.org/installing.html")

    print()
    print("PDF Engines:")
    for engine, label in [('xelatex', 'XeLaTeX (recommended for Chinese)'),
                          ('pdflatex', 'pdflatex (limited Unicode)'),
                          ('lualatex', 'LuaLaTeX')]:
        version = check_tool(engine)
        if version:
            print(f"✓ {label}: available")
        else:
            print(f"✗ {label}: Not found")

    print()
    print("Office Suites:")
    libre = check_tool('soffice') or check_tool('libreoffice')
    if libre:
        print("✓ LibreOffice: available (for DOCX->PDF)")
    else:
        print("✗ LibreOffice: Not found")

    if sys.platform == 'win32':
        try:
            import win32com.client as wc
            word = wc.Dispatch('Word.Application')
            word.Quit()
            print("✓ Microsoft Word COM: available (best for DOCX->PDF)")
        except Exception:
            print("✗ Microsoft Word COM: Not available")
    else:
        print("  Microsoft Word COM: N/A (Windows only)")

    print()
    print("=" * 40)
    print()
    print("Recommendations:")
    if not pandoc:
        print("  ❌ Pandoc is REQUIRED. Please install it first.")
    elif not check_tool('xelatex') and not check_tool('pdflatex'):
        print("  ⚠️  No LaTeX found. PDF generation will use fallback methods.")
        print("     For best results, install TinyTeX: https://yihui.org/tinytex/")
    elif not check_tool('xelatex') and check_tool('pdflatex'):
        print("  ⚠️  pdflatex found but XeLaTeX is recommended for Chinese documents.")
    else:
        print("  ✅ All recommended tools are available!")
    print()


if __name__ == '__main__':
    main()
