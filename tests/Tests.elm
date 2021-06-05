module Tests exposing (suite)

import Backend
import Duration
import EmailAddress
import Env
import Frontend
import Id
import LoginForm
import Test exposing (..)
import TestFramework as TF exposing (EmailType(..))
import Types exposing (FrontendModel(..), LoginStatus(..))
import Ui


loginFromHomepage :
    Bool
    -> Id.SessionId
    -> Id.SessionId
    -> EmailAddress.EmailAddress
    -> TF.State
    -> { state : TF.State, clientId : Id.ClientId, clientIdFromEmail : Id.ClientId }
loginFromHomepage loginWithEnterKey sessionId sessionIdFromEmail emailAddress state =
    state
        |> TF.connectFrontend sessionId (TF.unsafeUrl Env.domain)
        |> (\( state2, clientId ) ->
                state2
                    |> TF.simulateTime Duration.second
                    |> TF.clickEvent clientId Frontend.signUpOrLoginButtonId
                    |> TF.simulateTime Duration.second
                    |> TF.inputEvent clientId LoginForm.emailAddressInputId (EmailAddress.toString emailAddress)
                    |> TF.simulateTime Duration.second
                    |> (if loginWithEnterKey then
                            TF.keyDownEvent clientId LoginForm.emailAddressInputId Ui.enterKeyCode

                        else
                            TF.clickEvent clientId LoginForm.submitButtonId
                       )
                    |> TF.simulateTime Duration.second
                    |> (\state3 ->
                            case List.filter (Tuple.first >> (==) emailAddress) state3.emailInboxes of
                                [ ( _, LoginEmail route loginToken ) ] ->
                                    state3
                                        |> TF.connectFrontend
                                            sessionIdFromEmail
                                            (TF.unsafeUrl (Backend.loginEmailLink route loginToken))
                                        |> (\( state4, clientIdFromEmail ) ->
                                                { state = state4 |> TF.simulateTime Duration.second
                                                , clientId = clientId
                                                , clientIdFromEmail = clientIdFromEmail
                                                }
                                           )

                                _ ->
                                    Debug.todo "Should have gotten a login email"
                       )
           )


suite : Test
suite =
    describe "App tests"
        [ test "Login from homepage and submit with login button" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage False sessionId sessionId emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.checkLoadedFrontend
                                    clientIdFromEmail
                                    (\frontend ->
                                        case frontend.loginStatus of
                                            LoggedIn loggedIn ->
                                                if loggedIn.emailAddress == emailAddress then
                                                    Ok ()

                                                else
                                                    "Incorrect email address "
                                                        ++ EmailAddress.toString loggedIn.emailAddress
                                                        |> Err

                                            _ ->
                                                Err "Failed to log in"
                                    )
                       )
                    |> TF.finishSimulation
        , test "Login from homepage and submit with enter key" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage True sessionId sessionId emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.checkLoadedFrontend
                                    clientIdFromEmail
                                    (\frontend ->
                                        case frontend.loginStatus of
                                            LoggedIn loggedIn ->
                                                if loggedIn.emailAddress == emailAddress then
                                                    Ok ()

                                                else
                                                    "Incorrect email address "
                                                        ++ EmailAddress.toString loggedIn.emailAddress
                                                        |> Err

                                            _ ->
                                                Err "Failed to log in"
                                    )
                       )
                    |> TF.finishSimulation
        , test "Login from homepage and check that original clientId also got logged in since it's on the same session" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage True sessionId sessionId emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.checkLoadedFrontend
                                    clientId
                                    (\frontend ->
                                        case frontend.loginStatus of
                                            LoggedIn loggedIn ->
                                                if loggedIn.emailAddress == emailAddress then
                                                    Ok ()

                                                else
                                                    "Incorrect email address "
                                                        ++ EmailAddress.toString loggedIn.emailAddress
                                                        |> Err

                                            _ ->
                                                Err "Failed to log in"
                                    )
                       )
                    |> TF.finishSimulation
        , test "Login from homepage and check that original clientId did not get logged since it has a different sessionId" <|
            \_ ->
                TF.init
                    |> loginFromHomepage
                        True
                        (Id.sessionIdFromString "session0")
                        (Id.sessionIdFromString "session1")
                        (TF.unsafeEmailAddress "a@a.se")
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.checkLoadedFrontend
                                    clientId
                                    (\frontend ->
                                        case frontend.loginStatus of
                                            LoggedIn _ ->
                                                Err "Should not have been logged in"

                                            NotLoggedIn _ ->
                                                Ok ()

                                            LoginStatusPending ->
                                                Err "Failed to check login"
                                    )
                       )
                    |> TF.finishSimulation
        , test "Login from homepage and check it's not possible to use the same login token twice" <|
            \_ ->
                let
                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"

                    sessionId =
                        Id.sessionIdFromString "session0"
                in
                TF.init
                    |> loginFromHomepage True sessionId sessionId emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            case List.filter (Tuple.first >> (==) emailAddress) state.emailInboxes of
                                [ ( _, LoginEmail route loginToken ) ] ->
                                    state
                                        |> TF.connectFrontend
                                            (Id.sessionIdFromString "session1")
                                            (TF.unsafeUrl (Backend.loginEmailLink route loginToken))
                                        |> (\( state2, clientId3 ) ->
                                                state2
                                                    |> TF.simulateTime Duration.second
                                                    |> Debug.log "test"
                                                    |> TF.checkLoadedFrontend
                                                        clientId3
                                                        (\frontend ->
                                                            case frontend.loginStatus of
                                                                LoggedIn _ ->
                                                                    Err "Should not have been logged in"

                                                                NotLoggedIn _ ->
                                                                    if frontend.hasLoginTokenError then
                                                                        Ok ()

                                                                    else
                                                                        Err "Correctly didn't log in but failed to show error"

                                                                LoginStatusPending ->
                                                                    Err "Failed to check login"
                                                        )
                                           )

                                _ ->
                                    Debug.todo "Didn't find login email"
                       )
                    |> TF.finishSimulation
        ]


