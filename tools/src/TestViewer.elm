module TestViewer exposing (..)

import AssocList as Dict
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Html exposing (Html)
import Html.Events
import TestFramework as TF exposing (Replay(..))
import Tests
import Url exposing (Url)


type Msg
    = PressedNext
    | PressedRestart
    | NoOp
    | UrlChanged Url
    | LinkClicked UrlRequest


type alias Model =
    { inProgress : TF.Replay
    , state : TF.State
    }


test =
    TF.toReplay Tests.createEventAndAnotherUserNotLoggedInJoinsIt


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init _ _ _ =
    let
        ( state, replay ) =
            test
    in
    ( { inProgress = replay, state = state }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PressedNext ->
            ( case model.inProgress of
                NextStep_ nextStepFunc replay_ ->
                    { model
                        | inProgress = replay_
                        , state = nextStepFunc model.state
                    }

                AndThen_ andThenFunc replay ->
                    let
                        ( state, replay_ ) =
                            TF.toReplay (andThenFunc model.state)
                    in
                    { model
                        | inProgress = replay_
                        , state = state
                    }

                Done ->
                    { model | inProgress = Done }
            , Cmd.none
            )

        PressedRestart ->
            let
                ( state, replay ) =
                    test
            in
            ( { inProgress = replay, state = state }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        UrlChanged url ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            ( model, Cmd.none )


view : Model -> Document Msg
view model =
    { title = "Test framework viewer"
    , body =
        [ case Dict.toList model.state.frontends of
            ( _, frontend ) :: _ ->
                TF.frontendApp.view frontend.model
                    |> .body
                    |> Html.div []
                    |> Html.map (\_ -> NoOp)

            [] ->
                Html.text "No frontend found"
        , if model.inProgress == Done then
            restartButton

          else
            nextButton
        ]
    }


restartButton : Html Msg
restartButton =
    Html.button
        [ Html.Events.onClick PressedRestart ]
        [ Html.text "Restart" ]


nextButton : Html Msg
nextButton =
    Html.button
        [ Html.Events.onClick PressedNext ]
        [ Html.text "Next" ]


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
