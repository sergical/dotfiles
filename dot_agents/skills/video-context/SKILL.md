---
name: video-context
description: Get the transcript, title, timestamps and key frames of a video with the `summarize` CLI. Use whenever a task needs to know what a video says or shows, such as a YouTube, Loom, X or Vimeo link or a local media file, even when the user only says "watch this", "what do they say about", "summarize this talk" or pastes a video URL. Also use to list the videos of a channel or playlist.
---

# Video Context

`summarize` (Homebrew) already solves video context: captions first, then
yt-dlp, then local whisper.cpp when a video has no captions. It caches each
result in `~/.summarize/`, so a second read costs no network. One command gives
the whole transcript. Do not find a method again: past sessions lost many calls
to approaches that this tool already replaces (see "Do not").

You are the summarizer. Use `--extract` so that `summarize` prints the source
text and does not call a model, which needs an API key. Read the text, then
answer.

## Transcript

Write the result to a file in your scratch directory, then read it. A one-hour
talk is about 10,000 words, which is too much to print into the conversation.

```sh
summarize "$URL" --extract --timestamps --json > "$SCRATCH/raw.json" &&
  jq -Rrs '(fromjson? | .extracted | "# \(.title)\n\(.transcriptMetadata.durationSeconds // "?")s · \(if .transcriptionProvider then "speech-to-text (\(.transcriptionProvider))" else "captions via \(.transcriptSource)" end)\n\n\(.content)") // .' \
  "$SCRATCH/raw.json" > "$SCRATCH/video.txt" &&
  wc -w "$SCRATCH/video.txt"
```

If `summarize` exits non-zero, read its error and see "Failures". Do not parse
the output of a failed run.

- `$URL` can be a YouTube URL, a direct media URL, or a local file path. For a
  local file, `summarize` ignores `--json` and prints plain text; the jq filter
  passes that text through unchanged.
- For a URL, the first lines give the title, the length in seconds and where
  the text came from. Captions can be automatic, and speech-to-text output and
  every local file come from a transcription model, so expect spelling errors
  in names.
- Caption lines start with `[m:ss]`. Quote the time when you cite the video, so
  the user can jump to it.
- For more than about 3,000 words, read the file in parts, or `grep -n` for the
  topic and read the lines around each hit.

## Frames

Add frames when what is on screen matters: slides, code, a UI demo or a chart.

```sh
summarize "$URL" --extract --timestamps --slides --slides-debug \
  --slides-dir "$SCRATCH/slides" --slides-max 12 > "$SCRATCH/video.txt"
```

The transcript then holds a `Slide N/M · m:ss` line and a PNG path at each scene
change. Open only the PNGs that the question needs. Add `--slides-ocr` when you
must search the text on the slides (it needs `tesseract`).

Scene changes can be far apart: in a two-minute sketch, six slides covered the
whole video, and the nearest slide to an event at 0:13 was from 0:01. When the
question names a moment ("when they ask for X", "at the end"), find its time
in the transcript and take one frame at that second. Download only that second:
YouTube can return 403 when ffmpeg opens the stream URL from `yt-dlp -g`.
yt-dlp prints the real file path, because the container can be MP4 or WebM.

```sh
clip=$(yt-dlp -q -f "bv*[height<=720]" --download-sections "*16-17" \
  --force-overwrites -o "$SCRATCH/at16.%(ext)s" \
  --print after_move:filepath "$URL") &&
  ffmpeg -loglevel error -y -i "$clip" -frames:v 1 "$SCRATCH/at16.png"
```

For the end of a video, use the length from the transcript header and take a
frame 2 to 3 seconds before it.

## Channels and playlists

`summarize` prints nothing and exits 0 for a channel or playlist URL. Use
yt-dlp to list the videos, newest first, then run `summarize` on each one that
you need:

```sh
yt-dlp --flat-playlist --playlist-end 20 --print "%(id)s|%(title)s" \
  "https://www.youtube.com/@handle/videos"
```

- The flat list prints `NA` for dates. For dates, remove `--flat-playlist` and
  keep `--playlist-end` small: each video costs about 3 seconds.
- A handle can point to a different or empty channel ("does not have a videos
  tab"). Find the `UC…` channel ID, then use
  `https://www.youtube.com/channel/<id>/videos`.

## Failures

| Symptom | Fix |
| --- | --- |
| HTTP 403 or "Sign in to confirm" | Run again with `SUMMARIZE_YT_DLP_COOKIES_FROM_BROWSER=chrome` |
| "Media file transcription requires…" | Run `chezmoi apply` (it installs the whisper model) and `brew bundle install --no-upgrade --file=~/.Brewfile` (it installs `whisper-cli`) |
| Loom, X or Vimeo URL fails | Run `yt-dlp -f ba -o "$SCRATCH/audio.%(ext)s" "$URL"`, then run `summarize` on the file |
| Empty output, exit 0 | The URL is a channel, playlist or page; see "Channels and playlists" |

## Do not

Each of these cost past sessions many calls, and `summarize` does the same in
one:

- Fetch youtube.com pages or oEmbed with a web-fetch tool. They do not contain
  the transcript.
- Use transcript websites. They are slow, rate-limited and often fail.
- Open the transcript panel in a browser.
- Write a VTT or caption parser, or download the whole video for frames, for a
  one-time question. Build your own pipeline only when a product needs word
  timings or frames at a fixed rate.
