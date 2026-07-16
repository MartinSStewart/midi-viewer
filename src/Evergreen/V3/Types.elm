module Evergreen.V3.Types exposing (..)

import Browser
import Browser.Navigation
import Bytes
import Dict
import Evergreen.V3.Audio
import Evergreen.V3.Midi
import File
import Time
import Url


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | MidiFileRequested
    | MidiFileSelected File.File
    | MidiFileLoaded String Bytes.Bytes
    | PianoSampleLoaded Int (Result Evergreen.V3.Audio.LoadError Evergreen.V3.Audio.Source)
    | PressedPlay
    | GotPlaybackStartTime Time.Posix
    | PressedStop
    | Tick Time.Posix
    | NoOp


type Source
    = Demo
    | FromFile String


type alias FrontendModel_ =
    { key : Browser.Navigation.Key
    , source : Source
    , recording : Result String Evergreen.V3.Midi.MidiRecording
    , pianoSamples : Dict.Dict Int (Result Evergreen.V3.Audio.LoadError Evergreen.V3.Audio.Source)
    , playbackStart : Maybe Time.Posix
    , now : Time.Posix
    }


type alias FrontendModel =
    Evergreen.V3.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendModel =
    {}


type alias FrontendMsg =
    Evergreen.V3.Audio.Msg FrontendMsg_


type ToBackend
    = NoOpToBackend


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
