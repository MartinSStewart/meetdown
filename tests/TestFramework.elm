module TestFramework exposing
    ( EmailType(..)
    , Instructions
    , State
    , andThen
    , checkBackend
    , checkFrontend
    , checkLoadedFrontend
    , checkState
    , checkView
    , clickButton
    , clickLink
    , clickRadioButton
    , connectFrontend
    , continueWith
    , disconnectFrontend
    , fastForward
    , flatten
    , frontendApp
    , init
    , inputDate
    , inputNumber
    , inputText
    , inputTime
    , isDeleteAccountEmail
    , isEventReminderEmail
    , keyDownEvent
    , reconnectFrontend
    , runEffects
    , simulateStep
    , simulateTime
    , startTime
    , toExpectation
    )

import Array exposing (Array)
import AssocList as Dict exposing (Dict)
import BackendEffects exposing (BackendEffect)
import BackendLogic
import BackendSub exposing (BackendSub)
import Basics.Extra as Basics
import Browser exposing (UrlRequest(..))
import Date exposing (Date)
import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import Env
import Event exposing (EventType)
import Expect exposing (Expectation)
import FrontendEffects exposing (FrontendEffect)
import FrontendLogic
import FrontendSub exposing (FrontendSub)
import Group exposing (EventId)
import GroupName exposing (GroupName)
import Html exposing (Html)
import Html.Attributes
import Id exposing (ButtonId(..), ClientId, DateInputId, DeleteUserToken, GroupId, HtmlId, Id, LoginToken, NumberInputId, RadioButtonId, SessionId, TextInputId, TimeInputId)
import Json.Encode
import List.Nonempty exposing (Nonempty)
import MockFile exposing (File(..))
import Pixels
import Quantity
import Route exposing (Route)
import Test.Html.Event
import Test.Html.Query
import Test.Html.Selector
import Test.Runner
import Time
import Types exposing (BackendModel, BackendMsg, FrontendModel(..), FrontendMsg, LoadedFrontend, NavigationKey(..), ToBackend, ToFrontend)
import Ui
import Url exposing (Url)


type alias State =
    { backend : BackendModel
    , pendingEffects : BackendEffect
    , frontends : Dict ClientId FrontendState
    , counter : Int
    , elapsedTime : Duration
    , toBackend : List ( SessionId, ClientId, ToBackend )
    , timers : Dict Duration { msg : Time.Posix -> BackendMsg, startTime : Time.Posix }
    , testErrors : List String
    , emailInboxes : List ( EmailAddress, EmailType )
    }


type Instructions
    = NextStep String (State -> State) Instructions
    | AndThen (State -> Instructions) Instructions
    | Start State


type EmailType
    = LoginEmail Route (Id LoginToken) (Maybe ( GroupId, EventId ))
    | DeleteAccountEmail (Id DeleteUserToken)
    | EventReminderEmail GroupId GroupName Event.Event Time.Zone


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


checkState : (State -> Result String ()) -> Instructions -> Instructions
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


checkBackend : (BackendModel -> Result String ()) -> Instructions -> Instructions
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


checkFrontend : ClientId -> (FrontendModel -> Result String ()) -> Instructions -> Instructions
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


addTestError : String -> State -> State
addTestError error state =
    { state | testErrors = state.testErrors ++ [ error ] }


checkView : ClientId -> (Test.Html.Query.Single FrontendMsg -> Expectation) -> Instructions -> Instructions
checkView clientId query =
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


checkLoadedFrontend : ClientId -> (LoadedFrontend -> Result String ()) -> Instructions -> Instructions
checkLoadedFrontend clientId checkFunc state =
    checkFrontend
        clientId
        (\frontend ->
            case frontend of
                Loaded loaded ->
                    checkFunc loaded

                Loading _ ->
                    Err "Frontend is still loading"
        )
        state


toExpectation : Instructions -> Expectation
toExpectation inProgress =
    let
        state =
            instructionsToState inProgress
    in
    if List.isEmpty state.testErrors then
        Expect.pass

    else
        Expect.fail <| String.join "," state.testErrors


