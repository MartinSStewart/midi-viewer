module Frontend exposing (app)

import Audio exposing (Audio, AudioData)
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Dict
import File
import File.Select
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Lamdera
import Midi
import Ports
import Task
import Time
import Types exposing (..)
import Url


app :
    { init : Lamdera.Url -> Browser.Navigation.Key -> ( FrontendModel, Cmd FrontendMsg )
    , view : FrontendModel -> Browser.Document FrontendMsg
    , update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
    , updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
    , subscriptions : FrontendModel -> Sub FrontendMsg
    , onUrlRequest : UrlRequest -> FrontendMsg
    , onUrlChange : Url.Url -> FrontendMsg
    }
app =
    Lamdera.frontend
        (Audio.lamderaFrontendWithAudio
            { init = init
            , onUrlRequest = UrlClicked
            , onUrlChange = UrlChanged
            , update = update
            , updateFromBackend = updateFromBackend
            , subscriptions = \_ _ -> Sub.none
            , view = view
            , audio = audio
            , audioPort = { toJS = Ports.audioPortToJS, fromJS = Ports.audioPortFromJS }
            }
        )


{-| The recordings of single piano notes used for playback, along with the
MIDI note each one is a recording of. Notes in between are played by
pitch-shifting the nearest sample.
-}
pianoSampleUrls : List ( Int, String )
pianoSampleUrls =
    [ ( 36, "/piano-c2.mp3" )
    , ( 60, "/piano-c4.mp3" )
    , ( 84, "/piano-c6.mp3" )
    ]


init : Url.Url -> Browser.Navigation.Key -> ( FrontendModel_, Cmd FrontendMsg_, Audio.AudioCmd FrontendMsg_ )
init _ key =
    ( { key = key
      , source = Demo
      , recording = Ok Midi.demoRecording
      , pianoSamples = Dict.empty
      , playbackStart = Nothing
      }
    , Cmd.none
    , pianoSampleUrls
        |> List.map (\( root, url ) -> Audio.loadAudio (PianoSampleLoaded root) url)
        |> Audio.cmdBatch
    )


update : AudioData -> FrontendMsg_ -> FrontendModel_ -> ( FrontendModel_, Cmd FrontendMsg_, Audio.AudioCmd FrontendMsg_ )
update _ msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Browser.Navigation.pushUrl model.key (Url.toString url), Audio.cmdNone )

                External url ->
                    ( model, Browser.Navigation.load url, Audio.cmdNone )

        UrlChanged _ ->
            ( model, Cmd.none, Audio.cmdNone )

        MidiFileRequested ->
            ( model
            , File.Select.file [ "audio/midi", "audio/x-midi", ".mid", ".midi" ] MidiFileSelected
            , Audio.cmdNone
            )

        MidiFileSelected file ->
            ( model
            , Task.perform (MidiFileLoaded (File.name file)) (File.toBytes file)
            , Audio.cmdNone
            )

        MidiFileLoaded name bytes ->
            ( { model
                | source = FromFile name
                , recording = Midi.fromBytes bytes
                , playbackStart = Nothing
              }
            , Cmd.none
            , Audio.cmdNone
            )

        PianoSampleLoaded root result ->
            ( { model | pianoSamples = Dict.insert root result model.pianoSamples }
            , Cmd.none
            , Audio.cmdNone
            )

        PressedPlay ->
            ( model, Task.perform GotPlaybackStartTime Time.now, Audio.cmdNone )

        GotPlaybackStartTime time ->
            -- start a moment in the future so notes at tick 0 aren't skipped
            ( { model | playbackStart = Just (addMillis 200 time) }
            , Cmd.none
            , Audio.cmdNone
            )

        PressedStop ->
            ( { model | playbackStart = Nothing }, Cmd.none, Audio.cmdNone )


updateFromBackend : AudioData -> ToFrontend -> FrontendModel_ -> ( FrontendModel_, Cmd FrontendMsg_, Audio.AudioCmd FrontendMsg_ )
updateFromBackend _ msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none, Audio.cmdNone )



-- AUDIO


audio : AudioData -> FrontendModel_ -> Audio
audio _ model =
    case ( model.playbackStart, model.recording, loadedPianoSamples model.pianoSamples ) of
        ( Just startTime, Ok recording, Just samples ) ->
            Midi.playbackNotes recording
                |> List.map (noteAudio samples startTime)
                |> Audio.group
                -- headroom so chords don't clip
                |> Audio.scaleVolume 0.5

        _ ->
            Audio.silence


