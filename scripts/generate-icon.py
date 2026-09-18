#!/usr/bin/env python3
"""Generate AxLines app icon assets from the canonical SVG glyph.

Pure-python (no third-party deps). Rasterizes the single-path SVG glyph
(viewBox 0 0 384 512, the "three bars" mark) to:
  - resources/linux/code.png            (1024x1024)
  - resources/win32/code.ico            (256/128/64/48/32/16)
  - resources/win32/code_150x150.png    (150x150)
  - resources/win32/code_70x70.png      (70x70)
  - resources/darwin/code.icns          (multi-size icns)

Usage: python scripts/generate-icon.py
"""

import math
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SVG_VIEW_W = 384
SVG_VIEW_H = 512
FILL_COLOR = (255, 255, 255, 255)  # opaque white

# Canonical SVG path (three subpaths, Font Awesome "bars/list" glyph).
# Each entry is a list of (op, args) tuples.
PATHS = [
    [('M', (190.4, 74.1)),
     ('c', (5.6, -16.8, -3.5, -34.9, -20.2, -40.5)),
     ('s', (-34.9, 3.5, -40.5, 20.2)),
     ('l', (-128.0, 384.0)),
     ('c', (-5.6, 16.8, 3.5, 34.9, 20.2, 40.5)),
     ('s', (34.9, -3.5, 40.5, -20.2)),
     ('l', (128.0, -384.0)),
     ('Z', ())],
    [('m', (70.9, -41.7)),
     ('c', (-17.4, -2.9, -33.9, 8.9, -36.8, 26.3)),
     ('l', (-64.0, 384.0)),
     ('c', (-2.9, 17.4, 8.9, 33.9, 26.3, 36.8)),
     ('s', (33.9, -8.9, 36.8, -26.3)),
     ('l', (64.0, -384.0)),
     ('c', (2.9, -17.4, -8.9, -33.9, -26.3, -36.8)),
     ('Z', ())],
    [('M', (352.0, 32.0)),
     ('c', (-17.7, 0, -32.0, 14.3, -32.0, 32.0)),
     ('v', (384.0,)),
     ('c', (0, 17.7, 14.3, 32.0, 32.0, 32.0)),
     ('s', (32.0, -14.3, 32.0, -32.0)),
     ('v', (-384.0,)),
     ('c', (0, -17.7, -14.3, -32.0, -32.0, -32.0)),
     ('Z', ())],
]


def cubic_bezier(p0, p1, p2, p3, segments=16):
    pts = []
    for i in range(segments + 1):
        t = i / segments
        mt = 1 - t
        x = mt**3 * p0[0] + 3 * mt**2 * t * p1[0] + 3 * mt * t**2 * p2[0] + t**3 * p3[0]
        y = mt**3 * p0[1] + 3 * mt**2 * t * p1[1] + 3 * mt * t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def flatten_paths():
    polys = []
    for cmds in PATHS:
        cur = (0.0, 0.0)
        pts = []
        ctrl = None
        for op, args in cmds:
            if op == 'M':
                cur = (args[0], args[1]); pts = [cur]; ctrl = None
            elif op == 'm':
                cur = (cur[0] + args[0], cur[1] + args[1]); pts = [cur]; ctrl = None
            elif op == 'l':
                cur = (cur[0] + args[0], cur[1] + args[1]); pts.append(cur); ctrl = None
            elif op == 'v':
                cur = (cur[0], cur[1] + args[0]); pts.append(cur); ctrl = None
            elif op == 'c':
                p1 = (cur[0] + args[0], cur[1] + args[1])
                p2 = (cur[0] + args[2], cur[1] + args[3])
                p3 = (cur[0] + args[4], cur[1] + args[5])
                seg = cubic_bezier(cur, p1, p2, p3)
                pts.extend(seg[1:]); cur = p3; ctrl = p2
            elif op == 's':
                if ctrl is None:
                    p1 = cur
                else:
                    p1 = (2 * cur[0] - ctrl[0], 2 * cur[1] - ctrl[1])
                p2 = (cur[0] + args[0], cur[1] + args[1])
                p3 = (cur[0] + args[2], cur[1] + args[3])
                seg = cubic_bezier(cur, p1, p2, p3)
                pts.extend(seg[1:]); cur = p3; ctrl = p2
            elif op == 'Z':
                if len(pts) >= 3:
                    polys.append(pts)
                pts = []
        if len(pts) >= 3:
            polys.append(pts)
    return polys


def point_in_poly(x, y, poly):
    inside = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > y) != (yj > y):
            xint = (xj - xi) * (y - yi) / (yj - yi) + xi
            if x < xint:
                inside = not inside
        j = i
    return inside


def _poly_bounds(poly):
    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    return min(xs), max(xs), min(ys), max(ys)


def render_to_rgba(width, height):
    sx = width / SVG_VIEW_W
    sy = height / SVG_VIEW_H
    polys = [[(x * sx, y * sy) for x, y in poly] for poly in flatten_paths()]
    bounds = [_poly_bounds(p) for p in polys]
    buf = bytearray(width * height * 4)
    # Per-scanline active-list approach: test only pixels inside bounding boxes.
    for py in range(height):
        y = py + 0.5
        row = py * width * 4
        for px in range(width):
            x = px + 0.5
            for poly, bb in zip(polys, bounds):
                xmin, xmax, ymin, ymax = bb
                if x < xmin or x > xmax or y < ymin or y > ymax:
                    continue
                if point_in_poly(x, y, poly):
                    o = row + px * 4
                    buf[o] = FILL_COLOR[0]
                    buf[o + 1] = FILL_COLOR[1]
                    buf[o + 2] = FILL_COLOR[2]
                    buf[o + 3] = FILL_COLOR[3]
                    break
    return buf


