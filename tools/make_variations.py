"""Draws dinos from an 8-digit DNA number and renders a variations sheet.
Usage: python3 tools/make_variations.py   (needs playwright + chromium for the PNG)"""
import os, sys, math

COLORS = [("Hot Pink","#ff2fa8"),("Violet","#8e5bff"),("Mint","#2fd6a0"),("Sunny","#ffb22f"),
          ("Sky","#3fa9ff"),("Coral","#ff6a5c"),("Lime","#8fd62f"),("Ice","#4fd0e0")]
EYES = ["Dot","Shiny","Sleepy","Blush"]
SPIKES = ["No spikes","Small spikes","Big spikes","Bumpy back"]
PATTERN = ["Plain","Spots","Stripes","Belly dots"]
ACCESSORY = ["No accessory","Party hat","Bow","Glasses","Crown"]

def decode(dna):
    d = [int(c) for c in dna]
    return dict(color=(d[0]*10+d[1]) % 8, eyes=d[2] % 4, spikes=d[3] % 4, pattern=d[4] % 4, acc=d[5] % 5)

def mix(h, k, to):
    c = [int(h[i:i+2],16) for i in (1,3,5)]
    return "#%02x%02x%02x" % tuple(round(a*(1-k)+b*k) for a,b in zip(c,to))

def dino(dna):
    t = decode(dna); body = COLORS[t["color"]][1]
    dark, light = mix(body,.22,(0,0,0)), mix(body,.55,(255,255,255))
    o = []
    # spikes (behind body)
    if t["spikes"]:
        for ang in (205, 230, 255):
            a = math.radians(ang); bx, by = -2+30*math.cos(a), 12+30*math.sin(a)
            nx, ny = math.cos(a), math.sin(a); px, py = -ny, nx
            if t["spikes"] == 3:
                o.append(f'<circle cx="{bx+nx*3:.1f}" cy="{by+ny*3:.1f}" r="6" fill="{dark}"/>')
            else:
                h = 9 if t["spikes"] == 1 else 15; w = 6 if t["spikes"] == 1 else 8
                o.append(f'<polygon points="{bx+px*w:.1f},{by+py*w:.1f} {bx-px*w:.1f},{by-py*w:.1f} {bx+nx*h:.1f},{by+ny*h:.1f}" fill="{dark}"/>')
    o.append(f'<path d="M-26 8 C-50 20 -64 6 -56 -10 C-50 0 -40 0 -26 -10 Z" fill="{body}"/>')
    o.append(f'<ellipse cx="-2" cy="12" rx="30" ry="30" fill="{body}"/>')
    o.append(f'<ellipse cx="5" cy="18" rx="17" ry="20" fill="{light}"/>')
    o.append(f'<ellipse cx="-14" cy="41" rx="11" ry="7" fill="{dark}"/><ellipse cx="11" cy="41" rx="11" ry="7" fill="{dark}"/>')
    if t["pattern"] == 1:
        o += [f'<circle cx="{x}" cy="{y}" r="{r}" fill="{dark}"/>' for x,y,r in ((-16,-4,3.5),(-22,12,3),(-14,26,3.5))]
    elif t["pattern"] == 2:
        o += [f'<path d="M{x} {y} q-10 8 -4 18" stroke="{dark}" stroke-width="3.5" fill="none" stroke-linecap="round"/>' for x,y in ((-14,-4),(-20,10),(-14,24))]
    elif t["pattern"] == 3:
        o += [f'<circle cx="{x}" cy="{y}" r="2.6" fill="{body}"/>' for x,y in ((0,8),(10,12),(4,20),(12,26),(-2,30))]
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
        o.append(f'<circle cx="25" cy="-19" r="4" fill="#ff7aa8" opacity=".6"/>')
    o.append('<path d="M30 -19 Q38 -13 45 -21" stroke="#111" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
    o.append(f'<circle cx="45" cy="-33" r="1.6" fill="{dark}"/>')
    a = t["acc"]
    if a == 1:
        o.append('<polygon points="10,-40 34,-40 22,-72" fill="#ffd23f"/><circle cx="22" cy="-73" r="4.5" fill="#ff2fa8"/><path d="M14 -48 h16 M17 -57 h10" stroke="#fff" stroke-width="2.5"/>')
    elif a == 2:
        o.append('<polygon points="12,-42 -4,-54 -4,-32" fill="#ffd23f"/><polygon points="12,-42 28,-54 28,-32" fill="#ffd23f" transform="translate(0 0)"/><circle cx="12" cy="-42" r="4.5" fill="#e0a800"/>')
    elif a == 3:
        o.append('<circle cx="31" cy="-30" r="9" fill="none" stroke="#222" stroke-width="2.6"/><path d="M22 -30 L8 -34" stroke="#222" stroke-width="2.6" stroke-linecap="round"/>')
    elif a == 4:
        o.append('<polygon points="10,-41 10,-62 19,-52 27,-64 35,-52 44,-62 44,-41" fill="#ffd23f" stroke="#e0a800" stroke-width="2"/>')
    return "\n".join(o)

SHEET = ["00000000","01211300","02033101","03312405","04122207","05231019","06302142","07120433"]

def sheet():
    W, H, cw, ch, m = 1000, 640, 220, 290, 24
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
             f'<rect width="{W}" height="{H}" rx="28" fill="#ff2fa8"/>']
    for i, dna in enumerate(SHEET):
        x = m + (i%4)*(cw+m/2+ (W-2*m-4*cw-3*m/2)/3 - m/2 + m/2) if False else 24 + (i%4)*(cw+ (W-48-4*cw)/3)
        y = 24 + (i//4)*(ch+ (H-48-2*ch))
        t = decode(dna)
        parts.append(f'<rect x="{x:.0f}" y="{y}" width="{cw}" height="{ch}" rx="16" fill="#fff"/>')
        parts.append(f'<g transform="translate({x+cw/2:.0f} {y+130}) scale(1.45)">{dino(dna)}</g>')
        parts.append(f'<text x="{x+cw/2:.0f}" y="{y+236}" text-anchor="middle" font-family="ui-monospace,Menlo,Consolas,monospace" font-size="17" font-weight="700" fill="#1a1d2e">DNA {dna}</text>')
        parts.append(f'<text x="{x+cw/2:.0f}" y="{y+258}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="12.5" fill="#5b6180">{COLORS[t["color"]][0]} · {EYES[t["eyes"]]} eyes</text>')
        parts.append(f'<text x="{x+cw/2:.0f}" y="{y+275}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="12.5" fill="#5b6180">{SPIKES[t["spikes"]]} · {PATTERN[t["pattern"]]} · {ACCESSORY[t["acc"]]}</text>')
    parts.append("</svg>")
    return "\n".join(parts)

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
    open(os.path.join(out, "dino-variations.svg"), "w").write(sheet())
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b = p.chromium.launch(); pg = b.new_page(viewport={"width":1000,"height":640})
        pg.goto("file://" + os.path.abspath(os.path.join(out, "dino-variations.svg")))
        pg.screenshot(path=os.path.join(out, "dino-variations.png"), omit_background=True); b.close()
    print("ok")
