"""Reference (off-chain) renderer for MazeDino. The Solidity renderer must produce byte-identical SVG.
  python3 tools/dino_ref.py consts      -> prints the constants pasted into DinoRenderer.sol
  python3 tools/dino_ref.py refs        -> writes test/ref/<dna>.svg for the Foundry test
"""
import math, os, sys

COLORS = [("Hot Pink","#ff2fa8"),("Violet","#8e5bff"),("Mint","#2fd6a0"),("Sunny","#ffb22f"),
          ("Sky","#3fa9ff"),("Coral","#ff6a5c"),("Lime","#8fd62f"),("Ice","#4fd0e0")]

def mix(h, k, to):
    c = [int(h[i:i+2], 16) for i in (1, 3, 5)]
    return "#%02x%02x%02x" % tuple(round(a*(1-k)+b*k) for a, b in zip(c, to))

DARK  = [mix(c, .22, (0, 0, 0)) for _, c in COLORS]
LIGHT = [mix(c, .55, (255, 255, 255)) for _, c in COLORS]
BODY  = [c for _, c in COLORS]

def spike_consts():
    pts = {1: [], 2: []}; bump = []
    for ang in (205, 230, 255):
        a = math.radians(ang); bx, by = -2 + 30*math.cos(a), 12 + 30*math.sin(a)
        nx, ny = math.cos(a), math.sin(a); px, py = -ny, nx
        bump.append(f'cx="{bx+nx*3:.1f}" cy="{by+ny*3:.1f}"')
        for style, (h, w) in ((1, (9, 6)), (2, (15, 8))):
            pts[style].append(f"{bx+px*w:.1f},{by+py*w:.1f} {bx-px*w:.1f},{by-py*w:.1f} {bx+nx*h:.1f},{by+ny*h:.1f}")
    return pts, bump
SP, BUMP = spike_consts()

def decode(dna):
    d = [int(c) for c in f"{dna:08d}"]
    return dict(color=(d[0]*10+d[1]) % 8, eyes=d[2] % 4, spikes=d[3] % 4, pattern=d[4] % 4, acc=d[5] % 5)

def dino(dna):
    t = decode(dna); body, dark, light = BODY[t["color"]], DARK[t["color"]], LIGHT[t["color"]]
    o = []
    if t["spikes"] == 3:
        o += [f'<circle {b} r="6" fill="{dark}"/>' for b in BUMP]
    elif t["spikes"]:
        o += [f'<polygon points="{p}" fill="{dark}"/>' for p in SP[t["spikes"]]]
    o.append(f'<path d="M-26 8 C-50 20 -64 6 -56 -10 C-50 0 -40 0 -26 -10 Z" fill="{body}"/>')
    o.append(f'<ellipse cx="-2" cy="12" rx="30" ry="30" fill="{body}"/>')
    o.append(f'<ellipse cx="5" cy="18" rx="17" ry="20" fill="{light}"/>')
    o.append(f'<ellipse cx="-14" cy="41" rx="11" ry="7" fill="{dark}"/><ellipse cx="11" cy="41" rx="11" ry="7" fill="{dark}"/>')
    if t["pattern"] == 1:
        o += [f'<circle cx="{x}" cy="{y}" r="{r}" fill="{dark}"/>' for x, y, r in ((-16, -4, "3.5"), (-22, 12, "3"), (-14, 26, "3.5"))]
    elif t["pattern"] == 2:
        o += [f'<path d="M{x} {y} q-10 8 -4 18" stroke="{dark}" stroke-width="3.5" fill="none" stroke-linecap="round"/>' for x, y in ((-14, -4), (-20, 10), (-14, 24))]
    elif t["pattern"] == 3:
        o += [f'<circle cx="{x}" cy="{y}" r="2.6" fill="{body}"/>' for x, y in ((0, 8), (10, 12), (4, 20), (12, 26), (-2, 30))]
    o.append(f'<rect x="-8" y="-42" width="58" height="38" rx="19" fill="{body}"/>')
    o.append(f'<path d="M17 4 q9 1 10 9 M17 4 q-1 8 7 11" stroke="{dark}" stroke-width="3" fill="none" stroke-linecap="round"/>')
    e = t["eyes"]
    if e == 2:
        o.append('<path d="M26 -30 q5 4 10 0" stroke="#111" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
    elif e == 1:
        o.append('<circle cx="31" cy="-30" r="5.2" fill="#111"/><circle cx="33" cy="-32" r="1.8" fill="#fff"/><circle cx="29.5" cy="-28" r="1" fill="#fff"/>')
    else:
        o.append('<circle cx="31" cy="-30" r="3.4" fill="#111"/><circle cx="32" cy="-31" r="1" fill="#fff"/>')
    if e == 3:
        o.append('<circle cx="25" cy="-19" r="4" fill="#ff7aa8" opacity=".6"/>')
    o.append('<path d="M30 -19 Q38 -13 45 -21" stroke="#111" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
    o.append(f'<circle cx="45" cy="-33" r="1.6" fill="{dark}"/>')
    a = t["acc"]
    if a == 1:
        o.append('<polygon points="10,-40 34,-40 22,-72" fill="#ffd23f"/><circle cx="22" cy="-73" r="4.5" fill="#ff2fa8"/><path d="M14 -48 h16 M17 -57 h10" stroke="#fff" stroke-width="2.5"/>')
    elif a == 2:
        o.append('<polygon points="12,-42 -4,-54 -4,-32" fill="#ffd23f"/><polygon points="12,-42 28,-54 28,-32" fill="#ffd23f"/><circle cx="12" cy="-42" r="4.5" fill="#e0a800"/>')
    elif a == 3:
        o.append('<circle cx="31" cy="-30" r="9" fill="none" stroke="#222" stroke-width="2.6"/><path d="M22 -30 L8 -34" stroke="#222" stroke-width="2.6" stroke-linecap="round"/>')
    elif a == 4:
        o.append('<polygon points="10,-41 10,-62 19,-52 27,-64 35,-52 44,-62 44,-41" fill="#ffd23f" stroke="#e0a800" stroke-width="2"/>')
    return "".join(o)

def full_svg(dna):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-100 -100 200 200">'
            '<rect x="-100" y="-100" width="200" height="200" fill="#fff0f8"/>'
            f'<g transform="translate(6 14)">{dino(dna)}</g></svg>')

SAMPLES = [0, 1211300, 2033101, 3312405, 4122207, 5231019, 6302142, 7120433, 99999999,
           12345678, 87654321, 31415926, 27182818, 10203040, 40302010, 55555555, 11111111,
           22222222, 33333333, 44444444, 66666666, 77777777, 88888888, 19283746, 70011996, 3000000]

if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    if sys.argv[1] == "consts":
        print("BODY ", "".join(BODY)); print("DARK ", "".join(DARK)); print("LIGHT", "".join(LIGHT))
        print("SP1", SP[1]); print("SP2", SP[2]); print("BUMP", BUMP)
    else:
        out = os.path.join(here, "..", "test", "ref"); os.makedirs(out, exist_ok=True)
        for dna in SAMPLES:
            open(os.path.join(out, f"{dna:08d}.svg"), "w").write(full_svg(dna))
        print(len(SAMPLES), "refs written")
