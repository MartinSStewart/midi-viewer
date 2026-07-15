module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Bytes
import Evergreen.V1.Midi
import File
import Url


type Source
    = Demo
    | FromFile String


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , source : Source
    , recording : Result String Evergreen.V1.Midi.MidiRecording
    }


type alias BackendModel =
    {}


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | MidiFileRequested
    | MidiFileSelected File.File
    | MidiFileLoaded String Bytes.Bytes


type ToBackend
    = NoOpToBackend


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