flatten : Instructions -> Nonempty ( String, State )
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


instructionsToState : Instructions -> State
instructionsToState inProgress =
    case inProgress of
        NextStep _ stateFunc inProgress_ ->
            instructionsToState inProgress_ |> stateFunc

        AndThen stateFunc inProgress_ ->
            instructionsToState inProgress_ |> stateFunc |> instructionsToState

        Start state ->
            state


type alias FrontendState =
    { model : FrontendModel
    , sessionId : SessionId
    , pendingEffects : FrontendEffect
    , toFrontend : List ToFrontend
    , clipboard : String
    , timers : Dict Duration { msg : Time.Posix -> FrontendMsg, startTime : Time.Posix }
    , url : Url
    }


startTime : Time.Posix
startTime =
    Time.millisToPosix 0


frontendApp =
    let
        app_ =
            FrontendLogic.createApp FrontendEffects.effects FrontendSub.subscriptions
    in
    { init = app_.init
    , update =
        \clientId msg model ->
            let
                ( newModel, effects ) =
                    app_.update msg model

                --_ =
                --    Debug.log "Frontend.update" ( Id.clientIdToString clientId, msg, effects )
            in
            ( newModel, effects )
    , updateFromBackend = app_.updateFromBackend
    , view = app_.view
    , subscriptions = app_.subscriptions
    }


backendApp =
    BackendLogic.createApp BackendEffects.effects BackendSub.subscriptions


init : Instructions
init =
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


getFrontendTimers : Time.Posix -> FrontendSub -> Dict Duration { msg : Time.Posix -> FrontendMsg, startTime : Time.Posix }
getFrontendTimers currentTime frontendSub =
    case frontendSub of
        FrontendSub.Batch batch ->
            List.foldl (\sub dict -> Dict.union (getFrontendTimers currentTime sub) dict) Dict.empty batch

        FrontendSub.TimeEvery duration msg ->
            Dict.singleton duration { msg = msg, startTime = currentTime }

        _ ->
            Dict.empty


getBackendTimers : Time.Posix -> BackendSub -> Dict Duration { msg : Time.Posix -> BackendMsg, startTime : Time.Posix }
getBackendTimers currentTime backendSub =
    case backendSub of
        BackendSub.Batch batch ->
            List.foldl (\sub dict -> Dict.union (getBackendTimers currentTime sub) dict) Dict.empty batch

        BackendSub.TimeEvery duration msg ->
            Dict.singleton duration { msg = msg, startTime = currentTime }

        _ ->
            Dict.empty


getClientDisconnectSubs : BackendSub -> List (SessionId -> ClientId -> BackendMsg)
getClientDisconnectSubs backendSub =
    case backendSub of
        BackendSub.Batch batch ->
            List.foldl (\sub list -> getClientDisconnectSubs sub ++ list) [] batch

        BackendSub.OnDisconnect msg ->
            [ msg ]

        _ ->
            []


getClientConnectSubs : BackendSub -> List (SessionId -> ClientId -> BackendMsg)
getClientConnectSubs backendSub =
    case backendSub of
        BackendSub.Batch batch ->
            List.foldl (\sub list -> getClientConnectSubs sub ++ list) [] batch

        BackendSub.OnConnect msg ->
            [ msg ]

        _ ->
            []


connectFrontend : SessionId -> Url -> (( Instructions, ClientId ) -> Instructions) -> Instructions -> Instructions
connectFrontend sessionId url andThenFunc =
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
                                    |> Tuple.mapSecond (\a -> BackendEffects.Batch [ newEffects, a ])
                            )
                            ( state.backend, state.pendingEffects )

                state2 : State
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


keyDownEvent : ClientId -> HtmlId any -> Int -> Instructions -> Instructions
keyDownEvent clientId htmlId keyCode state =
    userEvent
        ("Key down " ++ String.fromInt keyCode)
        clientId
        htmlId
        ( "keydown", Json.Encode.object [ ( "keyCode", Json.Encode.int keyCode ) ] )
        state


