#!/usr/bin/env python3
"""Report hardcoded user-facing strings that should live in ARB files.

Supports the localization sweep described in
docs/superpowers/specs/2026-08-12-feature-localization-sweep.md. A slice is
"done" when this script reports zero rows for its area.

Usage:
    python3 scripts/audit_hardcoded_strings.py                # whole lib/
    python3 scripts/audit_hardcoded_strings.py lib/features/pos
    python3 scripts/audit_hardcoded_strings.py --indonesian    # mixed-language only

Exits 1 when rows are found, so it can gate a slice locally.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from collections import Counter

# Constructors and named parameters that render user-visible text.
# Named parameters whose value is rendered to the user.
_TEXT_PARAMS = (
    r"title|subtitle|label|labelText|hintText|helperText|tooltip"
    r"|message|content|errorText|semanticLabel|counterText|prefixText"
    r"|suffixText"
)

# A literal may not sit immediately after the opening delimiter: a conditional
# can precede it, as in `Text(isEdit ? 'Edit' : 'Add')`. Allowing an optional
# expression prefix is what catches those; requiring it to end in `?` or `:`
# keeps the match anchored to a rendered value rather than any nearby string.
_MAYBE_CONDITION = r"(?:[^'\"()]*?[?:]\s*)?"

PATTERNS = [
    re.compile(r"Text\(\s*" + _MAYBE_CONDITION + r"'([^']{2,})'"),
    re.compile(r'Text\(\s*' + _MAYBE_CONDITION + r'"([^"]{2,})"'),
    re.compile(
        r"(?:" + _TEXT_PARAMS + r")\s*:\s*" + _MAYBE_CONDITION + r"'([^']{2,})'"
    ),
    re.compile(
        r"(?:" + _TEXT_PARAMS + r")\s*:\s*" + _MAYBE_CONDITION + r'"([^"]{2,})"'
    ),
]

# Words that mark a literal as Indonesian. Such strings render as Indonesian
# even when the app is in English, which is the highest-severity case.
INDONESIAN_MARKERS = (
    'Apotek', 'Obat', 'Simpan', 'Hapus', 'Tambah', 'Batal', 'Struk',
    'Identitas', 'Jumlah', 'Harga', 'Stok', 'Kasir', 'Produk', 'Pemasok',
    'Resep', 'Laporan', 'Pengguna', 'Peringatan', 'Nama', 'Tanggal', 'Total',
    'Bebas', 'Keras', 'Terbatas', 'Hijau', 'Biru', 'Merah', 'Perlu', 'Dokter',
    'Wajib', 'Gagal', 'Berhasil', 'Yakin', 'Kembali', 'Cari', 'Pilih',
    'Semua', 'Belum', 'Modal', 'Prive', 'Awal', 'Akhir', 'Arus',
)


def is_technical(value: str) -> bool:
    """True for values that are not user-facing copy."""
    if re.fullmatch(r"[a-z0-9_./:-]+", value):
        return True  # keys, routes, codes
    if value.startswith('assets/') or value.endswith(('.png', '.csv', '.json')):
        return True
    if re.fullmatch(r"[yMdHms:/\-. ]+", value):
        return True  # date/number format patterns
    if re.fullmatch(r"[#*=\-_ ]+", value):
        return True  # separators
    return False


def scan(root: str):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != 'l10n']
        for filename in sorted(filenames):
            if not filename.endswith('.dart') or filename.endswith('.g.dart'):
                continue
            path = os.path.join(dirpath, filename)
            with open(path, encoding='utf-8') as handle:
                for number, line in enumerate(handle, 1):
                    if 'l10n.' in line:
                        continue
                    for pattern in PATTERNS:
                        for match in pattern.finditer(line):
                            text = match.group(1)
                            if is_technical(text) or '$' in text:
                                continue
                            yield path, number, text


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('path', nargs='?', default='lib')
    parser.add_argument(
        '--indonesian',
        action='store_true',
        help='only report literals that look Indonesian',
    )
    args = parser.parse_args()

    if not os.path.exists(args.path):
        print(f'no such path: {args.path}', file=sys.stderr)
        return 2

    rows = list(scan(args.path))
    if args.indonesian:
        rows = [r for r in rows if any(w in r[2] for w in INDONESIAN_MARKERS)]

    for path, number, text in rows:
        print(f'{path}:{number}  {text}')

    if rows:
        print()
        areas = Counter(
            '/'.join(p.split('/')[:3]) if p.count('/') > 1 else p
            for p, _, _ in rows
        )
        for area, count in areas.most_common():
            print(f'{count:5}  {area}')
        print(f'\n{len(rows)} hardcoded user-facing string(s) found')
        return 1

    print(f'no hardcoded user-facing strings in {args.path}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
