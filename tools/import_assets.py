#!/usr/bin/env python3
"""Offline media-only ZIP importer. No scripts/scenes from an archive are executed.
Python is used once to copy assets, never as a game dependency or backend.
"""
import argparse
import hashlib
import json
import re
import stat
import sys
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {'.glb', '.gltf', '.bin', '.fbx', '.obj', '.mtl', '.png', '.jpg', '.jpeg', '.webp', '.tga', '.bmp', '.svg', '.ogv', '.mp4', '.mov', '.webm', '.ogg', '.wav', '.mp3', '.ttf', '.otf'}
MODEL = {'.glb', '.gltf', '.fbx', '.obj'}
IMAGE = {'.png', '.jpg', '.jpeg', '.webp', '.tga', '.bmp'}
RULES = {
    "game_logo": (IMAGE, ["logo", "游戏标题", "游戏图标"]),
    'deer_model': (MODEL, ['tufted_deer', 'tufteddeer', '毛冠鹿', 'deer']),
    'forest_model': (MODEL, ['forest', '森林', '环境', 'environment']),
    'portraits.tufted_deer': (IMAGE, ['tufted_deer', '毛冠鹿']),
    'portraits.otter': (IMAGE, ['otter', '水獭']),
    'portraits.hog_badger': (IMAGE, ['hog_badger', '猪獾']),
    'portraits.marten': (IMAGE, ['marten', '松貂']),
    'postcards.FIRST_MEETING': (IMAGE, ['first_meeting', '第一次见面', '初次见面']),
    'postcards.FIRST_EXPLORATION': (IMAGE, ['first_exploration', '初次探索']),
    'postcards.NEW_COMPANION': (IMAGE, ['new_companion', '新的伙伴']),
    'documentary': ({'.ogv'}, ['documentary', '纪录片', '毛冠鹿']),
    'forest_ambience': ({'.ogg', '.wav', '.mp3'}, ['ambience', 'ambient', '环境音', 'forest']),
}

def decoded_name(info):
    name = info.filename
    if not info.flag_bits & 0x800:
        try:
            candidate = name.encode('cp437').decode('gb18030')
            if any('\u4e00' <= ch <= '\u9fff' for ch in candidate):
                name = candidate
        except (UnicodeError, LookupError):
            pass
    return name.replace('\\', '/')

def safe_relative(info):
    path = PurePosixPath(decoded_name(info))
    if path.is_absolute() or '..' in path.parts or ':' in str(path) or not path.parts:
        raise ValueError('Unsafe ZIP path: ' + info.filename)
    if stat.S_ISLNK(info.external_attr >> 16):
        raise ValueError('ZIP symlinks are not allowed: ' + info.filename)
    return path

def set_key(config, key, value):
    parts = key.split('.')
    target = config
    for part in parts[:-1]:
        target = target.setdefault(part, {})
    target[parts[-1]] = value

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archives', nargs='+', type=Path)
    parser.add_argument('--apply', action='store_true', help='Copy media and update unambiguous mappings. Default is inspection only.')
    parser.add_argument('--mapping', type=Path, help='JSON object mapping asset keys to full res:// paths printed by inspection.')
    args = parser.parse_args()
    config_file = ROOT / 'data/assets.json'
    config = json.loads(config_file.read_text(encoding='utf-8'))
    copies = []
    candidates = {key: [] for key in RULES}
    destinations = set()
    for archive in args.archives:
        folder = re.sub(r'[^\w\-]+', '_', archive.stem)
        with zipfile.ZipFile(archive) as z:
            if sum(info.file_size for info in z.infolist()) > 4 * 1024**3:
                raise ValueError('Expanded media exceed 4 GiB; import manually instead.')
            for info in z.infolist():
                rel = safe_relative(info)
                if info.is_dir() or rel.suffix.lower() not in EXTENSIONS:
                    continue
                if '__MACOSX' in rel.parts or rel.name.startswith('._'):
                    continue
                destination = ROOT / 'assets/imported' / folder / Path(*rel.parts)
                if not destination.resolve().is_relative_to((ROOT / 'assets/imported').resolve()):
                    raise ValueError('Destination escapes asset folder.')
                resource_path = 'res://' + destination.relative_to(ROOT).as_posix()
                if resource_path in destinations:
                    raise ValueError('Duplicate destination; import archives with distinct names.')
                destinations.add(resource_path)
                copies.append((archive, info.filename, destination))
                print(resource_path)
                for key, (extensions, words) in RULES.items():
                    if rel.suffix.lower() in extensions and any(word in rel.stem.lower() for word in words):
                        candidates[key].append(resource_path)
    selected = {key: paths[0] for key, paths in candidates.items() if len(paths) == 1}
    if len(candidates['documentary']) == 0:
        films = [p for p in destinations if p.lower().endswith('.ogv')]
        if len(films) == 1:
            selected['documentary'] = films[0]
    if args.mapping:
        custom = json.loads(args.mapping.read_text(encoding='utf-8'))
        for key, path in custom.items():
            if key not in RULES or path not in destinations:
                raise ValueError('Mapping must select a listed media file for a known key: ' + key)
            if Path(path).suffix.lower() not in RULES[key][0]:
                raise ValueError('Wrong media type for ' + key)
            selected[key] = path
    print('\nUnambiguous mappings:\n' + json.dumps(selected, indent=2, ensure_ascii=False))
    for key, paths in candidates.items():
        if key not in selected:
            print('NEEDS REVIEW:', key, '—', len(paths), 'candidates')
    if not args.apply:
        print('\nInspection only; no files changed. Use --apply after reviewing the mapping.')
        return
    # Preflight all existing destinations before copying, so no user assets are overwritten.
    for archive, name, dest in copies:
        if dest.exists():
            with zipfile.ZipFile(archive) as z:
                with z.open(name) as source:
                    incoming = hashlib.file_digest(source, 'sha256').hexdigest()
            with dest.open('rb') as source:
                existing = hashlib.file_digest(source, 'sha256').hexdigest()
            if incoming != existing:
                raise ValueError('Refusing to overwrite a different existing asset: ' + str(dest))
    for archive, name, dest in copies:
        if dest.exists():
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive) as z, z.open(name) as source, dest.open('xb') as output:
            while chunk := source.read(1024 * 1024):
                output.write(chunk)
    for key, value in selected.items():
        set_key(config, key, value)
    serialized = json.dumps(config, ensure_ascii=False, indent=2) + '\n'
    if config_file.read_text(encoding='utf-8') != serialized:
        backup = config_file.with_suffix('.json.before-import')
        if not backup.exists():
            backup.write_bytes(config_file.read_bytes())
        config_file.write_text(serialized, encoding='utf-8')
    print('\nImported', len(copies), 'media files. Reopen Godot to import them.')
    print('MP4/MOV files need conversion to OGV. Check model scale, orientation, terrain and navigation in Godot.')

if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, zipfile.BadZipFile, json.JSONDecodeError) as error:
        print('Import stopped:', error, file=sys.stderr)
        sys.exit(1)
