module Evergreen.V1.Midi exposing (..)


type alias Ticks =
    Int


type alias Byte =
    Int


type SysExFlavour
    = F0
    | F7


type alias Channel =
    Int


type alias Note =
    Int


type alias Velocity =
    Int


type MidiEvent
    = SequenceNumber Int
    | Text String
    | Copyright String
    | TrackName String
    | InstrumentName String
    | Lyrics String
    | Marker String
    | CuePoint String
    | ChannelPrefix Int
    | Tempo Int
    | SMPTEOffset Int Int Int Int Int
    | TimeSignature Int Int Int Int
    | KeySignature Int Int
    | SequencerSpecific (List Byte)
    | SysEx SysExFlavour (List Byte)
    | Unspecified Int (List Byte)
    | NoteOn Channel Note Velocity
    | NoteOff Channel Note Velocity
    | NoteAfterTouch Channel Note Velocity
    | ControlChange Channel Int Int
    | ProgramChange Channel Int
    | ChannelAfterTouch Channel Velocity
    | PitchBend Channel Int


type alias MidiMessage =
    ( Ticks, MidiEvent )


type alias Track =
    List MidiMessage


type TracksType
    = Simultaneous
    | Independent


type MidiRecording
    = SingleTrack Int Track
    | MultipleTracks TracksType Int (List Track)
