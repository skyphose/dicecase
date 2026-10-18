#!/usr/bin/env python3
"""Light each face of a die STL the way a lamp would, with cast shadows, so a
ONE-COLOUR design can be judged for readability. OpenSCAD's preview has no
shadows: a symbol top and the floor around it face the same way and shade the
same, which hides exactly the thing a single-colour relief relies on.

Ray-casts a height map of each face off the mesh, then shades it with a light
coming in low across the face, marching shadows through the height map.

  python3 tools/lamp.py die.stl out.png [label]
The die must be the 24 mm cube sitting on z = 0, centred on x = y = 0.
"""
import sys, numpy as np, trimesh
from PIL import Image, ImageDraw

path, out = sys.argv[1], sys.argv[2]
label = sys.argv[3] if len(sys.argv) > 3 else ""
m = trimesh.load(path)
S, C, N = 24.0, np.array([0, 0, 12.0]), 240      # die size, centre, pixels/face
res = S / N

# face: outward normal, the face's "right" and "up" as seen from outside
faces = {
    "top (1)":  ([0,0,1],  [1,0,0], [0,1,0]),
    "+x (2)":   ([1,0,0],  [0,1,0], [0,0,1]),
    "+y (3)":   ([0,1,0],  [-1,0,0],[0,0,1]),
    "-y (4)":   ([0,-1,0], [1,0,0], [0,0,1]),
    "-x (5)":   ([-1,0,0], [0,-1,0],[0,0,1]),
    "bed (6)":  ([0,0,-1], [1,0,0], [0,-1,0]),
}
inter = trimesh.ray.ray_triangle.RayMeshIntersector(m)
tiles = []
for name, (n, r, u) in faces.items():
    n, r, u = map(np.array, (n, r, u))
    g = (np.arange(N) + 0.5) * res - S/2
    uu, rr = np.meshgrid(-g, g, indexing="ij")              # row 0 = top of face
    origins = C + n * (S/2 + 2) + rr[..., None] * r + uu[..., None] * u
    origins = origins.reshape(-1, 3)
    dirs = np.tile(-n, (len(origins), 1)).astype(float)
    loc, idx, _ = inter.intersects_location(origins, dirs, multiple_hits=False)
    h = np.full(len(origins), -3.0)
    h[idx] = (loc - C) @ n - S/2                            # 0 = face plane, negative = sunk
    h = h.reshape(N, N)
    # light from the upper left, low: 25 deg above the face
    elev = np.radians(float(__import__("os").environ.get("LAMP_ELEV", 25))); ldir = np.array([float(x) for x in __import__("os").environ.get("LAMP_DIR", "-1,1").split(",")]); ldir = ldir / np.linalg.norm(ldir)  # (col, row-up)
    gy, gx = np.gradient(h, res)                            # rows go down the face
    nx, ny, nz = -gx, gy, np.ones_like(h)
    nrm = np.sqrt(nx**2 + ny**2 + nz**2)
    L = np.array([ldir[0]*np.cos(elev), ldir[1]*np.cos(elev), np.sin(elev)])
    shade = np.clip((nx*L[0] + ny*L[1] + nz*L[2]) / nrm, 0, 1)
    # cast shadows: march toward the light; blocked if the terrain rises above the ray
    lit = np.ones_like(h, bool)
    tanE = np.tan(elev)
    for k in range(1, 40):
        d = k * res
        dc, dr = ldir[0] * k, -ldir[1] * k                  # columns right, rows up
        rs = np.clip((np.arange(N)[:, None] + dr).round().astype(int), 0, N-1)
        cs = np.clip((np.arange(N)[None, :] + dc).round().astype(int), 0, N-1)
        lit &= ~(h[rs, cs] > h + d * tanE + 1e-3)
    img = 0.18 + 0.82 * shade * np.where(lit, 1.0, 0.25)
    img[h < -2.5] = 1.0                                     # off the die
    t = Image.fromarray((img * 235).astype(np.uint8)).convert("RGB")
    ImageDraw.Draw(t).text((6, 4), name, fill=(200, 40, 40))
    tiles.append(t)
W = Image.new("RGB", (N * 6 + 50, N + (30 if label else 10)), "white")
for i, t in enumerate(tiles): W.paste(t, (10 + i * (N + 6), 10 if not label else 30))
if label: ImageDraw.Draw(W).text((10, 8), label, fill=(0, 0, 0))
W.save(out)
print("wrote", out)
