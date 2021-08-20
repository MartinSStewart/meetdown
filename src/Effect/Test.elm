module Effect.Test exposing
    ( BackendApp
    , BackendOnly
    , FrontendOnly
    , HttpRequest
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
    , reconnectFrontend
    , runEffects
    , sendToBackend
    , startTime
    , testApp
    , toExpectation
    )

import AssocList as Dict exposing (Dict)
import Basics.Extra as Basics
import Browser exposing (UrlRequest(..))
import Browser.Dom
import Bytes.Encode
import Duration exposing (Duration)
import Effect.Command exposing (Command, PortToJs)
import Effect.File as File
import Effect.Http exposing (HttpBody)
import Effect.Internal exposing (Command(..), File(..), NavigationKey(..), Task(..))
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription exposing (Subscription)
import Expect exposing (Expectation)
import Html exposing (Html)
import Html.Attributes
import Http
import Json.Decode
import Json.Encode
import List.Nonempty exposing (Nonempty)
import Quantity
import Test.Html.Event
import Test.Html.Query
import Test.Html.Selector
import Test.Runner
import Time
import Url exposing (Url)


type alias FrontendOnly =
    Effect.Internal.FrontendOnly


type alias BackendOnly =
    Effect.Internal.BackendOnly


type alias State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { backend : backendModel
    , pendingEffects : Command BackendOnly toFrontend backendMsg
    , frontends : Dict ClientId (FrontendState toBackend frontendMsg frontendModel toFrontend)
    , counter : Int
    , elapsedTime : Duration
    , toBackend : List ( SessionId, ClientId, toBackend )
    , timers : Dict Duration { msg : Time.Posix -> backendMsg, startTime : Time.Posix }
    , testErrors : List String
    , httpRequests : List HttpRequest
    , handleHttpRequest : { currentRequest : HttpRequest, httpRequests : List HttpRequest } -> Effect.Http.Response String
    , handlePortToJs :
        { currentRequest : PortToJs, portRequests : List PortToJs }
        -> Maybe ( String, Json.Decode.Value )
    , portRequests : List PortToJs
    , handleFileRequest : { mimeTypes : List String } -> Maybe File.File
    , domain : Url
    }


type alias HttpRequest =
    { method : String
    , url : String
    , body : HttpBody
    , headers : List ( String, String )
    }


type Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    = NextStep String (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel) (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    | AndThen (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel) (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    | Start (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)


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
                            state.testErrors ++ [ "ClientId \"" ++ Effect.Lamdera.clientIdToString clientId ++ "\" not found." ]
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
                            state.testErrors ++ [ "ClientId \"" ++ Effect.Lamdera.clientIdToString clientId ++ "\" not found." ]
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


flatten :
    Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Nonempty ( String, State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel )
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
    , pendingEffects : Command FrontendOnly toBackend frontendMsg
    , toFrontend : List toFrontend
    , clipboard : String
    , timers : Dict Duration { msg : Time.Posix -> frontendMsg, startTime : Time.Posix }
    , url : Url
    }


startTime : Time.Posix
startTime =
    Time.millisToPosix 0


type alias FrontendApp toBackend frontendMsg frontendModel toFrontend =
    { init : Url -> NavigationKey -> ( frontendModel, Command FrontendOnly toBackend frontendMsg )
    , onUrlRequest : UrlRequest -> frontendMsg
    , onUrlChange : Url -> frontendMsg
    , update : frontendMsg -> frontendModel -> ( frontendModel, Command FrontendOnly toBackend frontendMsg )
    , updateFromBackend : toFrontend -> frontendModel -> ( frontendModel, Command FrontendOnly toBackend frontendMsg )
    , view : frontendModel -> Browser.Document frontendMsg
    , subscriptions : frontendModel -> Subscription FrontendOnly frontendMsg
    }


type alias BackendApp toBackend toFrontend backendMsg backendModel =
    { init : ( backendModel, Command BackendOnly toFrontend backendMsg )
    , update : backendMsg -> backendModel -> ( backendModel, Command BackendOnly toFrontend backendMsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Command BackendOnly toFrontend backendMsg )
    , subscriptions : backendModel -> Subscription BackendOnly backendMsg
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
    , keyDownEvent : ClientId -> String -> Int -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , clickButton : ClientId -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , inputText : ClientId -> String -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , clickLink : ClientId -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , checkView : ClientId -> (Test.Html.Query.Single frontendMsg -> Expectation) -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    }


testApp :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> ({ currentRequest : HttpRequest, httpRequests : List HttpRequest } -> Effect.Http.Response String)
    ->
        ({ currentRequest : PortToJs, portRequests : List PortToJs }
         -> Maybe ( String, Json.Decode.Value )
        )
    -> ({ mimeTypes : List String } -> Maybe { name : String, mimeType : String, content : String, lastModified : Time.Posix })
    -> Url
    -> TestApp toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
testApp frontendApp backendApp handleHttpRequest handlePortToJs handleFileRequest domain =
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
            , timers = getTimers startTime (backendApp.subscriptions backend)
            , testErrors = []
            , httpRequests = []
            , handleHttpRequest = handleHttpRequest
            , handlePortToJs = handlePortToJs
            , portRequests = []
            , handleFileRequest = handleFileRequest >> Maybe.map MockFile
            , domain = domain
            }
    , simulateTime = simulateTime frontendApp backendApp
    , connectFrontend = connectFrontend frontendApp backendApp
    , keyDownEvent = keyDownEvent frontendApp
    , clickButton = clickButton frontendApp
    , inputText = inputText frontendApp
    , clickLink = clickLink frontendApp
    , checkView = checkView frontendApp
    }


