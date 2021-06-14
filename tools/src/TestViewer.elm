module TestViewer exposing (..)

import AssocList as Dict
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import DebugToJson
import Dict as RegularDict
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Html exposing (Html)
import Html.Attributes
import Id exposing (ClientId)
import Json.Decode
import Json.Encode
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
        [ Element.layout
            [ Element.Font.size 16 ]
            (Element.column
                [ Element.width Element.fill, Element.height Element.fill ]
                [ controlsView model
                , case model.state.testErrors of
                    [] ->
                        case model.clientId of
                            Just clientId ->
                                case Dict.get clientId model.state.frontends of
                                    Just frontend ->
                                        viewFrontend frontend.model
                                            |> Element.html
                                            |> Element.el
                                                [ Element.width Element.fill
                                                , Element.height Element.fill
                                                , Element.scrollbars
                                                ]

                                    Nothing ->
                                        Element.el
                                            [ Element.padding 8 ]
                                            (Element.text (Id.clientIdToString clientId ++ " hasn't connected yet"))

                            Nothing ->
                                Element.el
                                    [ Element.padding 8 ]
                                    (Element.text "No frontend found")

                    errors ->
                        Element.column
                            [ Element.Background.color <| Element.rgb255 255 218 218 ]
                            (List.map errorView errors)
                ]
            )
        ]
    }


controlsView : Model -> Element Msg
controlsView model =
    Element.row
        [ Element.Background.color <| Element.rgb 0.9 0.9 0.9
        , Element.width Element.fill
        ]
        [ Element.column
            [ Element.spacing 16
            , Element.padding 8
            , Element.width Element.fill
            , Element.alignTop
            ]
            [ Element.row
                [ Element.spacing 8, Element.width Element.fill ]
                [ nextButton
                , if List.isEmpty model.previousStates then
                    Element.none

                  else
                    previousButton
                , if model.inProgress == Done then
                    restartButton

                  else
                    Element.none
                ]
            , model.state.frontends
                |> Dict.keys
                |> List.sortBy Id.clientIdToString
                |> List.map (clientIdButton model.clientId)
                |> Element.row [ Element.spacing 8 ]
            ]

        --, model.state.backend
        --    |> Debug.toString
        --    |> Debug.log ""
        --    |> DebugToJson.toJson
        --    |> Debug.log ""
        --    |> Result.withDefault (Json.Encode.object [])
        --    |> Json.Decode.decodeValue (prettyPrintDecoder 0)
        --    |> Result.withDefault ""
        --    |> Html.text
        --    |> List.singleton
        --    |> Html.div [ Html.Attributes.style "white-space" "pre-wrap" ]
        --    |> Element.html
        --    |> Element.el [ Element.width Element.fill ]
        ]


prettyPrintDecoder : Int -> Json.Decode.Decoder String
prettyPrintDecoder depth =
    Json.Decode.oneOf
        [ Json.Decode.int |> Json.Decode.map String.fromInt
        , Json.Decode.float |> Json.Decode.map String.fromFloat
        , Json.Decode.string |> Json.Decode.map (\a -> "\"" ++ a ++ "\"")
        , Json.Decode.dict (Json.Decode.lazy (\() -> prettyPrintDecoder (depth + 1)))
            |> Json.Decode.map
                (\dict ->
                    let
                        offset =
                            String.repeat (4 * depth) " "
                    in
                    RegularDict.toList dict
                        |> List.map (\( field, value ) -> field ++ " : " ++ value)
                        |> String.join ("\n" ++ offset ++ ", ")
                        |> (\a -> "\n" ++ offset ++ "{ " ++ a ++ "\n" ++ offset ++ "}")
                )
        , Json.Decode.list (Json.Decode.lazy (\() -> prettyPrintDecoder (depth + 1)))
            |> Json.Decode.map (\list -> "[" ++ String.join "," list ++ "]")
        ]


errorView : String -> Element msg
errorView error =
    Element.paragraph
        []
        [ Element.text error ]


buttonStyle =
    [ Element.Background.color <| Element.rgb 0.8 0.8 0.8
    , Element.padding 8
    , Element.Border.rounded 4
    ]


restartButton : Element Msg
restartButton =
    Element.Input.button
        buttonStyle
        { onPress = Just PressedRestart, label = Element.text "Restart" }


nextButton : Element Msg
nextButton =
    Element.Input.button
        buttonStyle
        { onPress = Just PressedNext
        , label = Element.text "Next"
        }


previousButton : Element Msg
previousButton =
    Element.Input.button
        buttonStyle
        { onPress = Just PressedPrevious, label = Element.text "Previous" }


clientIdButton : Maybe ClientId -> ClientId -> Element Msg
clientIdButton currentClientId clientId =
    Element.Input.button
        [ Element.Background.color
            (if currentClientId == Just clientId then
                Element.rgb 1 1 1

             else
                Element.rgb 0.8 0.8 0.8
            )
        , Element.padding 8
        , Element.Border.rounded 4
        ]
        { onPress = Just (PressedClientId clientId)
        , label = Element.text (Id.clientIdToString clientId)
        }


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
