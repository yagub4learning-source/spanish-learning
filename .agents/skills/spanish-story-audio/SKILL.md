---
name: spanish-story-audio
description: Create or regenerate sentence audio clips for the Spanish learning stories, align existing full recordings to written sentences, and connect clips to translation popup play buttons in this project. Use when adding audio to a new story or rebuilding sentence clips.
---

# Spanish story audio

Read [the workflow](references/workflow.md) before generating or regenerating clips. It contains the proven alignment settings, setup commands, boundary checks, and publishing procedure.

Use [scripts/split_story_audio.py](scripts/split_story_audio.py) and [scripts/requirements.txt](scripts/requirements.txt). The script locates the site's `index.html` among its parent directories. All generated files belong under that site directory.

- Resolve stories by title or full recording filename stem; visible page numbers differ from internal story IDs.
- Treat `storyData.sentences` as the sentence boundaries and keep the original full recording. Add each sentence's relative `audio` path for the existing popup button.
- Use title slugs for both full recordings and `sentence-audio/<slug>/NN.mp3`. Do not create duplicate HTML or audio in the project root.
- Match recognized word timestamps to the written text. Stop and inspect unmatched boundary words; never estimate cuts from sentence length or pauses alone.
- Preserve existing clips by default. Use `--story <slug> --force` only when intentionally rebuilding that story.
- Validate decoding and paths, listen around uncertain cuts, and check playback. Automated matching does not establish clean audible boundaries.
- Follow the project's AGENTS.md publishing instructions. Confirm a completed Pages build and live asset availability before reporting publication success.