getTimers :
    Time.Posix
    -> Subscription restriction backendMsg
    -> Dict Duration { msg : Time.Posix -> backendMsg, startTime : Time.Posix }
getTimers currentTime backendSub =
    case backendSub of
        Effect.Internal.SubBatch batch ->
            List.foldl (\sub dict -> Dict.union (getTimers currentTime sub) dict) Dict.empty batch

        Effect.Internal.TimeEvery duration msg ->
            Dict.singleton duration { msg = msg, startTime = currentTime }

        Effect.Internal.OnAnimationFrame msg ->
            Dict.singleton (Duration.seconds (1 / 60)) { msg = msg, startTime = currentTime }

        _ ->
            Dict.empty


getClientDisconnectSubs : Effect.Internal.Subscription BackendOnly backendMsg -> List (SessionId -> ClientId -> backendMsg)
getClientDisconnectSubs backendSub =
    case backendSub of
        Effect.Internal.SubBatch batch ->
            List.foldl (\sub list -> getClientDisconnectSubs sub ++ list) [] batch

        Effect.Internal.OnDisconnect msg ->
            [ \sessionId clientId ->
                msg
                    (Effect.Lamdera.sessionIdToString sessionId |> Effect.Internal.SessionId)
                    (Effect.Lamdera.clientIdToString clientId |> Effect.Internal.ClientId)
            ]

        _ ->
            []


