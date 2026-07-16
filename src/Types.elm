module Types exposing
    ( BackendModel
    , BackendMsg(..)
    , FrontendModel
    , FrontendModel_
    , FrontendMsg
    , FrontendMsg_(..)
    , Source(..)
    , ToBackend(..)
    , ToFrontend(..)
    )

import Audio
import Browser exposing (UrlRequest)
import Browser.Navigation
import Bytes exposing (Bytes)
import Dict exposing (Dict)
import File exposing (File)
import Midi
import Time
import Url exposing (Url)


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type alias FrontendModel_ =
    { key : Browser.Navigation.Key
    , source : Source
    , recording : Result String Midi.MidiRecording

    -- piano samples used for playback, keyed by the MIDI note they are a recording of
    , pianoSamples : Dict Int (Result Audio.LoadError Audio.Source)
    , playbackStart : Maybe Time.Posix

    -- the current wall-clock time, updated each animation frame while playing so
    -- the piano roll can scroll and highlight keys in time with the music
    , now : Time.Posix
    }


type Source
    = Demo
    | FromFile String


type FrontendMsg_
    = UrlClicked UrlRequest
    | UrlChanged Url
    | MidiFileRequested
    | MidiFileSelected File
    | MidiFileLoaded String Bytes
    | PianoSampleLoaded Int (Result Audio.LoadError Audio.Source)
    | PressedPlay
    | GotPlaybackStartTime Time.Posix
    | PressedStop
    | Tick Time.Posix
    | NoOp


type ToBackend
    = NoOpToBackend


type alias BackendModel =
    {}


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
