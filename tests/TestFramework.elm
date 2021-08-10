module TestFramework exposing
    ( BackendApp
    , EmailType(..)
    , Instructions
    , State
    , TestApp
    , andThen
    , checkBackend
    , checkFrontend
    , checkState
    , connectFrontend
    , continueWith
    , disconnectFrontend
    , fastForward
    , flatten
    , isDeleteAccountEmail
    , isEventReminderEmail
    , keyDownEvent
    , reconnectFrontend
    , runEffects
    , sendToBackend
    , simulateStep
    , simulateTime
    , startTime
    , testApp
    , toExpectation
    )

import AssocList as Dict exposing (Dict)
import BackendEffect exposing (BackendEffect)
import BackendSub exposing (BackendSub)
import Basics.Extra as Basics
import Browser exposing (UrlRequest(..))
import Date exposing (Date)
import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import Env
import Event exposing (EventType)
import Expect exposing (Expectation)
import FrontendEffect exposing (FrontendEffect)
import FrontendSub exposing (FrontendSub)
import Group exposing (EventId)
import GroupName exposing (GroupName)
import Html exposing (Html)
import Html.Attributes
import Id exposing (ButtonId(..), ClientId, DateInputId, DeleteUserToken, GroupId, HtmlId, Id, LoginToken, NumberInputId, RadioButtonId, SessionId, TextInputId, TimeInputId)
import Json.Encode
import List.Nonempty exposing (Nonempty)
import MockFile exposing (File(..))
import NavigationKey exposing (NavigationKey(..))
import Pixels
import Quantity
import Route exposing (Route)
import Test.Html.Event
import Test.Html.Query
import Test.Html.Selector
import Test.Runner
import Time
import Ui
import Url exposing (Url)


type alias State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { backend : backendModel
    , pendingEffects : BackendEffect toFrontend backendMsg
    , frontends : Dict ClientId (FrontendState toBackend frontendMsg frontendModel toFrontend)
    , counter : Int
    , elapsedTime : Duration
    , toBackend : List ( SessionId, ClientId, toBackend )
    , timers : Dict Duration { msg : Time.Posix -> backendMsg, startTime : Time.Posix }
    , testErrors : List String
    , emailInboxes : List ( EmailAddress, EmailType )
    }


type Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    = NextStep String (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel) (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    | AndThen (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel) (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    | Start (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)


type EmailType
    = LoginEmail Route (Id LoginToken) (Maybe ( Id GroupId, EventId ))
    | DeleteAccountEmail (Id DeleteUserToken)
    | EventReminderEmail (Id GroupId) GroupName Event.Event Time.Zone


isEventReminderEmail : EmailType -> Bool
isEventReminderEmail emailType =
    case emailType of
        EventReminderEmail _ _ _ _ ->
            True

        _ ->
            False


isDeleteAccountEmail : EmailType -> Bool
isDeleteAccountEmail emailType =
    case emailType of
        DeleteAccountEmail _ ->
            True

        _ ->
            False


checkState :
    (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Result String ())
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkState checkFunc =
    NextStep
        "Check state"
        (\state ->
            case checkFunc state of
                Ok () ->
                    state

                Err error ->
                    { state | testErrors = state.testErrors ++ [ error ] }
        )


checkBackend :
    (backendModel -> Result String ())
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkBackend checkFunc =
    NextStep
        "Check backend"
        (\state ->
            case checkFunc state.backend of
                Ok () ->
                    state

                Err error ->
                    { state | testErrors = state.testErrors ++ [ error ] }
        )


checkFrontend : ClientId -> (frontendModel -> Result String ()) -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkFrontend clientId checkFunc =
    NextStep
        "Check frontend"
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    case checkFunc frontend.model of
                        Ok () ->
                            state

                        Err error ->
                            { state | testErrors = state.testErrors ++ [ error ] }

                Nothing ->
                    { state
                        | testErrors =
                            state.testErrors ++ [ "ClientId \"" ++ Id.clientIdToString clientId ++ "\" not found." ]
                    }
        )


addTestError : String -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
addTestError error state =
    { state | testErrors = state.testErrors ++ [ error ] }


checkView :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> ClientId
    -> (Test.Html.Query.Single frontendMsg -> Expectation)
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkView frontendApp clientId query =
    NextStep
        "Check view"
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    case
                        frontendApp.view frontend.model
                            |> .body
                            |> Html.div []
                            |> Test.Html.Query.fromHtml
                            |> query
                            |> Test.Runner.getFailureReason
                    of
                        Just { description } ->
                            { state | testErrors = state.testErrors ++ [ description ] }

                        Nothing ->
                            state

                Nothing ->
                    { state
                        | testErrors =
                            state.testErrors ++ [ "ClientId \"" ++ Id.clientIdToString clientId ++ "\" not found." ]
                    }
        )


