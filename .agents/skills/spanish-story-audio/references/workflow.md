# Sentence audio workflow

Use `split_story_audio.py` for this project. It reproduces the method used for the existing ten stories: Whisper word timestamps matched against the already written Spanish sentences. This is speech recognition plus text matching, not a dedicated forced-alignment model and not silence-only splitting. Timing is approximate and needs listening checks.

## Files and naming

- The only HTML source is `github-pages/index.html`; its `storyData` contains each story's `sentences` array and full recording in `audio.src`.
- Resolve a requested story by title, not the displayed number: page numbering includes the two learning sections and differs from internal story IDs.
- Full recording: `<spanish-title-slug>.mp3`, lower case, hyphens, no accents (e.g. `un-cafe-con-ana.mp3`).
- Sentence clips: `sentence-audio/<same-title-slug>/01.mp3`, `02.mp3`, etc., in the order of `sentences`. Do not use `story-2` folder names.
- Each sentence gets an `audio` property relative to `index.html`. Existing popup code automatically shows a play/pause button when this property is present. Preserve `story.audio.src` and the full-story player.
- Keep recordings and clips only inside `github-pages/`. Never create duplicate HTML or audio in the project root.

## Setup and commands

From the project root (the directory containing AGENTS.md):

```sh
python3 -m venv /private/tmp/spanish-audio-env
/private/tmp/spanish-audio-env/bin/pip install -r github-pages/.agents/skills/spanish-story-audio/scripts/requirements.txt
```

Generate only missing clips for all stories:

```sh
/private/tmp/spanish-audio-env/bin/python github-pages/.agents/skills/spanish-story-audio/scripts/split_story_audio.py
```

Or select a story by full audio filename stem (exact title or internal ID also accepted):

```sh
/private/tmp/spanish-audio-env/bin/python github-pages/.agents/skills/spanish-story-audio/scripts/split_story_audio.py --story un-cafe-con-ana
```

The script preserves completed stories by default. To intentionally rebuild a selected story after changing its recording or text, use `--story <slug> --force`. Review and remove obsolete clips if the new sentence count is smaller; the script does not delete them automatically.

```sh
/private/tmp/spanish-audio-env/bin/python github-pages/.agents/skills/spanish-story-audio/scripts/split_story_audio.py --check
```

`--check` only checks existing files; it does not download a model, transcribe, or change the HTML. The first generation needs network access to download the `small` model. Defaults: model in `/private/tmp/spanish-whisper-model`, transcript cache and `last-manifest.json` in `/private/tmp/spanish-audio-cache`. Both locations are disposable and can be overridden with `--model-dir` and `--cache-dir`. Do not assume old temporary files survive a new session. Cache keys include the recording and sentence text hashes to prevent reuse of stale timestamps.

## Exact splitting method

1. Read the existing `sentences` array; do not split Spanish text again or alter translations. It is the source of truth for popup boundaries, including dialogue.
2. Transcribe the full recording locally with `faster-whisper`, model `small`, CPU, `compute_type='int8'`, `language='es'`, `word_timestamps=True`, `beam_size=5`. Supply the Spanish sentences as `initial_prompt`.
3. Normalize expected and recognized words: lowercase, remove accents, punctuation and digits. Match their ordered sequences with `difflib.SequenceMatcher(autojunk=False)`.
4. Require the first and last word of every sentence to match. If a boundary does not match, stop, inspect the cached transcript and listen around that point. Correct a transcription error only after verifying it against the recording; if speech differs from the story, resolve that discrepancy explicitly. Never guess timings from text length or divide the recording into equal parts. Internal recognition errors can be harmless when both boundaries match; inspect them as needed.
5. Take the first word's start and last word's end. Add up to 90 ms before and 120 ms after, bounded by half the available gap to the adjacent word. Never extend beyond the recording. Reject clips of 120 ms or less, reversed boundaries, and overlapping sentence timings.
6. Decode the original with PyAV to mono float audio at 44,100 Hz. Slice the samples using those timestamps, then encode MP3 using `libmp3lame`, 96 kbit/s. Keep the original full recording untouched.
7. Write each sentence's relative clip path into `storyData`, leaving the rest of the page unchanged. Save the timing manifest for review.

## Verification and publishing

- Run `--check`: every sentence must have its own existing, decodable, nonempty clip. Check the HTML's audio paths against files on disk and inspect the diff for unrelated changes.
- Listen to representative clips from each newly processed story, especially short dialogue, first/last sentences, zero-gap boundaries, and any recognition mismatch. Automated matching/decoding alone does not prove clean cuts; adjust timestamps if speech is clipped or a neighbour is included.
- Verify the popup play/pause button, stopping at clip end, replaying, and that sentence playback pauses the full-story player (and vice versa).
- Commit and push from `github-pages/` to `main`. If push fails with `HTTP 400` / `unexpected disconnect`, the previously successful retry was `git -c http.postBuffer=52428800 push origin main`.
- Wait for the matching commit's GitHub Pages build to report `built`, then fetch the published HTML and check the audio URLs. Do not report deployment success just because push succeeded.
- Site: https://yagub4learning-source.github.io/spanish-learning/
- Repository: https://github.com/yagub4learning-source/spanish-learning
