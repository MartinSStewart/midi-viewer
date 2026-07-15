module Types exposing
    ( BackendModel
    , BackendMsg(..)
    , FrontendModel
    , FrontendMsg(..)
    , Source(..)
    , ToBackend(..)
    , ToFrontend(..)
    )

import Browser exposing (UrlRequest)
import Browser.Navigation
import Bytes exposing (Bytes)
import File exposing (File)
import Midi
import Url exposing (Url)


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , source : Source
    , recording : Result String Midi.MidiRecording
    }


type Source
    = Demo
    | FromFile String


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | MidiFileRequested
    | MidiFileSelected File
    | MidiFileLoaded String Bytes


type ToBackend
    = NoOpToBackend


type alias BackendModel =
    {}


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