toExpectation : Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Expectation
toExpectation inProgress =
    let
        state =
            instructionsToState inProgress
    in
    if List.isEmpty state.testErrors then
        Expect.pass

    else
        Expect.fail <| String.join "," state.testErrors


flatten : Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Nonempty ( String, State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel )
flatten inProgress =
    case inProgress of
        NextStep name stepFunc inProgress_ ->
            let
                list =
                    flatten inProgress_

                previousState =
                    List.Nonempty.head list |> Tuple.second
            in
            List.Nonempty.cons ( name, stepFunc previousState ) list

        AndThen andThenFunc inProgress_ ->
            let
                list =
                    flatten inProgress_

                previousState =
                    List.Nonempty.head list |> Tuple.second
            in
            List.Nonempty.append (flatten (andThenFunc previousState)) list

        Start state ->
            List.Nonempty.fromElement ( "Start", state )


instructionsToState :
    Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
instructionsToState inProgress =
    case inProgress of
        NextStep _ stateFunc inProgress_ ->
            instructionsToState inProgress_ |> stateFunc

        AndThen stateFunc inProgress_ ->
            instructionsToState inProgress_ |> stateFunc |> instructionsToState

        Start state ->
            state


type alias FrontendState toBackend frontendMsg frontendModel toFrontend =
    { model : frontendModel
    , sessionId : SessionId
    , pendingEffects : FrontendEffect toBackend frontendMsg
    , toFrontend : List toFrontend
    , clipboard : String
    , timers : Dict Duration { msg : Time.Posix -> frontendMsg, startTime : Time.Posix }
    , url : Url
    }


startTime : Time.Posix
startTime =
    Time.millisToPosix 0


type alias FrontendApp toBackend frontendMsg frontendModel toFrontend =
    { init : Url -> NavigationKey -> ( frontendModel, FrontendEffect toBackend frontendMsg )
    , onUrlRequest : UrlRequest -> frontendMsg
    , onUrlChange : Url -> frontendMsg
    , update : frontendMsg -> frontendModel -> ( frontendModel, FrontendEffect toBackend frontendMsg )
    , updateFromBackend : toFrontend -> frontendModel -> ( frontendModel, FrontendEffect toBackend frontendMsg )
    , view : frontendModel -> Browser.Document frontendMsg
    , subscriptions : frontendModel -> FrontendSub frontendMsg
    }


type alias BackendApp toBackend toFrontend backendMsg backendModel =
    { init : ( backendModel, BackendEffect toFrontend backendMsg )
    , update : backendMsg -> backendModel -> ( backendModel, BackendEffect toFrontend backendMsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, BackendEffect toFrontend backendMsg )
    , subscriptions : backendModel -> BackendSub backendMsg
    }


