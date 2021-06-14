module TestViewer exposing (..)

import AssocList as Dict
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (ClientId)
import TestFramework as TF exposing (Replay(..))
import Tests
import Url exposing (Url)


type Msg
    = PressedNext
    | PressedPrevious
    | PressedRestart
    | PressedClientId ClientId
    | NoOp
    | UrlChanged Url
    | LinkClicked UrlRequest


type alias Model =
    { inProgress : TF.Replay
    , state : TF.State
    , previousStates : List ( TF.State, TF.Replay )
    , clientId : Maybe ClientId
    }


test =
    TF.toReplay Tests.createEventAndAnotherUserNotLoggedInJoinsIt


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init _ _ _ =
    let
        ( state, replay ) =
            test
    in
    ( { inProgress = replay, state = state, previousStates = [], clientId = Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PressedNext ->
            ( case model.inProgress |> Debug.log "" of
                NextStep_ nextStepFunc replay_ ->
                    let
                        newState =
                            nextStepFunc model.state
                    in
                    { model
                        | inProgress = replay_
                        , state = newState
                        , previousStates = ( model.state, model.inProgress ) :: model.previousStates
                        , clientId =
                            case model.clientId of
                                Just _ ->
                                    model.clientId

                                Nothing ->
                                    Dict.keys newState.frontends |> List.head
                    }

                AndThen_ andThenFunc replay ->
                    let
                        ( state, replay_ ) =
                            TF.toReplay (andThenFunc model.state)
                    in
                    { model
                        | inProgress = joinReplays replay_ replay
                        , state = state
                        , previousStates = ( model.state, model.inProgress ) :: model.previousStates
                        , clientId =
                            case model.clientId of
                                Just _ ->
                                    model.clientId

                                Nothing ->
                                    Dict.keys state.frontends |> List.sortBy Id.clientIdToString |> List.head
                    }

                Done ->
                    { model | inProgress = Done }
            , Cmd.none
            )

        PressedPrevious ->
            case model.previousStates of
                ( state, replay ) :: rest ->
                    ( { model | inProgress = replay, state = state, previousStates = rest }, Cmd.none )

                [] ->
                    ( model, Cmd.none )

        PressedRestart ->
            let
                ( state, replay ) =
                    test
            in
            ( { model | inProgress = replay, state = state }, Cmd.none )

        PressedClientId clientId ->
            ( { model | clientId = Just clientId }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        UrlChanged url ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            ( model, Cmd.none )


joinReplays : Replay -> Replay -> Replay
joinReplays first second =
    case first of
        Done ->
            second

        NextStep_ mapFunc replay_ ->
            NextStep_ mapFunc (joinReplays replay_ second)

        AndThen_ andThenFunc replay_ ->
            AndThen_ andThenFunc (joinReplays replay_ second)


viewFrontend model =
    TF.frontendApp.view model
        |> .body
        |> Html.div []
        |> Html.map (\_ -> NoOp)


view : Model -> Document Msg
view model =
    { title = "Test framework viewer"
    , body =
        [ Html.div
            [ Html.Attributes.style "width" "100%"
            , Html.Attributes.style "padding-bottom" "70px"
            ]
            [ case model.state.testErrors of
                [] ->
                    case model.clientId of
                        Just clientId ->
                            case Dict.get clientId model.state.frontends of
                                Just frontend ->
                                    viewFrontend frontend.model

                                Nothing ->
                                    Html.div
                                        [ Html.Attributes.style "padding" "8px" ]
                                        [ Html.text (Id.clientIdToString clientId ++ " hasn't connected yet") ]

                        Nothing ->
                            Html.div [ Html.Attributes.style "padding" "8px" ] [ Html.text "No frontend found" ]

                errors ->
                    Html.div
                        [ Html.Attributes.style "background-color" "#FFF1F1"
                        ]
                        (List.map errorView errors)
            ]
        , Html.div
            [ Html.Attributes.style "position" "fixed"
            , Html.Attributes.style "bottom" "0"
            , Html.Attributes.style "background-color" "#F1F1F1"
            , Html.Attributes.style "width" "100%"
            ]
            [ Html.div
                [ Html.Attributes.style "padding" "8px" ]
                [ nextButton
                , if List.isEmpty model.previousStates then
                    Html.text ""

                  else
                    previousButton
                , if model.inProgress == Done then
                    restartButton

                  else
                    Html.text ""
                ]
            , Html.div
                [ Html.Attributes.style "padding" "8px", Html.Attributes.style "height" "20px" ]
                (model.state.frontends
                    |> Dict.keys
                    |> List.sortBy Id.clientIdToString
                    |> List.map (clientIdButton model.clientId)
                )
            ]
        ]
    }


errorView : String -> Html msg
errorView error =
    Html.pre [ Html.Attributes.style "padding" "4px" ] [ Html.text error ]


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


previousButton : Html Msg
previousButton =
    Html.button
        [ Html.Events.onClick PressedPrevious ]
        [ Html.text "Previous" ]


clientIdButton : Maybe ClientId -> ClientId -> Html Msg
clientIdButton currentClientId clientId =
    Html.button
        [ Html.Events.onClick (PressedClientId clientId)
        , Html.Attributes.style "background-color"
            (if currentClientId == Just clientId then
                "#FFFFFF"

             else
                "#DDDDDD"
            )
        , Html.Attributes.style "margin-right" "4px"
        ]
        [ Html.text (Id.clientIdToString clientId) ]


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
