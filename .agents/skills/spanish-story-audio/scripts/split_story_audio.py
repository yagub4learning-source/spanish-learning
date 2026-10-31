#!/usr/bin/env python3
"""Create sentence clips from storyData; see ../references/workflow.md."""
import argparse
import difflib
import hashlib
import json
from pathlib import Path
import re
import unicodedata

SITE = next(parent for parent in Path(__file__).resolve().parents
            if (parent / 'index.html').is_file())
DATA_RE = re.compile(r'const storyData = (.*?);\n')


def normalize(text):
    return ''.join(c for c in unicodedata.normalize('NFD', text.lower())
                   if c.isalpha() and not unicodedata.combining(c))


def align(story, words):
    expected, ranges = [], []
    for pair in story['sentences']:
        start = len(expected)
        expected.extend(filter(None, map(normalize, pair['es'].split())))
        ranges.append((start, len(expected)))
    actual = [normalize(w['word']) for w in words]
    mapping = {}
    for block in difflib.SequenceMatcher(None, expected, actual, autojunk=False).get_matching_blocks():
        for offset in range(block.size):
            mapping[block.a + offset] = block.b + offset
    for number, (start, end) in enumerate(ranges, 1):
        if start == end or start not in mapping or end - 1 not in mapping:
            raise ValueError(f"{story['title']}, sentence {number}: unmatched boundary. "
                             f"Review the cached transcript: {story['sentences'][number - 1]['es']}")
    print(f"{story['title']}: matched {len(mapping)}/{len(expected)} words")
    return ranges, mapping


def check(data):
    import av
    count = 0
    for story in data:
        if not (SITE / story['audio']['src']).is_file():
            raise ValueError(f"Missing full audio: {story['audio']['src']}")
        seen = set()
        for pair in story['sentences']:
            path = SITE / pair['audio']
            if path in seen:
                raise ValueError(f'Duplicate clip: {path}')
            seen.add(path)
            with av.open(str(path)) as source:
                duration = sum(f.samples / f.sample_rate for f in source.decode(audio=0))
            if duration <= .12:
                raise ValueError(f'Empty/short clip: {path}')
            count += 1
    print(f'PASS: {count} sentence clips decode; full audio files exist')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--story', help='Story id, exact title, or full audio filename stem')
    parser.add_argument('--force', action='store_true', help='Rebuild existing clips for selected stories')
    parser.add_argument('--check', action='store_true', help='Only decode and validate existing clips')
    parser.add_argument('--cache-dir', type=Path, default=Path('/private/tmp/spanish-audio-cache'))
    parser.add_argument('--model-dir', type=Path, default=Path('/private/tmp/spanish-whisper-model'))
    args = parser.parse_args()
    page = SITE / 'index.html'
    html = page.read_text()
    match = DATA_RE.search(html)
    if not match:
        raise ValueError('Cannot find storyData JSON in index.html')
    data = json.loads(match.group(1))
    if args.check:
        check(data)
        return
    chosen = [s for s in data if not args.story or args.story in
              (s['id'], s['title'], Path(s['audio']['src']).stem)]
    if not chosen:
        parser.error('No matching story')
    pending = [s for s in chosen if args.force or not all(
        p.get('audio') and (SITE / p['audio']).is_file() for p in s['sentences'])]
    if not pending:
        print('Nothing to generate; existing clips preserved.')
        return
    import av
    import numpy as np
    from faster_whisper import WhisperModel
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    model = None
    records = []
    # Validate every selected sentence boundary before creating any clips.
    for story in pending:
        source = SITE / story['audio']['src']
        prompt = ' '.join(p['es'] for p in story['sentences'])
        fingerprint = hashlib.sha256(source.read_bytes() + prompt.encode()).hexdigest()
        cache = args.cache_dir / f'{source.stem}-{fingerprint}.json'
        if cache.exists():
            words = json.loads(cache.read_text())
        else:
            if model is None:
                model = WhisperModel('small', device='cpu', compute_type='int8',
                                     download_root=str(args.model_dir))
            segments, _ = model.transcribe(str(source), language='es', word_timestamps=True,
                                            beam_size=5, initial_prompt=prompt)
            words = [dict(word=w.word, start=w.start, end=w.end)
                     for segment in segments for w in segment.words]
            cache.write_text(json.dumps(words, ensure_ascii=False, indent=2))
        ranges, mapping = align(story, words)
        records.append((story, words, ranges, mapping))
    manifest = []
    for story, words, ranges, mapping in records:
        with av.open(str(SITE / story['audio']['src'])) as source:
            resampler = av.AudioResampler(format='fltp', layout='mono', rate=44100)
            chunks = [f.to_ndarray() for frame in source.decode(audio=0)
                      for f in resampler.resample(frame)]
            chunks.extend(f.to_ndarray() for f in resampler.resample(None))
        audio = np.concatenate(chunks, axis=1)
        duration = audio.shape[1] / 44100
        folder = SITE / 'sentence-audio' / Path(story['audio']['src']).stem
        folder.mkdir(parents=True, exist_ok=True)
        previous_end = 0
        for i, (start, end) in enumerate(ranges):
            a, b = mapping[start], mapping[end - 1]
            left, right = words[a]['start'], words[b]['end']
            previous = words[a - 1]['end'] if a else 0
            following = words[b + 1]['start'] if b + 1 < len(words) else duration
            left = max(0, left - min(.09, max(0, left - previous) / 2))
            right = min(duration, right + min(.12, max(0, following - right) / 2))
            if right - left <= .12 or left + .001 < previous_end:
                raise ValueError(f"{story['title']}, sentence {i + 1}: invalid/overlapping timing")
            previous_end = right
            target = folder / f'{i + 1:02d}.mp3'
            with av.open(str(target), 'w') as output:
                stream = output.add_stream('libmp3lame', rate=44100)
                stream.layout, stream.bit_rate = 'mono', 96000
                frame = av.AudioFrame.from_ndarray(
                    audio[:, round(left * 44100):round(right * 44100)], format='fltp', layout='mono')
                frame.sample_rate = 44100
                for packet in stream.encode(frame):
                    output.mux(packet)
                for packet in stream.encode(None):
                    output.mux(packet)
            pair = story['sentences'][i]
            pair['audio'] = str(target.relative_to(SITE))
            manifest.append(dict(story=story['title'], sentence=i + 1, text=pair['es'],
                                 start=round(left, 3), end=round(right, 3), audio=pair['audio']))
        print(f"Created {len(ranges)} clips: {folder.name}")
    page.write_text(html[:match.start(1)] + json.dumps(data, ensure_ascii=False) + html[match.end(1):])
    (args.cache_dir / 'last-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    check(data)


if __name__ == '__main__':
    main()