type alias TestApp toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { init : Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , simulateTime : Duration -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , connectFrontend :
        SessionId
        -> Url
        -> (( Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, ClientId ) -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , clickButton : ClientId -> HtmlId ButtonId -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , clickRadioButton : ClientId -> HtmlId RadioButtonId -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , inputText : ClientId -> HtmlId TextInputId -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , inputNumber : ClientId -> HtmlId NumberInputId -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , inputDate : ClientId -> HtmlId DateInputId -> Date -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , inputTime : ClientId -> HtmlId TimeInputId -> Int -> Int -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , clickLink : ClientId -> Route -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , checkView : ClientId -> (Test.Html.Query.Single frontendMsg -> Expectation) -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    }


testApp :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> TestApp toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
testApp frontendApp backendApp =
    { init =
        let
            ( backend, effects ) =
                backendApp.init
        in
        Start
            { backend = backend
            , pendingEffects = effects
            , frontends = Dict.empty
            , counter = 0
            , elapsedTime = Quantity.zero
            , toBackend = []
            , timers = getBackendTimers startTime (backendApp.subscriptions backend)
            , testErrors = []
            , emailInboxes = []
            }
    , simulateTime = simulateTime frontendApp backendApp
    , connectFrontend = connectFrontend frontendApp backendApp
    , clickButton = clickButton frontendApp
    , clickRadioButton = clickRadioButton frontendApp
    , inputText = inputText frontendApp
    , inputNumber = inputNumber frontendApp
    , inputDate = inputDate frontendApp
    , inputTime = inputTime frontendApp
    , clickLink = clickLink frontendApp
    , checkView = checkView frontendApp
    }


getFrontendTimers : Time.Posix -> FrontendSub frontendMsg -> Dict Duration { msg : Time.Posix -> frontendMsg, startTime : Time.Posix }
getFrontendTimers currentTime frontendSub =
    case frontendSub of
        FrontendSub.Batch batch ->
            List.foldl (\sub dict -> Dict.union (getFrontendTimers currentTime sub) dict) Dict.empty batch

        FrontendSub.TimeEvery duration msg ->
            Dict.singleton duration { msg = msg, startTime = currentTime }

        _ ->
            Dict.empty


getBackendTimers :
    Time.Posix
    -> BackendSub backendMsg
    -> Dict Duration { msg : Time.Posix -> backendMsg, startTime : Time.Posix }
getBackendTimers currentTime backendSub =
    case backendSub of
        BackendSub.Batch batch ->
            List.foldl (\sub dict -> Dict.union (getBackendTimers currentTime sub) dict) Dict.empty batch

        BackendSub.TimeEvery duration msg ->
            Dict.singleton duration { msg = msg, startTime = currentTime }

        _ ->
            Dict.empty


getClientDisconnectSubs : BackendSub backendMsg -> List (SessionId -> ClientId -> backendMsg)
getClientDisconnectSubs backendSub =
    case backendSub of
        BackendSub.Batch batch ->
            List.foldl (\sub list -> getClientDisconnectSubs sub ++ list) [] batch

        BackendSub.OnDisconnect msg ->
            [ msg ]

        _ ->
            []


getClientConnectSubs : BackendSub backendMsg -> List (SessionId -> ClientId -> backendMsg)
getClientConnectSubs backendSub =
    case backendSub of
        BackendSub.Batch batch ->
            List.foldl (\sub list -> getClientConnectSubs sub ++ list) [] batch

        BackendSub.OnConnect msg ->
            [ msg ]

        _ ->
            []


connectFrontend :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> SessionId
    -> Url
    -> (( Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, ClientId ) -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
connectFrontend frontendApp backendApp sessionId url andThenFunc =
    AndThen
        (\state ->
            let
                clientId =
                    "clientId " ++ String.fromInt state.counter |> Id.clientIdFromString

                ( frontend, effects ) =
                    frontendApp.init url MockNavigationKey

                subscriptions =
                    frontendApp.subscriptions frontend

                ( backend, backendEffects ) =
                    getClientConnectSubs (backendApp.subscriptions state.backend)
                        |> List.foldl
                            (\msg ( newBackend, newEffects ) ->
                                backendApp.update (msg sessionId clientId) newBackend
                                    |> Tuple.mapSecond (\a -> BackendEffect.Batch [ newEffects, a ])
                            )
                            ( state.backend, state.pendingEffects )

                state2 : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
                state2 =
                    { state
                        | frontends =
                            Dict.insert
                                clientId
                                { model = frontend
                                , sessionId = sessionId
                                , pendingEffects = effects
                                , toFrontend = []
                                , clipboard = ""
                                , timers = getFrontendTimers (Duration.addTo startTime state.elapsedTime) subscriptions
                                , url = url
                                }
                                state.frontends
                        , counter = state.counter + 1
                        , backend = backend
                        , pendingEffects = backendEffects
                    }
            in
            andThenFunc
                ( Start state2 |> NextStep "Connect new frontend" identity
                , clientId
                )
        )


keyDownEvent : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> HtmlId any -> Int -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
keyDownEvent frontendApp clientId htmlId keyCode state =
    userEvent
        frontendApp
        ("Key down " ++ String.fromInt keyCode)
        clientId
        htmlId
        ( "keydown", Json.Encode.object [ ( "keyCode", Json.Encode.int keyCode ) ] )
        state


clickButton : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> HtmlId ButtonId -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clickButton frontendApp clientId htmlId state =
    userEvent frontendApp "Click button" clientId htmlId Test.Html.Event.click state


clickRadioButton : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> HtmlId RadioButtonId -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clickRadioButton frontendApp clientId htmlId state =
    userEvent frontendApp "Click radio button" clientId htmlId Test.Html.Event.click state


inputText : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> HtmlId TextInputId -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
inputText frontendApp clientId htmlId text state =
    userEvent frontendApp ("Input text \"" ++ text ++ "\"") clientId htmlId (Test.Html.Event.input text) state


inputNumber : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> HtmlId NumberInputId -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
inputNumber frontendApp clientId htmlId value state =
    userEvent frontendApp ("Input number " ++ value) clientId htmlId (Test.Html.Event.input value) state


inputDate : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> HtmlId DateInputId -> Date -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
inputDate frontendApp clientId htmlId date state =
    userEvent
        frontendApp
        ("Input date " ++ Ui.datestamp date)
        clientId
        htmlId
        (Test.Html.Event.input (Date.toIsoString date))
        state


inputTime : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> HtmlId TimeInputId -> Int -> Int -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
inputTime frontendApp clientId htmlId hour minute state =
    let
        input =
            Ui.timestamp hour minute
    in
    userEvent
        frontendApp
        ("Input time " ++ input)
        clientId
        htmlId
        (Test.Html.Event.input input)
        state


clickLink :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> ClientId
    -> Route
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clickLink frontendApp clientId route =
    let
        href : String
        href =
            Route.encode route
    in
    NextStep
        ("Click link " ++ href)
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    case
                        frontendApp.view frontend.model
                            |> .body
                            |> Html.div []
                            |> Test.Html.Query.fromHtml
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.href href) ]
                            |> Test.Html.Query.has []
                            |> Test.Runner.getFailureReason
                    of
                        Nothing ->
                            case Url.fromString (Env.domain ++ href) of
                                Just url ->
                                    let
                                        ( newModel, effects ) =
                                            frontendApp.update (frontendApp.onUrlRequest (Internal url)) frontend.model
                                    in
                                    { state
                                        | frontends =
                                            Dict.insert
                                                clientId
                                                { frontend | model = newModel, pendingEffects = effects }
                                                state.frontends
                                    }

                                Nothing ->
                                    addTestError ("Invalid url: " ++ Env.domain ++ href) state

                        Just err ->
                            addTestError
                                ("Clicking link failed for " ++ href ++ ": " ++ formatHtmlError err.description)
                                state

                Nothing ->
                    addTestError "ClientId not found" state
        )


