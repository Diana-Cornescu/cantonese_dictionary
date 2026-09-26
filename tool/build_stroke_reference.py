"""Builds assets/stroke_reference.bin from Make Me a Hanzi's graphics.txt.

Dev-only; never shipped. Needs Python 3 and nothing else. Run from the
project folder:

    python tool/build_stroke_reference.py path/to/makemeahanzi/graphics.txt

graphics.txt comes from https://github.com/skishore/makemeahanzi (Arphic
Public License; its text is in assets/licenses/arphic_public_license.txt).
Only graphics.txt is used, not dictionary.txt (a separate file under the
LGPL).

Written in Python rather than Dart because it was generated in a workspace
without the Dart SDK, and this script is the one that was actually run to
make the committed file. lib/data/stroke_reference.dart reads the output;
test/stroke_reference_test.dart checks the two agree on real glyphs.

File layout (little-endian), format version 1:

    [4 bytes  magic "SREF"]
    [uint8    version = 1]
    [uint32   glyphCount]
    index, glyphCount entries sorted by code point:
      [uint32 codePoint] [uint32 offset]    # offset from start of file
    per glyph, at its offset:
      [uint8 strokeCount]
      per stroke:
        [uint16 commandCount]
        per command:
          [uint8 op]  one of the ASCII letters M L Q C Z
          [int16 x, int16 y] * (M/L: 1, Q: 2, C: 3, Z: 0)

Coordinates are Make Me a Hanzi's own: a 1024 x 1024 grid whose top edge is
y = 900 and bottom edge y = -124 (y grows upwards). A few of the ~200,000
paths have fractional coordinates; they're rounded to whole units, which is
a tenth of a pixel in a 100-pixel box.
"""

import json
import re
import struct
import sys

POINTS_PER_OP = {'M': 1, 'L': 1, 'Q': 2, 'C': 3, 'Z': 0}
TOKEN = re.compile(r'[A-Za-z]|-?\d+(?:\.\d+)?')


def pack_stroke(path):
    tokens = TOKEN.findall(path)
    body = bytearray()
    count = 0
    i = 0
    while i < len(tokens):
        op = tokens[i]
        i += 1
        if op not in POINTS_PER_OP:
            raise ValueError(f'unsupported path command {op!r} in {path!r}')
        numbers = tokens[i:i + 2 * POINTS_PER_OP[op]]
        if len(numbers) != 2 * POINTS_PER_OP[op] or any(
                t.isalpha() for t in numbers):
            raise ValueError(f'malformed {op} command in {path!r}')
        i += len(numbers)
        body += op.encode('ascii')
        for n in numbers:
            body += struct.pack('<h', round(float(n)))
        count += 1
    return struct.pack('<H', count) + bytes(body)


def pack_glyph(strokes):
    if len(strokes) > 255:
        raise ValueError('more than 255 strokes')
    return bytes([len(strokes)]) + b''.join(pack_stroke(s) for s in strokes)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    glyphs = {}
    with open(sys.argv[1], encoding='utf-8') as f:
        for line in f:
            entry = json.loads(line)
            character = entry['character']
            if len(character) != 1:
                raise ValueError(f'not a single code point: {character!r}')
            glyphs[ord(character)] = pack_glyph(entry['strokes'])

    code_points = sorted(glyphs)
    header_size = 4 + 1 + 4 + 8 * len(code_points)
    out = bytearray(b'SREF') + struct.pack('<BI', 1, len(code_points))
    offset = header_size
    for cp in code_points:
        out += struct.pack('<II', cp, offset)
        offset += len(glyphs[cp])
    for cp in code_points:
        out += glyphs[cp]

    with open('assets/stroke_reference.bin', 'wb') as f:
        f.write(out)
    print(f'{len(code_points)} glyphs, {len(out) / 1e6:.1f} MB '
          f'-> assets/stroke_reference.bin')


if __name__ == '__main__':
    main()