getClientConnectSubs : Effect.Internal.Subscription BackendOnly backendMsg -> List (SessionId -> ClientId -> backendMsg)
getClientConnectSubs backendSub =
    case backendSub of
        Effect.Internal.SubBatch batch ->
            List.foldl (\sub list -> getClientConnectSubs sub ++ list) [] batch

        Effect.Internal.OnConnect msg ->
            [ \sessionId clientId ->
                msg
                    (Effect.Lamdera.sessionIdToString sessionId |> Effect.Internal.SessionId)
                    (Effect.Lamdera.clientIdToString clientId |> Effect.Internal.ClientId)
            ]

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
                    "clientId " ++ String.fromInt state.counter |> Effect.Lamdera.clientIdFromString

                ( frontend, effects ) =
                    frontendApp.init url MockNavigationKey

                subscriptions =
                    frontendApp.subscriptions frontend

                ( backend, backendEffects ) =
                    getClientConnectSubs (backendApp.subscriptions state.backend)
                        |> List.foldl
                            (\msg ( newBackend, newEffects ) ->
                                backendApp.update (msg sessionId clientId) newBackend
                                    |> Tuple.mapSecond (\a -> Effect.Command.batch [ newEffects, a ])
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
                                , timers = getTimers (Duration.addTo startTime state.elapsedTime) subscriptions
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


keyDownEvent : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> String -> Int -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
keyDownEvent frontendApp clientId htmlId keyCode state =
    userEvent
        frontendApp
        ("Key down " ++ String.fromInt keyCode)
        clientId
        htmlId
        ( "keydown", Json.Encode.object [ ( "keyCode", Json.Encode.int keyCode ) ] )
        state


clickButton : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clickButton frontendApp clientId htmlId state =
    userEvent frontendApp "Click button" clientId htmlId Test.Html.Event.click state


inputText : FrontendApp toBackend frontendMsg frontendModel toFrontend -> ClientId -> String -> String -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
inputText frontendApp clientId htmlId text state =
    userEvent frontendApp ("Input text \"" ++ text ++ "\"") clientId htmlId (Test.Html.Event.input text) state


normalizeUrl : Url -> String -> String
normalizeUrl domainUrl path =
    if String.startsWith "/" path then
        let
            domain =
                Url.toString domainUrl
        in
        if String.endsWith "/" domain then
            String.dropRight 1 domain ++ path

        else
            domain ++ path

    else
        path


clickLink :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> ClientId
    -> String
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clickLink frontendApp clientId href =
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
                            case Url.fromString (normalizeUrl state.domain href) of
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
                                    addTestError ("Invalid url: " ++ href) state

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
    -> String
    -> ( String, Json.Encode.Value )
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
userEvent frontendApp name clientId htmlId event =
    NextStep
        (Effect.Lamdera.clientIdToString clientId ++ ": " ++ name ++ " for " ++ htmlId)
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        query =
                            frontendApp.view frontend.model
                                |> .body
                                |> Html.div []
                                |> Test.Html.Query.fromHtml
                                |> Test.Html.Query.find [ Test.Html.Selector.id htmlId ]
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
                                        ("User event failed for " ++ htmlId ++ ": " ++ formatHtmlError description)
                                        state

                                Nothing ->
                                    addTestError
                                        ("User event failed for " ++ htmlId ++ ": " ++ err)
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
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, Maybe (FrontendState toBackend frontendMsg frontendModel toFrontend) )
disconnectFrontend backendApp clientId state =
    case Dict.get clientId state.frontends of
        Just frontend ->
            let
                ( backend, effects ) =
                    getClientDisconnectSubs (backendApp.subscriptions state.backend)
                        |> List.foldl
                            (\msg ( newBackend, newEffects ) ->
                                backendApp.update (msg frontend.sessionId clientId) newBackend
                                    |> Tuple.mapSecond (\a -> Effect.Command.batch [ newEffects, a ])
                            )
                            ( state.backend, state.pendingEffects )
            in
            ( { state | backend = backend, pendingEffects = effects, frontends = Dict.remove clientId state.frontends }
            , Just { frontend | toFrontend = [] }
            )

        Nothing ->
            ( state, Nothing )