def downsample(rgba, w, h, factor):
    nw, nh = w // factor, h // factor
    out = bytearray(nw * nh * 4)
    for py in range(nh):
        for px in range(nw):
            r = g = b = a = 0
            for sy in range(factor):
                for sx in range(factor):
                    o = ((py * factor + sy) * w + px * factor + sx) * 4
                    r += rgba[o]; g += rgba[o + 1]
                    b += rgba[o + 2]; a += rgba[o + 3]
            n = factor * factor
            o = (py * nw + px) * 4
            out[o] = r // n; out[o + 1] = g // n
            out[o + 2] = b // n; out[o + 3] = a // n
    return out


def render_aa(width, height, ss=4):
    big = render_to_rgba(width * ss, height * ss)
    return downsample(big, width * ss, height * ss, ss)


def write_png(path, width, height, rgba):
    def chunk(typ, data):
        return (struct.pack('>I', len(data)) + typ + data
                + struct.pack('>I', zlib.crc32(typ + data) & 0xffffffff))

    raw = bytearray()
    for py in range(height):
        raw.append(0)
        raw += rgba[py * width * 4:(py + 1) * width * 4]
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    data = (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', ihdr)
            + chunk(b'IDAT', zlib.compress(bytes(raw), 9))
            + chunk(b'IEND', b''))
    with open(path, 'wb') as f:
        f.write(data)


def png_bytes(width, height, rgba):
    tmp = os.path.join(ROOT, '.build', '_tmp_icon.png')
    os.makedirs(os.path.dirname(tmp), exist_ok=True)
    write_png(tmp, width, height, rgba)
    with open(tmp, 'rb') as f:
        return f.read()


def write_ico(path, sizes, images):
    count = len(sizes)
    header = struct.pack('<HHH', 0, 1, count)
    entries = b''
    blobs = []
    offset = 6 + 16 * count
    for s in sizes:
        rgba = images[s]
        bgra = bytearray(s * s * 4)
        for py in range(s):
            src_row = py * s * 4
            dst_row = (s - 1 - py) * s * 4
            for px in range(s):
                so = src_row + px * 4
                do = dst_row + px * 4
                bgra[do] = rgba[so + 2]
                bgra[do + 1] = rgba[so + 1]
                bgra[do + 2] = rgba[so]
                bgra[do + 3] = rgba[so + 3]
        xor = bytes(bgra)
        and_stride = ((s + 31) // 32) * 4
        and_mask = b'\x00' * (and_stride * s)
        bih = struct.pack('<IIIHHIIIIII', 40, s, s * 2, 1, 32, 0,
                          len(xor) + len(and_mask), 0, 0, 0, 0)
        entry = struct.pack('<BBBBHHII', s & 0xff, s & 0xff, 0, 0, 1, 32,
                            len(bih) + len(xor) + len(and_mask), offset)
        entries += entry
        blobs.append(bih + xor + and_mask)
        offset += len(bih) + len(xor) + len(and_mask)
    with open(path, 'wb') as f:
        f.write(header + entries + b''.join(blobs))


def write_icns(path, pngs):
    type_map = {16: b'icp4', 32: b'icp5', 64: b'icp6', 128: b'ic07',
                256: b'ic08', 512: b'ic09', 1024: b'ic10'}
    entries = []
    for size in (16, 32, 64, 128, 256, 512, 1024):
        if size in pngs and size in type_map:
            entries.append((type_map[size], pngs[size]))
    total = 8 + sum(8 + len(d) for _, d in entries)
    out = bytearray(struct.pack('>4sI', b'icns', total))
    for typ, d in entries:
        out += struct.pack('>4sI', typ, 8 + len(d)) + d
    with open(path, 'wb') as f:
        f.write(bytes(out))


def main():
    print('Rendering icons...')
    base = render_aa(1024, 1024, ss=4)

    linux_png = os.path.join(ROOT, 'resources', 'linux', 'code.png')
    write_png(linux_png, 1024, 1024, base)
    print(f'  wrote {linux_png} (1024x1024)')

    for size, name in ((150, 'code_150x150.png'), (70, 'code_70x70.png')):
        img = render_aa(size, size, ss=4)
        p = os.path.join(ROOT, 'resources', 'win32', name)
        write_png(p, size, size, img)
        print(f'  wrote {p} ({size}x{size})')

    ico_images = {s: render_aa(s, s, ss=4) for s in (256, 128, 64, 48, 32, 16)}
    ico_path = os.path.join(ROOT, 'resources', 'win32', 'code.ico')
    write_ico(ico_path, [256, 128, 64, 48, 32, 16], ico_images)
    print(f'  wrote {ico_path} (256/128/64/48/32/16)')

    pngs = {}
    for s in (16, 32, 64, 128, 256, 512, 1024):
        pngs[s] = png_bytes(1024, 1024, base) if s == 1024 \
            else png_bytes(s, s, render_aa(s, s, ss=4))
    icns_path = os.path.join(ROOT, 'resources', 'darwin', 'code.icns')
    write_icns(icns_path, pngs)
    print(f'  wrote {icns_path}')
    print('Done.')


if __name__ == '__main__':
    main()