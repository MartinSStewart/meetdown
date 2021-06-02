module TestFramework exposing (..)

import AssocList as Dict exposing (Dict)
import Backend
import BackendEffects exposing (BackendEffect)
import BackendSub exposing (BackendSub)
import Basics.Extra as Basics
import Duration exposing (Duration)
import Env
import Expect exposing (Expectation)
import Frontend
import FrontendEffects exposing (FrontendEffect)
import FrontendSub exposing (FrontendSub)
import Id exposing (ClientId, SessionId)
import Quantity
import Time
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, NavigationKey(..), ToBackend, ToFrontend)
import Url exposing (Url)


unsafeUrl : String -> Url
unsafeUrl urlText =
    case Url.fromString urlText of
        Just url ->
            url

        Nothing ->
            Debug.todo ("Invalid url " ++ urlText)


type alias State =
    { backend : BackendModel
    , pendingEffects : BackendEffect
    , frontends : Dict ClientId FrontendState
    , counter : Int
    , elapsedTime : Duration
    , toBackend : List ( SessionId, ClientId, ToBackend )
    , timers : Dict Duration { msg : Time.Posix -> BackendMsg, startTime : Time.Posix }
    , testErrors : List String
    }


checkState : (State -> Maybe String) -> State -> State
checkState checkFunc state =
    case checkFunc state of
        Just error ->
            { state | testErrors = state.testErrors ++ [ error ] }

        Nothing ->
            state


finishSimulation : State -> Expectation
finishSimulation state =
    if List.isEmpty state.testErrors then
        Expect.pass

    else
        Expect.fail <| String.join "," state.testErrors


type alias FrontendState =
    { model : FrontendModel
    , sessionId : SessionId
    , pendingEffects : FrontendEffect
    , toFrontend : List ToFrontend
    , clipboard : String
    , timers : Dict Duration { msg : Time.Posix -> FrontendMsg, startTime : Time.Posix }
    , url : Url
    }


startTime =
    Time.millisToPosix 0


frontendApp =
    Frontend.createApp FrontendEffects.effects FrontendSub.subscriptions


backendApp =
    Backend.createApp BackendEffects.effects BackendSub.subscriptions


init : State
init =
    let
        ( backend, effects ) =
            backendApp.init
    in
    { backend = backend
    , pendingEffects = effects
    , frontends = Dict.empty
    , counter = 0
    , elapsedTime = Quantity.zero
    , toBackend = []
    , timers = getBackendTimers startTime (backendApp.subscriptions backend)
    , testErrors = []
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


connectFrontend : Url -> State -> ( State, ClientId )
connectFrontend url state =
    let
        clientId =
            "clientId " ++ String.fromInt state.counter |> Id.clientIdFromString

        sessionId =
            "sessionId " ++ String.fromInt (state.counter + 1) |> Id.sessionIdFromString

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
    in
    ( { state
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
        , counter = state.counter + 2
        , backend = backend
        , pendingEffects = backendEffects
      }
    , clientId
    )


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


runFrontendMsg : ClientId -> FrontendMsg -> State -> State
runFrontendMsg clientId frontendMsg state =
    let
        _ =
            if Dict.member clientId state.frontends then
                ()

            else
                Debug.todo "clientId not found in runFrontendMsg"
    in
    { state
        | frontends =
            Dict.update
                clientId
                (Maybe.map
                    (\frontend ->
                        let
                            ( model, effects ) =
                                frontendApp.update frontendMsg frontend.model
                        in
                        { frontend
                            | model = model
                            , pendingEffects = FrontendEffects.Batch [ frontend.pendingEffects, effects ]
                        }
                    )
                )
                state.frontends
    }


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
                (\_ frontend ->
                    let
                        ( newFrontendModel, newFrontendEffects ) =
                            getCompletedTimers frontend.timers
                                |> List.foldl
                                    (\( _, { msg } ) ( frontendModel, effects ) ->
                                        frontendApp.update
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


simulateTime : Duration -> State -> State
simulateTime duration state =
    if duration |> Quantity.lessThan Quantity.zero then
        state

    else
        simulateTime (duration |> Quantity.minus animationFrame) (simulateStep state)


fastForward : Duration -> State -> State
fastForward duration state =
    { state | elapsedTime = Quantity.plus state.elapsedTime duration }


runEffects : State -> State
runEffects state =
    let
        state2 =
            runBackendEffects state.pendingEffects (clearEffects state)

        state4 =
            Dict.foldl
                (\clientId frontend state3 ->
                    runFrontendEffects frontend.sessionId clientId frontend.pendingEffects state3
                )
                state2
                state.frontends
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
                        , pendingEffects = FrontendEffects.Batch [ frontend.pendingEffects, newEffects2 ]
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


clearEffects : State -> State
clearEffects state =
    { state
        | pendingEffects = BackendEffects.None
        , frontends = Dict.map (\_ frontend -> { frontend | pendingEffects = FrontendEffects.None }) state.frontends
    }


runFrontendEffects : SessionId -> ClientId -> FrontendEffect -> State -> State
runFrontendEffects sessionId clientId effect state =
    case effect of
        Batch_ effects ->
            List.foldl (runFrontendEffects sessionId clientId) state effects

        SendToBackend toBackend ->
            { state | toBackend = state.toBackend ++ [ ( sessionId, clientId, toBackend ) ] }

        PushUrl _ urlText ->
            handleUrlChange urlText clientId state

        ReplaceUrl _ urlText ->
            handleUrlChange urlText clientId state

        LoadUrl urlText ->
            handleUrlChange urlText clientId state

        FileDownload _ _ _ ->
            state

        CopyToClipboard text ->
            { state
                | frontends =
                    Dict.update clientId (Maybe.map (\frontend -> { frontend | clipboard = text })) state.frontends
            }

        ScrollToBottom _ ->
            state

        Blur _ ->
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
                            frontendApp.update (Types.UrlChanged url) frontend.model
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
        Batch_ effects ->
            List.concatMap flattenFrontendEffect effects

        _ ->
            [ effect ]


flattenBackendEffect : BackendEffect -> List BackendEffect
flattenBackendEffect effect =
    case effect of
        Batch effects ->
            List.concatMap flattenBackendEffect effects

        _ ->
            [ effect ]


runBackendEffects : BackendEffect -> State -> State
runBackendEffects effect state =
    case effect of
        Batch effects ->
            List.foldl runBackendEffects state effects

        SendToFrontend clientId toFrontend ->
            { state
                | frontends =
                    Dict.update
                        clientId
                        (Maybe.map (\frontend -> { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] }))
                        state.frontends
            }

        TimeNow msg ->
            let
                ( model, effects ) =
                    backendApp.update (msg (Duration.addTo startTime state.elapsedTime)) state.backend
            in
            { state | backend = model, pendingEffects = BackendEffects.Batch [ state.pendingEffects, effects ] }
