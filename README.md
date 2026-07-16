# midi-viewer (this readme and the code is AI generated)

A MIDI file parser and piano-roll viewer, built as a [Lamdera](https://lamdera.com) app (the backend is a no-op — everything happens in the frontend).

Open a `.mid` file and you get:

- a piano roll (piano keyboard on the left, one row per note, channel-colored notes, velocity shown as opacity)
- a summary line (format, ticks/beat, tempo, note count, approximate duration)
- a decoded per-track event list
- playback with a piano sound (all instruments are rendered as piano to keep things simple)

A small built-in demo recording is rendered before any file is loaded.

## Modules

- `src/Midi.elm` — the interesting part: MIDI types, a parser and encoder built on `elm/bytes` (`fromBytes`/`toBytes` for file images, `eventFromBytes`/`eventToBytes` for standalone Web-MIDI-style events), and the piano-roll renderer (`viewRecording`). The types and parsing behavior are modelled on [newlandsvalley/elm-comidi](https://github.com/newlandsvalley/elm-comidi), updated from Elm 0.18. Running status tracks the raw status byte, so velocity-zero note-ons (which parse as note-offs) don't corrupt later running-status events.
- `src/Frontend.elm` — app shell: file picker, error display, page layout, and audio playback built on the vendored `Audio` module (notes are pitch-shifted from the piano samples in `public/`, `elm-pkg-js/audio.js` is the port glue, and `src/Ports.elm` declares the ports). During playback the roll scrolls in time with the music and the keys light up.
- `src/Audio.elm` — a vendored copy of [MartinSStewart/elm-audio](https://package.elm-lang.org/packages/MartinSStewart/elm-audio/latest/) so its playback-diffing can be optimized. `diffAudioState` works out the minimal set of Web-Audio changes each frame; it was rewritten from `O(playing × wanted)` to roughly `O((playing + wanted) · log)` by bucketing sounds by identity, and it now short-circuits entirely when the audio hasn't changed since the previous frame (the common case when only a clock is ticking). Regression tests live in `tests/AudioDiffTests.elm`.
- `src/Backend.elm`, `src/Types.elm`, `src/Env.elm` — Lamdera boilerplate with a dummy backend.

The piano note recordings come from [gleitz/midi-js-soundfonts](https://github.com/gleitz/midi-js-soundfonts) (FluidR3\_GM acoustic grand piano, MIT licensed).

## Running

```
lamdera live
```

then open <http://localhost:8000>.

## Tests

Round-trip fuzz tests (`MidiEvent`/`MidiRecording` → bytes → back), ported from elm-comidi, plus byte-level unit tests for running status, velocity-zero note-ons, and non-standard header chunk sizes:

```
elm-test-rs --compiler `which lamdera`
```