userEvent :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> String
    -> ClientId
    -> HtmlId any
    -> ( String, Json.Encode.Value )
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
userEvent frontendApp name clientId htmlId event =
    NextStep
        (Id.clientIdToString clientId ++ ": " ++ name ++ " for " ++ Id.htmlIdToString htmlId)
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        query =
                            frontendApp.view frontend.model
                                |> .body
                                |> Html.div []
                                |> Test.Html.Query.fromHtml
                                |> Test.Html.Query.find [ Test.Html.Selector.id (Id.htmlIdToString htmlId) ]
                    in
                    case Test.Html.Event.simulate event query |> Test.Html.Event.toResult of
                        Ok msg ->
                            let
                                ( newModel, effects ) =
                                    frontendApp.update msg frontend.model
                            in
                            { state
                                | frontends =
                                    Dict.insert
                                        clientId
                                        { frontend | model = newModel, pendingEffects = effects }
                                        state.frontends
                            }

                        Err err ->
                            case Test.Runner.getFailureReason (Test.Html.Query.has [] query) of
                                Just { description } ->
                                    addTestError
                                        ("User event failed for " ++ Id.htmlIdToString htmlId ++ ": " ++ formatHtmlError description)
                                        state

                                Nothing ->
                                    addTestError
                                        ("User event failed for " ++ Id.htmlIdToString htmlId ++ ": " ++ err)
                                        state

                Nothing ->
                    addTestError "ClientId not found" state
        )