{-| All piano samples, once every one of them has loaded successfully
-}
loadedPianoSamples : Dict.Dict Int (Result Audio.LoadError Audio.Source) -> Maybe (List ( Int, Audio.Source ))
loadedPianoSamples samples =
    let
        loaded =
            Dict.toList samples
                |> List.filterMap
                    (\( root, result ) ->
                        case result of
                            Ok source ->
                                Just ( root, source )

                            Err _ ->
                                Nothing
                    )
    in
    if List.length loaded == List.length pianoSampleUrls then
        Just loaded

    else
        Nothing


noteAudio : List ( Int, Audio.Source ) -> Time.Posix -> Midi.PlaybackNote -> Audio
noteAudio samples startTime note =
    case List.sortBy (\( root, _ ) -> abs (root - note.note)) samples of
        ( root, source ) :: _ ->
            let
                start =
                    addMillis (round (note.start * 1000)) startTime

                -- give staccato notes a little room to sound
                noteEnd =
                    addMillis (round ((note.start + max 0.06 note.duration) * 1000)) startTime

                volume =
                    toFloat note.velocity / 127

                config =
                    Audio.audioDefaultConfig
            in
            Audio.audioWithConfig
                { config | playbackRate = 2 ^ (toFloat (note.note - root) / 12) }
                source
                start
                -- hold the note at its velocity, then release over 100ms
                |> Audio.scaleVolumeAt
                    [ ( start, volume )
                    , ( noteEnd, volume )
                    , ( addMillis 100 noteEnd, 0 )
                    ]

        [] ->
            Audio.silence


addMillis : Int -> Time.Posix -> Time.Posix
addMillis millis time =
    Time.millisToPosix (Time.posixToMillis time + millis)



-- VIEW


view : AudioData -> FrontendModel_ -> Browser.Document FrontendMsg_
view _ model =
    { title = "MIDI parser & renderer"
    , body = [ viewPage model ]
    }


viewPage : FrontendModel_ -> Html FrontendMsg_
viewPage model =
    Html.div
        [ Html.Attributes.style "font-family" "system-ui, sans-serif"
        , Html.Attributes.style "margin" "0 auto"
        , Html.Attributes.style "padding" "24px 16px 64px 16px"
        , Html.Attributes.style "color" "#1c2733"
        , Html.Attributes.style "background-color" "white"
        ]
        [ Html.div
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "align-items" "baseline"
            , Html.Attributes.style "gap" "16px"
            , Html.Attributes.style "flex-wrap" "wrap"
            ]
            [ Html.h1
                [ Html.Attributes.style "margin" "0" ]
                [ Html.text "MIDI parser & renderer" ]
            , Html.button
                [ Html.Events.onClick MidiFileRequested
                , Html.Attributes.style "font-size" "15px"
                , Html.Attributes.style "padding" "6px 14px"
                , Html.Attributes.style "cursor" "pointer"
                ]
                [ Html.text "Open MIDI file…" ]
            , playbackButton model
            , Html.span
                [ Html.Attributes.style "color" "#5b6b7b" ]
                [ Html.text
                    (case model.source of
                        Demo ->
                            "showing the built-in demo recording"

                        FromFile name ->
                            name
                    )
                ]
            ]
        , case model.recording of
            Err message ->
                Html.div
                    [ Html.Attributes.style "margin-top" "24px"
                    , Html.Attributes.style "padding" "12px 16px"
                    , Html.Attributes.style "background" "#fdeaea"
                    , Html.Attributes.style "border" "1px solid #e5b4b4"
                    , Html.Attributes.style "border-radius" "6px"
                    ]
                    [ Html.text message ]

            Ok recording ->
                Midi.viewRecording recording
        ]


playbackButton : FrontendModel_ -> Html FrontendMsg_
playbackButton model =
    let
        button msg label =
            Html.button
                [ Html.Events.onClick msg
                , Html.Attributes.style "font-size" "15px"
                , Html.Attributes.style "padding" "6px 14px"
                , Html.Attributes.style "cursor" "pointer"
                ]
                [ Html.text label ]

        anySampleFailed =
            Dict.values model.pianoSamples
                |> List.any
                    (\result ->
                        case result of
                            Err _ ->
                                True

                            Ok _ ->
                                False
                    )
    in
    case model.recording of
        Err _ ->
            Html.text ""

        Ok _ ->
            case model.playbackStart of
                Just _ ->
                    button PressedStop "⏹ Stop"

                Nothing ->
                    if loadedPianoSamples model.pianoSamples /= Nothing then
                        button PressedPlay "▶ Play"

                    else if anySampleFailed then
                        Html.span
                            [ Html.Attributes.style "color" "#b4494f" ]
                            [ Html.text "couldn't load the piano sound" ]

                    else
                        Html.span
                            [ Html.Attributes.style "color" "#5b6b7b" ]
                            [ Html.text "loading piano sound…" ]