abc =
    { backend = { connections = D [ ( SessionId "session1", Nonempty (ClientId "clientId 2") [] ), ( SessionId "session0", Nonempty (ClientId "clientId 1") [ ClientId "clientId 0" ] ) ], groupIdCounter = 0, groups = D [], logs = Array.fromList [ SendGridSendEmail (Posix 17) (Ok ()) (EmailAddress { domain = "a", localPart = "a", tags = [], tld = [ "se" ] }) ], pendingDeleteUserTokens = D [], pendingLoginTokens = D [], secretCounter = 2, sessions = BiDict { forward = D [ ( SessionId "session0", Id "4c603b6820b7935c59fe289d850b0f772221f1f80a4d8a9c7424c5448412a1ab" ) ], reverse = D [ ( Id "4c603b6820b7935c59fe289d850b0f772221f1f80a4d8a9c7424c5448412a1ab", Set (D [ ( SessionId "session0", () ) ]) ) ] }, time = Posix 17, users = D [ ( Id "4c603b6820b7935c59fe289d850b0f772221f1f80a4d8a9c7424c5448412a1ab", { description = Description "", emailAddress = EmailAddress { domain = "a", localPart = "a", tags = [], tld = [ "se" ] }, name = Name "Anonymous", profileImage = DefaultImage } ) ] }
    , counter = 3
    , elapsedTime = Quantity 5.999999999999984
    , emailInboxes = [ ( EmailAddress { domain = "a", localPart = "a", tags = [], tld = [ "se" ] }, LoginEmail HomepageRoute (Id "71e63e426a6e8b910aa2b3c8c910cf8be113aae9d4b9a1a3fb7b43d2aa368823") ) ]
    , frontends =
        D
            [ ( ClientId "clientId 2"
              , { clipboard = ""
                , model = Loaded { accountDeletedResult = Nothing, cachedGroups = D [], cachedUsers = D [], groupCreated = False, groupForm = Editting { description = "", name = "", pressedSubmit = False, visibility = Nothing }, groupPage = D [], hasLoginTokenError = True, lastConnectionCheck = Posix 5017, loginForm = { email = "", emailSent = Nothing, pressedSubmitEmail = False }, loginStatus = LoginStatusPending, logs = Nothing, navigationKey = MockNavigationKey, route = HomepageRoute, searchBox = "", searchList = [], time = Posix 5017, timezone = Zone 0 [], windowHeight = Quantity 1080, windowWidth = Quantity 1920 }
                , pendingEffects = Batch [ Batch [ None ], Batch [ None ] ]
                , sessionId = SessionId "session1"
                , timers = D []
                , toFrontend = []
                , url = { fragment = Nothing, host = "localhost", path = "/", port_ = Just 8000, protocol = Https, query = Nothing }
                }
              )
            , ( ClientId "clientId 1"
              , { clipboard = ""
                , model = Loaded { accountDeletedResult = Nothing, cachedGroups = D [], cachedUsers = D [ ( Id "4c603b6820b7935c59fe289d850b0f772221f1f80a4d8a9c7424c5448412a1ab", { description = Description "", name = Name "Anonymous", profileImage = DefaultImage } ) ], groupCreated = False, groupForm = Editting { description = "", name = "", pressedSubmit = False, visibility = Nothing }, groupPage = D [], hasLoginTokenError = True, lastConnectionCheck = Posix 4017, loginForm = { email = "", emailSent = Nothing, pressedSubmitEmail = False }, loginStatus = LoggedIn { emailAddress = EmailAddress { domain = "a", localPart = "a", tags = [], tld = [ "se" ] }, myGroups = Nothing, profileForm = { changeCounter = 0, form = { description = Unchanged, emailAddress = Unchanged, name = Unchanged }, pressedDeleteAccount = False, profileImage = Unchanged, profileImageSize = Nothing }, userId = Id "4c603b6820b7935c59fe289d850b0f772221f1f80a4d8a9c7424c5448412a1ab" }, logs = Nothing, navigationKey = MockNavigationKey, route = HomepageRoute, searchBox = "", searchList = [], time = Posix 4017, timezone = Zone 0 [], windowHeight = Quantity 1080, windowWidth = Quantity 1920 }
                , pendingEffects = Batch [ Batch [ None ], Batch [ None ] ]
                , sessionId = SessionId "session0"
                , timers = D []
                , toFrontend = []
                , url = { fragment = Nothing, host = "localhost", path = "/", port_ = Just 8000, protocol = Https, query = Nothing }
                }
              )
            , ( ClientId "clientId 0"
              , { clipboard = ""
                , model = Loaded { accountDeletedResult = Nothing, cachedGroups = D [], cachedUsers = D [ ( Id "4c603b6820b7935c59fe289d850b0f772221f1f80a4d8a9c7424c5448412a1ab", { description = Description "", name = Name "Anonymous", profileImage = DefaultImage } ) ], groupCreated = False, groupForm = Editting { description = "", name = "", pressedSubmit = False, visibility = Nothing }, groupPage = D [], hasLoginTokenError = False, lastConnectionCheck = Posix 17, loginForm = { email = "a@a.se", emailSent = Just (EmailAddress { domain = "a", localPart = "a", tags = [], tld = [ "se" ] }), pressedSubmitEmail = False }, loginStatus = LoggedIn { emailAddress = EmailAddress { domain = "a", localPart = "a", tags = [], tld = [ "se" ] }, myGroups = Nothing, profileForm = { changeCounter = 0, form = { description = Unchanged, emailAddress = Unchanged, name = Unchanged }, pressedDeleteAccount = False, profileImage = Unchanged, profileImageSize = Nothing }, userId = Id "4c603b6820b7935c59fe289d850b0f772221f1f80a4d8a9c7424c5448412a1ab" }, logs = Nothing, navigationKey = MockNavigationKey, route = HomepageRoute, searchBox = "", searchList = [], time = Posix17, timezone = Zone 0 [], windowHeight = Quantity 1080, windowWidth = Quantity 1920 }
                , pendingEffects = Batch [ Batch [ None ], Batch [ None ] ]
                , sessionId = SessionId "session0"
                , timers = D []
                , toFrontend = []
                , url = { fragment = Nothing, host = "localhost", path = "/", port_ = Just 8000, protocol = Https, query = Nothing }
                }
              )
            ]
    , pendingEffects = Batch [ None ]
    , testErrors = []
    , timers = D [ ( Quantity 15, { msg = a, startTime = Posix 0 } ) ]
    , toBackend = []
    }