formatHtmlError : String -> String
formatHtmlError description =
    let
        stylesStart =
            String.indexes "<style>" description

        stylesEnd =
            String.indexes "</style>" description
    in
    List.map2 Tuple.pair stylesStart stylesEnd
        |> List.foldr
            (\( start, end ) text ->
                String.slice 0 (start + String.length "<style>") text
                    ++ "..."
                    ++ String.slice end (String.length text + 999) text
            )
            description


disconnectFrontend :
    BackendApp toBackend toFrontend backendMsg backendModel
    -> ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, FrontendState toBackend frontendMsg frontendModel toFrontend )
disconnectFrontend backendApp clientId state =
    case Dict.get clientId state.frontends of
        Just frontend ->
            let
                ( backend, effects ) =
                    getClientDisconnectSubs (backendApp.subscriptions state.backend)
                        |> List.foldl
                            (\msg ( newBackend, newEffects ) ->
                                backendApp.update (msg frontend.sessionId clientId) newBackend
                                    |> Tuple.mapSecond (\a -> BackendEffect.Batch [ newEffects, a ])
                            )
                            ( state.backend, state.pendingEffects )
            in
            ( { state | backend = backend, pendingEffects = effects, frontends = Dict.remove clientId state.frontends }, { frontend | toFrontend = [] } )

        Nothing ->
            Debug.todo "Invalid clientId"


reconnectFrontend :
    BackendApp toBackend toFrontend backendMsg backendModel
    -> FrontendState toBackend frontendMsg frontendModel toFrontend
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, ClientId )
reconnectFrontend backendApp frontendState state =
    let
        clientId =
            "clientId " ++ String.fromInt state.counter |> Id.clientIdFromString

        ( backend, effects ) =
            getClientConnectSubs (backendApp.subscriptions state.backend)
                |> List.foldl
                    (\msg ( newBackend, newEffects ) ->
                        backendApp.update (msg frontendState.sessionId clientId) newBackend
                            |> Tuple.mapSecond (\a -> BackendEffect.Batch [ newEffects, a ])
                    )
                    ( state.backend, state.pendingEffects )
    in
    ( { state
        | frontends = Dict.insert clientId frontendState state.frontends
        , backend = backend
        , pendingEffects = effects
        , counter = state.counter + 1
      }
    , clientId
    )


sendToBackend : SessionId -> ClientId -> toBackend -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
sendToBackend sessionId clientId toBackend =
    NextStep "Send to backend"
        (\state ->
            { state | toBackend = state.toBackend ++ [ ( sessionId, clientId, toBackend ) ] }
        )


animationFrame =
    Duration.seconds (1 / 60)


simulateStep :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
simulateStep frontendApp backendApp state =
    let
        newTime =
            Quantity.plus state.elapsedTime animationFrame

        getCompletedTimers : Dict Duration { a | startTime : Time.Posix } -> List ( Duration, { a | startTime : Time.Posix } )
        getCompletedTimers timers =
            Dict.toList timers
                |> List.filter
                    (\( duration, value ) ->
                        let
                            offset : Duration
                            offset =
                                Duration.from startTime value.startTime

                            timerLength : Float
                            timerLength =
                                Duration.inMilliseconds duration
                        in
                        Basics.fractionalModBy timerLength (state.elapsedTime |> Quantity.minus offset |> Duration.inMilliseconds)
                            > Basics.fractionalModBy timerLength (newTime |> Quantity.minus offset |> Duration.inMilliseconds)
                    )

        ( newBackend, newBackendEffects ) =
            getCompletedTimers state.timers
                |> List.foldl
                    (\( _, { msg } ) ( backend, effects ) ->
                        backendApp.update
                            (msg (Duration.addTo startTime newTime))
                            backend
                            |> Tuple.mapSecond (\a -> BackendEffect.Batch [ effects, a ])
                    )
                    ( state.backend, state.pendingEffects )
    in
    { state
        | elapsedTime = newTime
        , pendingEffects = newBackendEffects
        , backend = newBackend
        , frontends =
            Dict.map
                (\clientId frontend ->
                    let
                        ( newFrontendModel, newFrontendEffects ) =
                            getCompletedTimers frontend.timers
                                |> List.foldl
                                    (\( _, { msg } ) ( frontendModel, effects ) ->
                                        --let
                                        --    _ =
                                        --        Debug.log "timer completed" ""
                                        --in
                                        frontendApp.update
                                            (msg (Duration.addTo startTime newTime))
                                            frontendModel
                                            |> Tuple.mapSecond (\a -> FrontendEffect.Batch [ effects, a ])
                                    )
                                    ( frontend.model, frontend.pendingEffects )
                    in
                    { frontend | pendingEffects = newFrontendEffects, model = newFrontendModel }
                )
                state.frontends
    }
        |> runEffects frontendApp backendApp


