module TestViewer exposing (..)

import AssocList as Dict
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Colors
import Dict as RegularDict
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Html exposing (Html)
import Id exposing (ClientId)
import Json.Decode
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import List.Zipper exposing (Zipper)
import TestFramework as TF exposing (Instructions)
import Tests
import Ui
import Url exposing (Url)


type Msg
    = PressedNext
    | PressedPrevious
    | PressedRestart
    | PressedClientId ClientId
    | NoOp
    | UrlChanged Url
    | LinkClicked UrlRequest
    | TimelineSliderChanged Int


type alias Model =
    { steps : Zipper ( String, TF.State )
    , clientId : Maybe ClientId
    }


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init _ _ _ =
    let
        (Nonempty head rest) =
            TF.flatten Tests.createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt |> List.Nonempty.reverse
    in
    ( { steps = List.Zipper.from [] head rest
      , clientId = Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PressedNext ->
            case List.Zipper.next model.steps of
                Just newSteps ->
                    ( { model
                        | steps = newSteps
                        , clientId =
                            case model.clientId of
                                Just _ ->
                                    model.clientId

                                Nothing ->
                                    List.Zipper.current newSteps
                                        |> Tuple.second
                                        |> .frontends
                                        |> Dict.keys
                                        |> List.sortBy Id.clientIdToString
                                        |> List.head
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        PressedPrevious ->
            ( { model | steps = List.Zipper.previous model.steps |> Maybe.withDefault model.steps }, Cmd.none )

        PressedRestart ->
            ( { model | steps = List.Zipper.first model.steps }, Cmd.none )

        PressedClientId clientId ->
            ( { model | clientId = Just clientId }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        UrlChanged url ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            ( model, Cmd.none )

        TimelineSliderChanged index ->
            let
                steps =
                    List.Zipper.toList model.steps
            in
            case List.getAt index steps of
                Just indexValue ->
                    ( { model
                        | steps =
                            List.Zipper.from
                                (List.take index steps)
                                indexValue
                                (List.drop (1 + index) steps)
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )


viewFrontend model =
    TF.frontendApp.view model
        |> .body
        |> Html.div []
        |> Html.map (\_ -> NoOp)


view : Model -> Document Msg
view model =
    let
        currentStep =
            List.Zipper.current model.steps |> Tuple.second
    in
    { title = "Test framework viewer"
    , body =
        [ Element.layout
            [ Element.Font.size 16 ]
            (Element.column
                [ Element.width Element.fill, Element.height Element.fill ]
                [ controlsView model
                , Ui.horizontalLine
                , case currentStep.testErrors of
                    [] ->
                        case model.clientId of
                            Just clientId ->
                                case Dict.get clientId currentStep.frontends of
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
    let
        currentStep =
            List.Zipper.current model.steps |> Tuple.second

        nextStepName =
            List.Zipper.next model.steps |> Maybe.map (List.Zipper.current >> Tuple.first)

        currentIndex =
            List.Zipper.before model.steps |> List.length

        timelineLength =
            List.Zipper.toList model.steps |> List.length |> (+) -1
    in
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
                [ Element.Input.slider
                    [ Element.width (Element.px 200)
                    , Element.behindContent <|
                        Element.el
                            [ Element.Background.color Colors.darkGrey
                            , Element.width Element.fill
                            , Element.height (Element.px 10)
                            , Element.centerY
                            ]
                            Element.none
                    ]
                    { onChange = round >> TimelineSliderChanged
                    , label = Element.Input.labelHidden "Timeline slider"
                    , min = 0
                    , max = toFloat timelineLength
                    , value = toFloat currentIndex
                    , thumb = Element.Input.defaultThumb
                    , step = Just 1
                    }
                , String.fromInt currentIndex
                    ++ "/"
                    ++ String.fromInt timelineLength
                    |> Element.text
                , nextButton (nextStepName |> Maybe.withDefault "No steps remaining")
                , previousButton
                , restartButton
                ]
            , currentStep.frontends
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
    Html.pre
        []
        [ Html.text error ]
        |> Element.html
        |> Element.el []


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


nextButton : String -> Element Msg
nextButton nextName =
    Element.Input.button
        buttonStyle
        { onPress = Just PressedNext
        , label = Element.text nextName
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