clickButton : ClientId -> HtmlId ButtonId -> Instructions -> Instructions
clickButton clientId htmlId state =
    userEvent "Click button" clientId htmlId Test.Html.Event.click state


clickRadioButton : ClientId -> HtmlId RadioButtonId -> Instructions -> Instructions
clickRadioButton clientId htmlId state =
    userEvent "Click radio button" clientId htmlId Test.Html.Event.click state


inputText : ClientId -> HtmlId TextInputId -> String -> Instructions -> Instructions
inputText clientId htmlId text state =
    userEvent ("Input text \"" ++ text ++ "\"") clientId htmlId (Test.Html.Event.input text) state


inputNumber : ClientId -> HtmlId NumberInputId -> String -> Instructions -> Instructions
inputNumber clientId htmlId value state =
    userEvent ("Input number " ++ value) clientId htmlId (Test.Html.Event.input value) state


inputDate : ClientId -> HtmlId DateInputId -> Date -> Instructions -> Instructions
inputDate clientId htmlId date state =
    userEvent
        ("Input date " ++ Ui.datestamp date)
        clientId
        htmlId
        (Test.Html.Event.input (Date.toIsoString date))
        state


inputTime : ClientId -> HtmlId TimeInputId -> Int -> Int -> Instructions -> Instructions
inputTime clientId htmlId hour minute state =
    userEvent
        ("Input time " ++ String.fromInt hour ++ ":" ++ String.padLeft 2 '0' (String.fromInt minute))
        clientId
        htmlId
        (Test.Html.Event.input (String.fromInt hour ++ ":" ++ String.padLeft 2 '0' (String.fromInt minute)))
        state


clickLink : ClientId -> Route -> Instructions -> Instructions
clickLink clientId route =
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
                                            frontendApp.update clientId (Types.UrlClicked (Internal url)) frontend.model
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


userEvent : String -> ClientId -> HtmlId any -> ( String, Json.Encode.Value ) -> Instructions -> Instructions
userEvent name clientId htmlId event =
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
                                    frontendApp.update clientId msg frontend.model
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


disconnectFrontend : ClientId -> State -> ( State, FrontendState )
disconnectFrontend clientId state =
    case Dict.get clientId state.frontends of
        Just frontend ->
            let
                ( backend, effects ) =
                    getClientDisconnectSubs (backendApp.subscriptions state.backend)
                        |> List.foldl
                            (\msg ( newBackend, newEffects ) ->
                                backendApp.update (msg frontend.sessionId clientId) newBackend
                                    |> Tuple.mapSecond (\a -> BackendEffects.Batch [ newEffects, a ])
                            )
                            ( state.backend, state.pendingEffects )
            in
            ( { state | backend = backend, pendingEffects = effects, frontends = Dict.remove clientId state.frontends }, { frontend | toFrontend = [] } )

        Nothing ->
            Debug.todo "Invalid clientId"


reconnectFrontend : FrontendState -> State -> ( State, ClientId )
reconnectFrontend frontendState state =
    let
        clientId =
            "clientId " ++ String.fromInt state.counter |> Id.clientIdFromString

        ( backend, effects ) =
            getClientConnectSubs (backendApp.subscriptions state.backend)
                |> List.foldl
                    (\msg ( newBackend, newEffects ) ->
                        backendApp.update (msg frontendState.sessionId clientId) newBackend
                            |> Tuple.mapSecond (\a -> BackendEffects.Batch [ newEffects, a ])
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


animationFrame =
    Duration.seconds (1 / 60)


simulateStep : State -> State
simulateStep state =
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
                            |> Tuple.mapSecond (\a -> BackendEffects.Batch [ effects, a ])
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
                                            clientId
                                            (msg (Duration.addTo startTime newTime))
                                            frontendModel
                                            |> Tuple.mapSecond (\a -> FrontendEffects.Batch [ effects, a ])
                                    )
                                    ( frontend.model, frontend.pendingEffects )
                    in
                    { frontend | pendingEffects = newFrontendEffects, model = newFrontendModel }
                )
                state.frontends
    }
        |> runEffects