simulateTime :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> Duration
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
simulateTime frontendApp backendApp duration =
    NextStep
        ("Simulate time " ++ String.fromFloat (Duration.inSeconds duration) ++ "s")
        (simulateTimeHelper frontendApp backendApp duration)


simulateTimeHelper :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> Duration
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
simulateTimeHelper frontendApp backendApp duration state =
    if duration |> Quantity.lessThan Quantity.zero then
        state

    else
        simulateTimeHelper frontendApp backendApp (duration |> Quantity.minus animationFrame) (simulateStep frontendApp backendApp state)


fastForward :
    Duration
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
fastForward duration =
    NextStep
        ("Fast forward " ++ String.fromFloat (Duration.inSeconds duration) ++ "s")
        (\state -> { state | elapsedTime = Quantity.plus state.elapsedTime duration })


andThen :
    (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
andThen =
    AndThen


continueWith : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
continueWith state =
    Start state


runEffects :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runEffects frontendApp backendApp state =
    let
        state2 =
            runBackendEffects backendApp state.pendingEffects (clearBackendEffects state)

        state4 =
            Dict.foldl
                (\clientId { sessionId, pendingEffects } state3 ->
                    runFrontendEffects
                        frontendApp
                        sessionId
                        clientId
                        pendingEffects
                        (clearFrontendEffects clientId state3)
                )
                state2
                state2.frontends
    in
    { state4
        | pendingEffects = flattenBackendEffect state4.pendingEffects |> BackendEffect.Batch
        , frontends =
            Dict.map
                (\_ frontend ->
                    { frontend | pendingEffects = flattenFrontendEffect frontend.pendingEffects |> FrontendEffect.Batch }
                )
                state4.frontends
    }
        |> runNetwork frontendApp backendApp


runNetwork :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runNetwork frontendApp backendApp state =
    let
        ( backendModel, effects ) =
            List.foldl
                (\( sessionId, clientId, toBackendMsg ) ( model, effects2 ) ->
                    --let
                    --    _ =
                    --        Debug.log "updateFromFrontend" ( clientId, toBackendMsg )
                    --in
                    backendApp.updateFromFrontend sessionId clientId toBackendMsg model
                        |> Tuple.mapSecond (\a -> BackendEffect.Batch [ effects2, a ])
                )
                ( state.backend, state.pendingEffects )
                state.toBackend

        frontends =
            Dict.map
                (\clientId frontend ->
                    let
                        ( newModel, newEffects2 ) =
                            List.foldl
                                (\msg ( model, newEffects ) ->
                                    --let
                                    --    _ =
                                    --        Debug.log "Frontend.updateFromBackend" ( clientId, msg )
                                    --in
                                    frontendApp.updateFromBackend msg model
                                        |> Tuple.mapSecond (\a -> FrontendEffect.Batch [ newEffects, a ])
                                )
                                ( frontend.model, frontend.pendingEffects )
                                frontend.toFrontend
                    in
                    { frontend
                        | model = newModel
                        , pendingEffects = newEffects2
                        , toFrontend = []
                    }
                )
                state.frontends
    in
    { state
        | toBackend = []
        , backend = backendModel
        , pendingEffects = flattenBackendEffect effects |> BackendEffect.Batch
        , frontends = frontends
    }


clearBackendEffects :
    State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clearBackendEffects state =
    { state | pendingEffects = BackendEffect.None }


clearFrontendEffects :
    ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clearFrontendEffects clientId state =
    { state
        | frontends =
            Dict.update
                clientId
                (Maybe.map (\frontend -> { frontend | pendingEffects = FrontendEffect.None }))
                state.frontends
    }


runFrontendEffects :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> SessionId
    -> ClientId
    -> FrontendEffect toBackend frontendMsg
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runFrontendEffects frontendApp sessionId clientId effectsToPerform state =
    case effectsToPerform of
        FrontendEffect.Batch nestedEffectsToPerform ->
            List.foldl (runFrontendEffects frontendApp sessionId clientId) state nestedEffectsToPerform

        FrontendEffect.SendToBackend toBackend ->
            { state | toBackend = state.toBackend ++ [ ( sessionId, clientId, toBackend ) ] }

        FrontendEffect.NavigationPushUrl _ urlText ->
            handleUrlChange frontendApp urlText clientId state

        FrontendEffect.NavigationReplaceUrl _ urlText ->
            handleUrlChange frontendApp urlText clientId state

        FrontendEffect.NavigationLoad urlText ->
            handleUrlChange frontendApp urlText clientId state

        FrontendEffect.None ->
            state

        FrontendEffect.GetTime msg ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        ( model, effects ) =
                            frontendApp.update (msg (Duration.addTo startTime state.elapsedTime)) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = FrontendEffect.Batch [ frontend.pendingEffects, effects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        FrontendEffect.Wait duration msg ->
            state

        FrontendEffect.SelectFile mimeTypes msg ->
            state

        FrontendEffect.CopyToClipboard text ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    { state | frontends = Dict.insert clientId { frontend | clipboard = text } state.frontends }

                Nothing ->
                    state

        FrontendEffect.CropImage cropImageData ->
            state

        FrontendEffect.FileToUrl msg file ->
            case file of
                MockFile fileName ->
                    case Dict.get clientId state.frontends of
                        Just frontend ->
                            let
                                fileContent =
                                    case fileName of
                                        "profile.png" ->
                                            "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9Ta0UqgnYQcchQnayIijhKFYtgobQVWnUwufRDaNKQpLg4Cq4FBz8Wqw4uzro6uAqC4AeIm5uToouU+L+k0CLGg+N+vLv3uHsHCPUyU82OcUDVLCMVj4nZ3IoYfEUn/OhDAGMSM/VEeiEDz/F1Dx9f76I8y/vcn6NHyZsM8InEs0w3LOJ14ulNS+e8TxxmJUkhPiceNeiCxI9cl11+41x0WOCZYSOTmiMOE4vFNpbbmJUMlXiKOKKoGuULWZcVzluc1XKVNe/JXxjKa8tprtMcQhyLSCAJETKq2EAZFqK0aqSYSNF+zMM/6PiT5JLJtQFGjnlUoEJy/OB/8LtbszA54SaFYkDgxbY/hoHgLtCo2fb3sW03TgD/M3CltfyVOjDzSXqtpUWOgN5t4OK6pcl7wOUOMPCkS4bkSH6aQqEAvJ/RN+WA/luge9XtrbmP0wcgQ10t3QAHh8BIkbLXPN7d1d7bv2ea/f0AT2FymQ2GVEYAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAHdElNRQflBgMSBgvJgnPPAAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAAAxJREFUCNdjmH36PwAEagJmf/sZfAAAAABJRU5ErkJggg=="

                                        _ ->
                                            "uninteresting file"

                                ( model, effects ) =
                                    frontendApp.update (msg fileContent) frontend.model
                            in
                            { state
                                | frontends =
                                    Dict.insert clientId
                                        { frontend
                                            | model = model
                                            , pendingEffects = FrontendEffect.Batch [ frontend.pendingEffects, effects ]
                                        }
                                        state.frontends
                            }

                        Nothing ->
                            state

                RealFile _ ->
                    state

        FrontendEffect.GetElement function string ->
            state

        FrontendEffect.GetWindowSize msg ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        ( model, effects ) =
                            frontendApp.update (msg (Pixels.pixels 1920) (Pixels.pixels 1080)) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = FrontendEffect.Batch [ frontend.pendingEffects, effects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        FrontendEffect.GetTimeZone msg ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        timezone =
                            Ok ( "utc", Time.utc )

                        ( model, effects ) =
                            frontendApp.update (msg timezone) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = FrontendEffect.Batch [ frontend.pendingEffects, effects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        FrontendEffect.ScrollToTop _ ->
            state


handleUrlChange :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> String
    -> ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleUrlChange frontendApp urlText clientId state =
    let
        urlText_ =
            if String.startsWith "/" urlText then
                Env.domain ++ urlText

            else
                urlText
    in
    case Url.fromString urlText_ of
        Just url ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        ( model, effects ) =
                            frontendApp.update (frontendApp.onUrlChange url) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = FrontendEffect.Batch [ frontend.pendingEffects, effects ]
                                    , url = url
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        Nothing ->
            state


flattenFrontendEffect : FrontendEffect toBackend frontendMsg -> List (FrontendEffect toBackend frontendMsg)
flattenFrontendEffect effect =
    case effect of
        FrontendEffect.Batch effects ->
            List.concatMap flattenFrontendEffect effects

        FrontendEffect.None ->
            []

        _ ->
            [ effect ]


flattenBackendEffect : BackendEffect toFrontend backendMsg -> List (BackendEffect toFrontend backendMsg)
flattenBackendEffect effect =
    case effect of
        BackendEffect.Batch effects ->
            List.concatMap flattenBackendEffect effects

        BackendEffect.None ->
            []

        _ ->
            [ effect ]


runBackendEffects :
    BackendApp toBackend toFrontend backendMsg backendModel
    -> BackendEffect toFrontend backendMsg
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runBackendEffects backendApp effect state =
    case effect of
        BackendEffect.Batch effects ->
            List.foldl (runBackendEffects backendApp) state effects

        BackendEffect.SendToFrontend clientId toFrontend ->
            { state
                | frontends =
                    Dict.update
                        clientId
                        (Maybe.map (\frontend -> { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] }))
                        state.frontends
            }

        BackendEffect.GetTime msg ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Duration.addTo startTime state.elapsedTime)) state.backend
            in
            { state | backend = model, pendingEffects = BackendEffect.Batch [ state.pendingEffects, effects ] }

        BackendEffect.None ->
            state

        BackendEffect.SendLoginEmail msg emailAddress route loginToken maybeJoinEvent ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Ok postmarkResponse)) state.backend
            in
            { state
                | backend = model
                , pendingEffects = BackendEffect.Batch [ state.pendingEffects, effects ]
                , emailInboxes = state.emailInboxes ++ [ ( emailAddress, LoginEmail route loginToken maybeJoinEvent ) ]
            }

        BackendEffect.SendDeleteUserEmail msg emailAddress deleteToken ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Ok postmarkResponse)) state.backend
            in
            { state
                | backend = model
                , pendingEffects = BackendEffect.Batch [ state.pendingEffects, effects ]
                , emailInboxes = state.emailInboxes ++ [ ( emailAddress, DeleteAccountEmail deleteToken ) ]
            }

        BackendEffect.SendEventReminderEmail msg groupId groupName event timezone emailAddress ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Ok postmarkResponse)) state.backend
            in
            { state
                | backend = model
                , pendingEffects = BackendEffect.Batch [ state.pendingEffects, effects ]
                , emailInboxes = state.emailInboxes ++ [ ( emailAddress, EventReminderEmail groupId groupName event timezone ) ]
            }

        BackendEffect.SendToFrontends clientIds toFrontend ->
            List.foldl
                (\clientId state_ ->
                    { state_
                        | frontends =
                            Dict.update
                                clientId
                                (Maybe.map (\frontend -> { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] }))
                                state_.frontends
                    }
                )
                state
                clientIds


postmarkResponse =
    { to = ""
    , submittedAt = ""
    , messageID = ""
    , errorCode = 0
    , message = ""
    }
