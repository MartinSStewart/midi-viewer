module Evergreen.V5.Types exposing (..)

import Browser
import Browser.Navigation
import Bytes
import Dict
import Evergreen.V5.Audio
import Evergreen.V5.Midi
import File
import Time
import Url


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | MidiFileRequested
    | MidiFileSelected File.File
    | MidiFileLoaded String Bytes.Bytes
    | PianoSampleLoaded Int (Result Evergreen.V5.Audio.LoadError Evergreen.V5.Audio.Source)
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
    , recording : Result String Evergreen.V5.Midi.MidiRecording
    , pianoSamples : Dict.Dict Int (Result Evergreen.V5.Audio.LoadError Evergreen.V5.Audio.Source)
    , playbackStart : Maybe Time.Posix
    , now : Time.Posix
    , dummyField : Int
    }


type alias FrontendModel =
    Evergreen.V5.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendModel =
    {}


type alias FrontendMsg =
    Evergreen.V5.Audio.Msg FrontendMsg_


type ToBackend
    = NoOpToBackend


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