simulateTime : Duration -> Instructions -> Instructions
simulateTime duration =
    NextStep ("Simulate time " ++ String.fromFloat (Duration.inSeconds duration) ++ "s") (simulateTimeHelper duration)


simulateTimeHelper : Duration -> State -> State
simulateTimeHelper duration state =
    if duration |> Quantity.lessThan Quantity.zero then
        state

    else
        simulateTimeHelper (duration |> Quantity.minus animationFrame) (simulateStep state)


fastForward : Duration -> Instructions -> Instructions
fastForward duration =
    NextStep
        ("Fast forward " ++ String.fromFloat (Duration.inSeconds duration) ++ "s")
        (\state -> { state | elapsedTime = Quantity.plus state.elapsedTime duration })


andThen : (State -> Instructions) -> Instructions -> Instructions
andThen =
    AndThen


continueWith : State -> Instructions
continueWith state =
    Start state


runEffects : State -> State
runEffects state =
    let
        state2 =
            runBackendEffects state.pendingEffects (clearBackendEffects state)

        state4 =
            Dict.foldl
                (\clientId { sessionId, pendingEffects } state3 ->
                    runFrontendEffects
                        sessionId
                        clientId
                        pendingEffects
                        (clearFrontendEffects clientId state3)
                )
                state2
                state2.frontends
    in
    { state4
        | pendingEffects = flattenBackendEffect state4.pendingEffects |> BackendEffects.Batch
        , frontends =
            Dict.map
                (\_ frontend ->
                    { frontend | pendingEffects = flattenFrontendEffect frontend.pendingEffects |> FrontendEffects.Batch }
                )
                state4.frontends
    }
        |> runNetwork



--|> (\a ->
--        let
--            _ =
--                Debug.log "finish run effects" ()
--        in
--        a
--   )


runNetwork : State -> State
runNetwork state =
    let
        ( backendModel, effects ) =
            List.foldl
                (\( sessionId, clientId, toBackendMsg ) ( model, effects2 ) ->
                    --let
                    --    _ =
                    --        Debug.log "updateFromFrontend" ( clientId, toBackendMsg )
                    --in
                    backendApp.updateFromFrontend sessionId clientId toBackendMsg model
                        |> Tuple.mapSecond (\a -> BackendEffects.Batch [ effects2, a ])
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
                                        |> Tuple.mapSecond (\a -> FrontendEffects.Batch [ newEffects, a ])
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
        , pendingEffects = flattenBackendEffect effects |> BackendEffects.Batch
        , frontends = frontends
    }


clearBackendEffects : State -> State
clearBackendEffects state =
    { state | pendingEffects = BackendEffects.None }


clearFrontendEffects : ClientId -> State -> State
clearFrontendEffects clientId state =
    { state
        | frontends =
            Dict.update
                clientId
                (Maybe.map (\frontend -> { frontend | pendingEffects = FrontendEffects.None }))
                state.frontends
    }