reconnectFrontend :
    BackendApp toBackend toFrontend backendMsg backendModel
    -> FrontendState toBackend frontendMsg frontendModel toFrontend
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, ClientId )
reconnectFrontend backendApp frontendState state =
    let
        clientId =
            "clientId " ++ String.fromInt state.counter |> Effect.Lamdera.clientIdFromString

        ( backend, effects ) =
            getClientConnectSubs (backendApp.subscriptions state.backend)
                |> List.foldl
                    (\msg ( newBackend, newEffects ) ->
                        backendApp.update (msg frontendState.sessionId clientId) newBackend
                            |> Tuple.mapSecond (\a -> Effect.Command.batch [ newEffects, a ])
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
                            |> Tuple.mapSecond (\a -> Effect.Command.batch [ effects, a ])
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
                                            |> Tuple.mapSecond (\a -> Effect.Command.batch [ effects, a ])
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
            runBackendEffects frontendApp backendApp state.pendingEffects (clearBackendEffects state)

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
        | pendingEffects = flattenEffects state4.pendingEffects |> Effect.Command.batch
        , frontends =
            Dict.map
                (\_ frontend ->
                    { frontend | pendingEffects = flattenEffects frontend.pendingEffects |> Effect.Command.batch }
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
                    backendApp.updateFromFrontend sessionId clientId toBackendMsg model
                        |> Tuple.mapSecond (\a -> Effect.Command.batch [ effects2, a ])
                )
                ( state.backend, state.pendingEffects )
                state.toBackend

        frontends =
            Dict.map
                (\_ frontend ->
                    let
                        ( newModel, newEffects2 ) =
                            List.foldl
                                (\msg ( model, newEffects ) ->
                                    frontendApp.updateFromBackend msg model
                                        |> Tuple.mapSecond (\a -> Effect.Command.batch [ newEffects, a ])
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
        , pendingEffects = flattenEffects effects |> Effect.Command.batch
        , frontends = frontends
    }


clearBackendEffects :
    State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clearBackendEffects state =
    { state | pendingEffects = Effect.Command.none }


clearFrontendEffects :
    ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clearFrontendEffects clientId state =
    { state
        | frontends =
            Dict.update
                clientId
                (Maybe.map (\frontend -> { frontend | pendingEffects = None }))
                state.frontends
    }


runFrontendEffects :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> SessionId
    -> ClientId
    -> Command FrontendOnly toBackend frontendMsg
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runFrontendEffects frontendApp sessionId clientId effectsToPerform state =
    case effectsToPerform of
        Batch nestedEffectsToPerform ->
            List.foldl (runFrontendEffects frontendApp sessionId clientId) state nestedEffectsToPerform

        SendToBackend toBackend ->
            { state | toBackend = state.toBackend ++ [ ( sessionId, clientId, toBackend ) ] }

        NavigationPushUrl _ urlText ->
            handleUrlChange frontendApp urlText clientId state

        NavigationReplaceUrl _ urlText ->
            handleUrlChange frontendApp urlText clientId state

        NavigationLoad urlText ->
            handleUrlChange frontendApp urlText clientId state

        NavigationBack navigationKey int ->
            Debug.todo ""

        NavigationForward navigationKey int ->
            Debug.todo ""

        NavigationReload ->
            Debug.todo ""

        NavigationReloadAndSkipCache ->
            Debug.todo ""

        None ->
            state

        Task task ->
            let
                ( newState, msg ) =
                    runTask (Just clientId) frontendApp state task
            in
            case Dict.get clientId newState.frontends of
                Just frontend ->
                    let
                        ( model, effects ) =
                            frontendApp.update msg frontend.model
                    in
                    { newState
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = Effect.Command.batch [ frontend.pendingEffects, effects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        Port portName _ value ->
            let
                portRequest =
                    { portName = portName, value = value }

                newState =
                    { state | portRequests = portRequest :: state.portRequests }
            in
            case
                newState.handlePortToJs
                    { currentRequest = portRequest
                    , portRequests = state.portRequests
                    }
            of
                Just ( responsePortName, responseValue ) ->
                    case Dict.get clientId state.frontends of
                        Just frontend ->
                            let
                                msgs : List (Json.Decode.Value -> frontendMsg)
                                msgs =
                                    frontendApp.subscriptions frontend.model
                                        |> getPortSubscriptions
                                        |> List.filterMap
                                            (\sub ->
                                                if sub.portName == responsePortName then
                                                    Just sub.msg

                                                else
                                                    Nothing
                                            )

                                ( model, effects ) =
                                    List.foldl
                                        (\msg ( model_, effects_ ) ->
                                            let
                                                ( newModel, newEffects ) =
                                                    frontendApp.update (msg responseValue) model_
                                            in
                                            ( newModel, Effect.Command.batch [ effects_, newEffects ] )
                                        )
                                        ( frontend.model, frontend.pendingEffects )
                                        msgs
                            in
                            { newState
                                | frontends =
                                    Dict.insert clientId
                                        { frontend | model = model, pendingEffects = effects }
                                        newState.frontends
                            }

                        Nothing ->
                            newState

                Nothing ->
                    newState

        SendToFrontend _ _ ->
            state

        FileDownloadUrl _ ->
            state

        FileDownloadString _ ->
            state

        FileDownloadBytes _ ->
            state

        FileSelectFile mimeTypes msg ->
            case state.handleFileRequest { mimeTypes = mimeTypes } of
                Just file ->
                    case Dict.get clientId state.frontends of
                        Just frontend ->
                            let
                                ( model, effects ) =
                                    frontendApp.update (msg file) frontend.model
                            in
                            { state
                                | frontends =
                                    Dict.insert clientId
                                        { frontend
                                            | model = model
                                            , pendingEffects = Effect.Command.batch [ frontend.pendingEffects, effects ]
                                        }
                                        state.frontends
                            }

                        Nothing ->
                            state

                Nothing ->
                    state

        FileSelectFiles strings function ->
            Debug.todo ""

        Broadcast _ ->
            state


getPortSubscriptions :
    Subscription FrontendOnly frontendMsg
    -> List { portName : String, msg : Json.Decode.Value -> frontendMsg }
getPortSubscriptions subscription =
    case subscription of
        Effect.Internal.SubBatch subscriptions ->
            List.concatMap getPortSubscriptions subscriptions

        Effect.Internal.SubPort portName _ msg ->
            [ { portName = portName, msg = msg } ]

        _ ->
            []


handleUrlChange :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> String
    -> ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleUrlChange frontendApp urlText clientId state =
    let
        urlText_ =
            normalizeUrl state.domain urlText
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
                                    , pendingEffects = Effect.Command.batch [ frontend.pendingEffects, effects ]
                                    , url = url
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        Nothing ->
            state


flattenEffects : Command restriction toBackend frontendMsg -> List (Command restriction toBackend frontendMsg)
flattenEffects effect =
    case effect of
        Batch effects ->
            List.concatMap flattenEffects effects

        None ->
            []

        _ ->
            [ effect ]


runBackendEffects :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> Command BackendOnly toFrontend backendMsg
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runBackendEffects frontendApp backendApp effect state =
    case effect of
        Batch effects ->
            List.foldl (runBackendEffects frontendApp backendApp) state effects

        SendToFrontend (Effect.Internal.ClientId clientId) toFrontend ->
            { state
                | frontends =
                    Dict.update
                        (Effect.Lamdera.clientIdFromString clientId)
                        (Maybe.map (\frontend -> { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] }))
                        state.frontends
            }

        None ->
            state

        Task task ->
            let
                ( newState, msg ) =
                    runTask Nothing frontendApp state task

                ( model, effects ) =
                    backendApp.update msg newState.backend
            in
            { newState
                | backend = model
                , pendingEffects = Effect.Command.batch [ newState.pendingEffects, effects ]
            }

        SendToBackend _ ->
            state

        NavigationPushUrl _ _ ->
            state

        NavigationReplaceUrl _ _ ->
            state

        NavigationLoad _ ->
            state

        NavigationBack _ _ ->
            state

        NavigationForward _ _ ->
            state

        NavigationReload ->
            state

        NavigationReloadAndSkipCache ->
            state

        Port _ _ _ ->
            state

        FileDownloadUrl _ ->
            state

        FileDownloadString _ ->
            state

        FileDownloadBytes _ ->
            state

        FileSelectFile _ _ ->
            state

        FileSelectFiles _ _ ->
            state

        Broadcast toFrontend ->
            { state
                | frontends =
                    Dict.map
                        (\_ frontend -> { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] })
                        state.frontends
            }


runTask :
    Maybe ClientId
    -> FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Task restriction x x
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, x )
runTask maybeClientId frontendApp state task =
    case task of
        Succeed value ->
            ( state, value )

        Fail value ->
            ( state, value )

        HttpTask httpRequest ->
            -- TODO: Implement actual delays to http requests
            let
                request : HttpRequest
                request =
                    { method = httpRequest.method
                    , url = httpRequest.url
                    , body = httpRequest.body
                    , headers = httpRequest.headers
                    }
            in
            state.handleHttpRequest { currentRequest = request, httpRequests = state.httpRequests }
                |> (\response ->
                        case response of
                            Effect.Http.BadUrl_ url ->
                                Http.BadUrl_ url

                            Effect.Http.Timeout_ ->
                                Http.Timeout_

                            Effect.Http.NetworkError_ ->
                                Http.NetworkError_

                            Effect.Http.BadStatus_ metadata body ->
                                Http.BadStatus_ metadata body

                            Effect.Http.GoodStatus_ metadata body ->
                                Http.GoodStatus_ metadata body
                   )
                |> httpRequest.onRequestComplete
                |> runTask maybeClientId frontendApp { state | httpRequests = request :: state.httpRequests }

        SleepTask _ function ->
            -- TODO: Implement actual delays in tasks
            runTask maybeClientId frontendApp state (function ())

        TimeNow gotTime ->
            gotTime (Duration.addTo startTime state.elapsedTime) |> runTask maybeClientId frontendApp state

        TimeHere gotTimeZone ->
            gotTimeZone Time.utc |> runTask maybeClientId frontendApp state

        TimeGetZoneName getTimeZoneName ->
            getTimeZoneName (Time.Offset 0) |> runTask maybeClientId frontendApp state

        GetViewport function ->
            function { scene = { width = 1920, height = 1080 }, viewport = { x = 0, y = 0, width = 1920, height = 1080 } }
                |> runTask maybeClientId frontendApp state

        SetViewport _ _ function ->
            function () |> runTask maybeClientId frontendApp state

        GetElement htmlId function ->
            getDomTask
                frontendApp
                maybeClientId
                state
                htmlId
                function
                { scene = { width = 100, height = 100 }
                , viewport = { x = 0, y = 0, width = 100, height = 100 }
                , element = { x = 0, y = 0, width = 100, height = 100 }
                }

        FileToString file function ->
            case file of
                RealFile _ ->
                    function "" |> runTask maybeClientId frontendApp state

                MockFile { content } ->
                    function content |> runTask maybeClientId frontendApp state

        FileToBytes file function ->
            case file of
                RealFile _ ->
                    function (Bytes.Encode.encode (Bytes.Encode.sequence []))
                        |> runTask maybeClientId frontendApp state

                MockFile { content } ->
                    function (Bytes.Encode.encode (Bytes.Encode.string content))
                        |> runTask maybeClientId frontendApp state

        FileToUrl file function ->
            case file of
                RealFile _ ->
                    function "" |> runTask maybeClientId frontendApp state

                MockFile { content } ->
                    -- TODO: Don't assume that content is already in a data url format.
                    function content |> runTask maybeClientId frontendApp state

        Focus htmlId function ->
            getDomTask frontendApp maybeClientId state htmlId function ()

        Blur htmlId function ->
            getDomTask frontendApp maybeClientId state htmlId function ()

        GetViewportOf htmlId function ->
            getDomTask
                frontendApp
                maybeClientId
                state
                htmlId
                function
                { scene = { width = 100, height = 100 }
                , viewport = { x = 0, y = 0, width = 100, height = 100 }
                }

        SetViewportOf htmlId _ _ function ->
            getDomTask frontendApp maybeClientId state htmlId function ()


getDomTask frontendApp maybeClientId state htmlId function value =
    (case Maybe.andThen (\clientId -> Dict.get clientId state.frontends) maybeClientId of
        Just frontend ->
            frontendApp.view frontend.model
                |> .body
                |> Html.div []
                |> Test.Html.Query.fromHtml
                |> Test.Html.Query.has [ Test.Html.Selector.id htmlId ]
                |> Test.Runner.getFailureReason
                |> (\a ->
                        if a == Nothing then
                            Effect.Internal.BrowserDomNotFound htmlId |> Err

                        else
                            Ok value
                   )

        Nothing ->
            Effect.Internal.BrowserDomNotFound htmlId |> Err
    )
        |> function
        |> runTask maybeClientId frontendApp state
