module Frontend exposing (app)

import Browser exposing (UrlRequest(..))
import Browser.Navigation
import File
import File.Select
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Lamdera
import Midi
import Task
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
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \_ -> Sub.none
        , view = view
        }


init : Url.Url -> Browser.Navigation.Key -> ( FrontendModel, Cmd FrontendMsg )
init _ key =
    ( { key = key
      , source = Demo
      , recording = Ok Midi.demoRecording
      }
    , Cmd.none
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Browser.Navigation.pushUrl model.key (Url.toString url) )

                External url ->
                    ( model, Browser.Navigation.load url )

        UrlChanged _ ->
            ( model, Cmd.none )

        MidiFileRequested ->
            ( model, File.Select.file [ "audio/midi", "audio/x-midi", ".mid", ".midi" ] MidiFileSelected )

        MidiFileSelected file ->
            ( model, Task.perform (MidiFileLoaded (File.name file)) (File.toBytes file) )

        MidiFileLoaded name bytes ->
            ( { model | source = FromFile name, recording = Midi.fromBytes bytes }, Cmd.none )


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "MIDI parser & renderer"
    , body = [ viewPage model ]
    }


viewPage : FrontendModel -> Html FrontendMsg
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