runFrontendEffects : SessionId -> ClientId -> FrontendEffect -> State -> State
runFrontendEffects sessionId clientId effectsToPerform state =
    case effectsToPerform of
        FrontendEffects.Batch nestedEffectsToPerform ->
            List.foldl (runFrontendEffects sessionId clientId) state nestedEffectsToPerform

        FrontendEffects.SendToBackend toBackend ->
            { state | toBackend = state.toBackend ++ [ ( sessionId, clientId, toBackend ) ] }

        FrontendEffects.NavigationPushUrl _ urlText ->
            handleUrlChange urlText clientId state

        FrontendEffects.NavigationReplaceUrl _ urlText ->
            handleUrlChange urlText clientId state

        FrontendEffects.NavigationLoad urlText ->
            handleUrlChange urlText clientId state

        FrontendEffects.None ->
            state

        FrontendEffects.GetTime msg ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        ( model, effects ) =
                            frontendApp.update clientId (msg (Duration.addTo startTime state.elapsedTime)) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = FrontendEffects.Batch [ frontend.pendingEffects, effects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        FrontendEffects.Wait duration msg ->
            state

        FrontendEffects.SelectFile mimeTypes msg ->
            state

        FrontendEffects.CopyToClipboard text ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    { state | frontends = Dict.insert clientId { frontend | clipboard = text } state.frontends }

                Nothing ->
                    state

        FrontendEffects.CropImage cropImageData ->
            state

        FrontendEffects.FileToUrl msg file ->
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
                                    frontendApp.update clientId (msg fileContent) frontend.model
                            in
                            { state
                                | frontends =
                                    Dict.insert clientId
                                        { frontend
                                            | model = model
                                            , pendingEffects = FrontendEffects.Batch [ frontend.pendingEffects, effects ]
                                        }
                                        state.frontends
                            }

                        Nothing ->
                            state

                RealFile _ ->
                    state

        FrontendEffects.GetElement function string ->
            state

        FrontendEffects.GetWindowSize msg ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        ( model, effects ) =
                            frontendApp.update clientId (msg (Pixels.pixels 1920) (Pixels.pixels 1080)) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = FrontendEffects.Batch [ frontend.pendingEffects, effects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        FrontendEffects.GetTimeZone msg ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        timezone =
                            Ok ( "utc", Time.utc )

                        ( model, effects ) =
                            frontendApp.update clientId (msg timezone) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = FrontendEffects.Batch [ frontend.pendingEffects, effects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    state


handleUrlChange : String -> ClientId -> State -> State
handleUrlChange urlText clientId state =
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
                            frontendApp.update clientId (Types.UrlChanged url) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = FrontendEffects.Batch [ frontend.pendingEffects, effects ]
                                    , url = url
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        Nothing ->
            state


flattenFrontendEffect : FrontendEffect -> List FrontendEffect
flattenFrontendEffect effect =
    case effect of
        FrontendEffects.Batch effects ->
            List.concatMap flattenFrontendEffect effects

        FrontendEffects.None ->
            []

        _ ->
            [ effect ]


flattenBackendEffect : BackendEffect -> List BackendEffect
flattenBackendEffect effect =
    case effect of
        BackendEffects.Batch effects ->
            List.concatMap flattenBackendEffect effects

        BackendEffects.None ->
            []

        _ ->
            [ effect ]


runBackendEffects : BackendEffect -> State -> State
runBackendEffects effect state =
    case effect of
        BackendEffects.Batch effects ->
            List.foldl runBackendEffects state effects

        BackendEffects.SendToFrontend clientId toFrontend ->
            { state
                | frontends =
                    Dict.update
                        clientId
                        (Maybe.map (\frontend -> { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] }))
                        state.frontends
            }

        BackendEffects.GetTime msg ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Duration.addTo startTime state.elapsedTime)) state.backend
            in
            { state | backend = model, pendingEffects = BackendEffects.Batch [ state.pendingEffects, effects ] }

        BackendEffects.None ->
            state

        BackendEffects.SendLoginEmail msg emailAddress route loginToken maybeJoinEvent ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Ok ())) state.backend
            in
            { state
                | backend = model
                , pendingEffects = BackendEffects.Batch [ state.pendingEffects, effects ]
                , emailInboxes = state.emailInboxes ++ [ ( emailAddress, LoginEmail route loginToken maybeJoinEvent ) ]
            }

        BackendEffects.SendDeleteUserEmail msg emailAddress deleteToken ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Ok ())) state.backend
            in
            { state
                | backend = model
                , pendingEffects = BackendEffects.Batch [ state.pendingEffects, effects ]
                , emailInboxes = state.emailInboxes ++ [ ( emailAddress, DeleteAccountEmail deleteToken ) ]
            }

        BackendEffects.SendEventReminderEmail msg groupId groupName event timezone emailAddress ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Ok ())) state.backend
            in
            { state
                | backend = model
                , pendingEffects = BackendEffects.Batch [ state.pendingEffects, effects ]
                , emailInboxes = state.emailInboxes ++ [ ( emailAddress, EventReminderEmail groupId groupName event timezone ) ]
            }
