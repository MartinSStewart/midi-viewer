# midi-viewer (this readme and the code is AI generated)

A MIDI file parser and piano-roll viewer, built as a [Lamdera](https://lamdera.com) app (the backend is a no-op — everything happens in the frontend).

Open a `.mid` file and you get:

- a piano roll (piano keyboard on the left, one row per note, channel-colored notes, velocity shown as opacity)
- a summary line (format, ticks/beat, tempo, note count, approximate duration)
- a decoded per-track event list

A small built-in demo recording is rendered before any file is loaded.

## Modules

- `src/Midi.elm` — the interesting part: MIDI types, a parser and encoder built on `elm/bytes` (`fromBytes`/`toBytes` for file images, `eventFromBytes`/`eventToBytes` for standalone Web-MIDI-style events), and the piano-roll renderer (`viewRecording`). The types and parsing behavior are modelled on [newlandsvalley/elm-comidi](https://github.com/newlandsvalley/elm-comidi), updated from Elm 0.18. Running status tracks the raw status byte, so velocity-zero note-ons (which parse as note-offs) don't corrupt later running-status events.
- `src/Frontend.elm` — app shell: file picker, error display, page layout.
- `src/Backend.elm`, `src/Types.elm`, `src/Env.elm` — Lamdera boilerplate with a dummy backend.

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
