"""Build the runtime atlas directly from the current editable source images."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parent
DIRECTIONS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']
GIF_FOLDERS = {'run': 'Running', 'jump': 'Jumping', 'mantle': 'Climbing', 'attack': 'Attack'}


def load_gif(folder, direction):
    exact = ROOT / folder / f'{direction}.gif'
    matches = [exact] if exact.exists() else list((ROOT / folder).glob(f'*_{direction}.gif'))
    if len(matches) != 1:
        raise ValueError(f'{folder}/{direction}: expected one source GIF, found {matches}')
    frames, durations = [], []
    with Image.open(matches[0]) as source:
        for index in range(source.n_frames):
            source.seek(index)
            frames.append(source.convert('RGBA'))
            durations.append(source.info.get('duration', 200) / 1000)
    return frames, durations


def build():
    clips, timings = {}, {}
    for category, folder in GIF_FOLDERS.items():
        clips[category], timings[category] = {}, {}
        for direction in DIRECTIONS:
            clips[category][direction], timings[category][direction] = load_gif(folder, direction)
    clips['followup'], timings['followup'] = {}, {}
    for direction in DIRECTIONS:
        clips['followup'][direction], timings['followup'][direction] = load_gif('AttackContinue1', direction)
    for category, folder in [('base', 'Idle/base'), ('crouch', 'Crouch'), ('slide', 'Sliding'), ('dash', 'Dash'), ('protect', 'Protect')]:
        clips[category] = {d: [Image.open(ROOT / folder / f'{d}.png').convert('RGBA')] for d in DIRECTIONS}
    idle = Image.open(ROOT / 'Idle/samurai-idle-sheet.png').convert('RGBA')
    clips['idle'] = {d: [idle.crop((f * 64, row * 64, (f + 1) * 64, (row + 1) * 64)) for f in range(6)] for row, d in enumerate(DIRECTIONS)}
    walking = Image.open(ROOT / 'Walking/east-sheet.png').convert('RGBA')
    clips['walk'] = {'east': [walking.crop((x, 0, x + 64, 64)) for x in range(0, walking.width, 64)]}
    order = ['base', 'idle', 'walk', 'run', 'jump', 'mantle', 'crouch', 'slide', 'dash', 'protect', 'attack']
    if 'followup' in clips:
        order.append('followup')
    # One row per direction and category. Different source sizes are padded, never scaled.
    cells = {c: (max(im.width for frames in clips[c].values() for im in frames), max(im.height for frames in clips[c].values() for im in frames)) for c in order}
    width = max(cells[c][0] * max(map(len, clips[c].values())) for c in order)
    height = sum(cells[c][1] * len(clips[c]) for c in order)
    atlas = Image.new('RGBA', (width, height))
    animations, offsets = {}, {}
    y = 0
    for category in order:
        w, h = cells[category]
        animations[category], offsets[category] = {}, {}
        for direction, frames in clips[category].items():
            regions = []
            for index, frame in enumerate(frames):
                dx, dy = (w - frame.width) // 2, (h - frame.height) // 2
                tile = Image.new('RGBA', (w, h))
                tile.paste(frame, (dx, dy))
                x = index * w
                atlas.paste(tile, (x, y))
                assert atlas.crop((x, y, x + w, y + h)).tobytes() == tile.tobytes()
                regions.append([x, y, w, h])
            animations[category][direction] = regions
            first = frames[0]
            offsets[category][direction] = first.getbbox()[3] + (h - first.height) // 2 - h / 2 if category in ['attack', 'slide', 'dash', 'protect', 'followup'] else (32 if category in ['run', 'jump', 'mantle'] else 30)
            y += h
    atlas.save(ROOT / 'samurai-atlas.png')
    manifest = {'width': width, 'height': height, 'directions': DIRECTIONS, 'animations': animations, 'timings': timings, 'offsets': offsets}
    (ROOT / 'samurai-atlas.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print(f'PASS: {width}x{height} atlas; all current source frames verified without scaling')


if __name__ == '__main__':
    build()
