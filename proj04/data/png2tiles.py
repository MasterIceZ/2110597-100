#install this first
#pip install pillow
#usage: python png2tiles.py
#back.png + front.png (1280x480) -> beach_tiles.mem + beach_map.mem

from PIL import Image

TILE = 16
COLS, ROWS = 80, 30


def to_6bit(r, g, b):
    return (r >> 6) << 4 | (g >> 6) << 2 | (b >> 6)


tiles = [(0x3F,) * (TILE * TILE)]
tile_id_of = {tiles[0]: 0}
game_map = []

for name in ["back.png", "front.png"]:
    img = Image.open(name).convert("RGB")
    for row in range(ROWS):
        line = []
        for col in range(COLS):
            tile = tuple(to_6bit(*img.getpixel((col * TILE + x, row * TILE + y)))
                         for y in range(TILE) for x in range(TILE))
            if tile not in tile_id_of:
                tile_id_of[tile] = len(tiles)
                tiles.append(tile)
            line.append(tile_id_of[tile])
        game_map.append(line)

assert len(tiles) <= 256
print("tiles used:", len(tiles))

with open("beach_map.mem", "w") as f:
    for line in game_map:
        f.write(" ".join(f"{t:02x}" for t in line) + "\n")

sheet = [[0x3F] * 256 for _ in range(256)]
for n, tile in enumerate(tiles):
    for y in range(TILE):
        for x in range(TILE):
            sheet[n // 16 * TILE + y][n % 16 * TILE + x] = tile[y * TILE + x]

with open("beach_tiles.mem", "w") as f:
    for line in sheet:
        for v in line:
            f.write(f"{v:02x}\n")
