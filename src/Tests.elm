module Tests exposing (tests)

import Backend
import Codec
import CreateGroupPage
import Date
import Dict as RegularDict
import Duration
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Test as TF exposing (HttpResponse(..))
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
import Group exposing (EventId)
import GroupName exposing (GroupName)
import GroupPage
import Html.Parser
import Id exposing (GroupId, Id, UserId)
import Json.Decode
import List.Extra as List
import LoginForm
import Name exposing (Name)
import Ports
import Postmark
import ProfilePage
import Quantity
import Route exposing (Route)
import SeqDict as Dict
import Test.Html.Query
import Test.Html.Selector
import Time exposing (Month(..))
import Types exposing (BackendModel, BackendMsg, FrontendModel(..), FrontendMsg(..), LoadedFrontend, LoginStatus(..), ToBackend(..), ToFrontend)
import Ui
import Unsafe
import Untrusted
import Url


main : Program () (TF.Model ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel) (TF.Msg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    TF.viewer tests


config =
    TF.Config
        { init = Frontend.init
        , update = Frontend.update
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , updateFromBackend = Frontend.updateFromBackend
        , subscriptions = Frontend.subscriptions
        , view = Frontend.view
        }
        { init = Backend.init
        , update = Backend.update
        , updateFromFrontend = Backend.updateFromFrontend
        , subscriptions = Backend.subscriptions
        }
        handleHttpRequests
        handlePortToJs
        handleFileRequest
        handleFilesRequest
        (Unsafe.url Env.domain)


handleHttpRequests : { a | currentRequest : TF.HttpRequest } -> HttpResponse
handleHttpRequests { currentRequest } =
    StringHttpResponse
        { url = currentRequest.url
        , statusCode = 200
        , statusText = "OK"
        , headers = RegularDict.empty
        }
        ""


handlePortToJs :
    { a | currentRequest : TF.PortToJs }
    -> Maybe ( String, Json.Decode.Value )
handlePortToJs { currentRequest } =
    if currentRequest.portName == Ports.cropImageToJsName then
        case Codec.decodeValue Ports.cropImageDataCodec currentRequest.value of
            Ok request ->
                Just
                    ( Ports.cropImageFromJsName
                    , Codec.encodeToValue
                        Ports.cropImageDataResponseCodec
                        { requestId = request.requestId
                        , croppedImageUrl = request.imageUrl
                        }
                    )

            Err _ ->
                Nothing

    else
        Nothing


handleFileRequest : { a | mimeTypes : List String } -> TF.FileUpload
handleFileRequest _ =
    TF.uploadStringFile
        "Image0.png"
        "image/png"
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9Ta0UqgnYQcchQnayIijhKFYtgobQVWnUwufRDaNKQpLg4Cq4FBz8Wqw4uzro6uAqC4AeIm5uToouU+L+k0CLGg+N+vLv3uHsHCPUyU82OcUDVLCMVj4nZ3IoYfEUn/OhDAGMSM/VEeiEDz/F1Dx9f76I8y/vcn6NHyZsM8InEs0w3LOJ14ulNS+e8TxxmJUkhPiceNeiCxI9cl11+41x0WOCZYSOTmiMOE4vFNpbbmJUMlXiKOKKoGuULWZcVzluc1XKVNe/JXxjKa8tprtMcQhyLSCAJETKq2EAZFqK0aqSYSNF+zMM/6PiT5JLJtQFGjnlUoEJy/OB/8LtbszA54SaFYkDgxbY/hoHgLtCo2fb3sW03TgD/M3CltfyVOjDzSXqtpUWOgN5t4OK6pcl7wOUOMPCkS4bkSH6aQqEAvJ/RN+WA/luge9XtrbmP0wcgQ10t3QAHh8BIkbLXPN7d1d7bv2ea/f0AT2FymQ2GVEYAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAHdElNRQflBgMSBgvJgnPPAAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAAAxJREFUCNdjmH36PwAEagJmf/sZfAAAAABJRU5ErkJggg=="
        (Time.millisToPosix 0)
        |> TF.UploadFile


handleFilesRequest _ =
    TF.CancelMultipleFilesUpload


checkLoadedFrontend :
    ClientId
    -> (LoadedFrontend -> Result String ())
    -> TF.Action ToBackend FrontendMsg FrontendModel toFrontend backendMsg backendModel
checkLoadedFrontend clientId checkFunc =
    TF.checkState
        100
        (\state ->
            case Dict.get clientId state.frontends of
                Just (Loaded loaded) ->
                    checkFunc loaded

                Just (Loading _) ->
                    Err "Frontend is still loading"

                Nothing ->
                    Err "Frontend not found"
        )


loginFromHomepage :
    Bool
    -> SessionId
    -> SessionId
    -> EmailAddress.EmailAddress
    ->
        ({ client : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , clientFromEmail : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         }
         -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
loginFromHomepage loginWithEnterKey sessionId sessionIdFromEmail emailAddress stateFunc =
    TF.connectFrontend
        100
        sessionId
        "/"
        windowSize
        (\client ->
            [ client.click 100 Frontend.signUpOrLoginButtonId
            , handleLoginForm False loginWithEnterKey client sessionIdFromEmail emailAddress stateFunc
            ]
        )


windowSize =
    { width = 900, height = 800 }


handleLoginForm :
    Bool
    -> Bool
    -> TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> SessionId
    -> EmailAddress
    ->
        ({ client : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , clientFromEmail : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         }
         -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
handleLoginForm takeSnapshots loginWithEnterKey client sessionIdFromEmail emailAddress andThenFunc =
    let
        takeSnapshot : String -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        takeSnapshot name =
            if takeSnapshots then
                client.snapshotView 100 { name = name }

            else
                TF.group []
    in
    [ takeSnapshot "Login page"
    , client.input 100 LoginForm.emailAddressInputId (EmailAddress.toString emailAddress)
    , takeSnapshot "Login page with email"
    , if loginWithEnterKey then
        client.keyDown 100 LoginForm.emailAddressInputId "Enter" []

      else
        client.click 100 LoginForm.submitButtonId
    , TF.andThen
        100
        (\data ->
            case List.filterMap isLoginEmail data.httpRequests |> List.head of
                Just loginEmail ->
                    if loginEmail.emailAddress == emailAddress then
                        [ TF.connectFrontend
                            100
                            sessionIdFromEmail
                            (Backend.loginEmailLinkAbsolutePath loginEmail.route loginEmail.loginToken loginEmail.maybeJoinEvent)
                            windowSize
                            (\clientFromEmail ->
                                [ andThenFunc
                                    { client = client
                                    , clientFromEmail = clientFromEmail
                                    }
                                ]
                            )
                        ]

                    else
                        [ TF.checkState
                            100
                            (\_ -> Err "Got a login email but it was to the wrong address")
                        ]

                _ ->
                    [ TF.checkState 100 (\_ -> Err "Should have gotten a login email") ]
        )
    ]
        |> TF.group


loginFromHomepageWithSnapshots :
    SessionId
    -> SessionId
    -> EmailAddress.EmailAddress
    ->
        ({ client : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , clientFromEmail : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         }
         -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
loginFromHomepageWithSnapshots sessionId sessionIdFromEmail emailAddress stateFunc =
    TF.connectFrontend
        100
        sessionId
        "/"
        windowSize
        (\client ->
            [ client.snapshotView 100 { name = "Homepage" }
            , client.click 100 Frontend.signUpOrLoginButtonId
            , handleLoginForm True False client sessionIdFromEmail emailAddress stateFunc
            ]
        )


decodePostmark : Json.Decode.Decoder ( String, EmailAddress, List Html.Parser.Node )
decodePostmark =
    Json.Decode.map3 (\subject to body -> ( subject, to, body ))
        (Json.Decode.field "Subject" Json.Decode.string)
        (Json.Decode.field "To" Json.Decode.string
            |> Json.Decode.andThen
                (\to ->
                    case EmailAddress.fromString to of
                        Just emailAddress ->
                            Json.Decode.succeed emailAddress

                        Nothing ->
                            Json.Decode.fail "Invalid email address"
                )
        )
        (Json.Decode.field "HtmlBody" Json.Decode.string
            |> Json.Decode.andThen
                (\html ->
                    case Html.Parser.run html of
                        Ok nodes ->
                            Json.Decode.succeed nodes

                        Err _ ->
                            Json.Decode.fail "Failed to parse html"
                )
        )


isLoginEmail :
    TF.HttpRequest
    ->
        Maybe
            { emailAddress : EmailAddress
            , route : Route
            , loginToken : Id Id.LoginToken
            , maybeJoinEvent : Maybe ( Id GroupId, EventId )
            }
isLoginEmail httpRequest =
    if String.startsWith (Postmark.endpoint ++ "/email") httpRequest.url then
        case httpRequest.body of
            TF.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        case ( subject, getRoutesFromHtml body ) of
                            ( "Meetdown login link", [ ( route, Route.LoginToken loginToken maybeJoinEvent ) ] ) ->
                                { emailAddress = to
                                , route = route
                                , loginToken = loginToken
                                , maybeJoinEvent = maybeJoinEvent
                                }
                                    |> Just

                            _ ->
                                Nothing

                    Err _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


isReminderEmail :
    TF.HttpRequest
    -> Maybe { emailAddress : EmailAddress, groupId : Id GroupId, groupName : GroupName }
isReminderEmail httpRequest =
    if String.startsWith (Postmark.endpoint ++ "/email") httpRequest.url then
        case httpRequest.body of
            TF.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        case ( String.contains "next event starts tomorrow" subject, getRoutesFromHtml body ) of
                            ( True, [ ( Route.GroupRoute groupId groupName, Route.NoToken ) ] ) ->
                                { emailAddress = to
                                , groupId = groupId
                                , groupName = groupName
                                }
                                    |> Just

                            _ ->
                                Nothing

                    Err _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


isNewEventNotificationEmail :
    TF.HttpRequest
    -> Maybe { emailAddress : EmailAddress, groupId : Id GroupId, groupName : GroupName }
isNewEventNotificationEmail httpRequest =
    if String.startsWith (Postmark.endpoint ++ "/email") httpRequest.url then
        case httpRequest.body of
            TF.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        case ( String.contains "has planned a new event" subject, getRoutesFromHtml body ) of
                            ( True, [ ( Route.GroupRoute groupId groupName, Route.NoToken ) ] ) ->
                                { emailAddress = to
                                , groupId = groupId
                                , groupName = groupName
                                }
                                    |> Just

                            _ ->
                                Nothing

                    Err _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


gotReminder : EmailAddress -> List TF.HttpRequest -> Bool
gotReminder emailAddress httpRequests =
    List.filterMap isReminderEmail httpRequests
        |> List.any (\reminder -> reminder.emailAddress == emailAddress)


isDeleteUserEmail :
    TF.HttpRequest
    ->
        Maybe
            { emailAddress : EmailAddress
            , route : Route
            , deleteUserToken : Id Id.DeleteUserToken
            }
isDeleteUserEmail httpRequest =
    if String.startsWith (Postmark.endpoint ++ "/email") httpRequest.url then
        case httpRequest.body of
            TF.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        case ( subject, getRoutesFromHtml body ) of
                            ( "Confirm account deletion", [ ( route, Route.DeleteUserToken deleteUserToken ) ] ) ->
                                { emailAddress = to
                                , route = route
                                , deleteUserToken = deleteUserToken
                                }
                                    |> Just

                            _ ->
                                Nothing

                    Err _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


getRoutesFromHtml : List Html.Parser.Node -> List ( Route, Route.Token )
getRoutesFromHtml nodes =
    List.filterMap
        (\( attributes, _ ) ->
            let
                maybeHref =
                    List.filterMap
                        (\( name, value ) ->
                            if name == "href" then
                                Just value

                            else
                                Nothing
                        )
                        attributes
                        |> List.head
            in
            maybeHref |> Maybe.andThen Url.fromString |> Maybe.andThen Route.decode
        )
        (findNodesByTag "a" nodes)


findNodesByTag : String -> List Html.Parser.Node -> List ( List Html.Parser.Attribute, List Html.Parser.Node )
findNodesByTag tagName nodes =
    List.concatMap
        (\node ->
            case node of
                Html.Parser.Element name attributes children ->
                    (if name == tagName then
                        [ ( attributes, children ) ]

                     else
                        []
                    )
                        ++ findNodesByTag tagName children

                _ ->
                    []
        )
        nodes


startTime : Time.Posix
startTime =
    Time.millisToPosix 0


tests : List (TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests =
    [ let
        sessionId =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start "Login from homepage and submit with login button"
        startTime
        config
        [ loginFromHomepageWithSnapshots
            sessionId
            sessionId
            emailAddress
            (\{ clientFromEmail } ->
                checkLoadedFrontend
                    clientFromEmail.clientId
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
        ]
    , TF.start "Attempt login with invalid email address"
        startTime
        config
        [ TF.connectFrontend
            100
            (Lamdera.sessionIdFromString "session0")
            "/"
            windowSize
            (\client ->
                [ client.click 100 Frontend.signUpOrLoginButtonId
                , client.input 100 LoginForm.emailAddressInputId "123"
                , client.click 100 LoginForm.submitButtonId
                , client.snapshotView 100 { name = "Invalid login email" }
                ]
            )
        ]
    , let
        sessionId =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start "Login from homepage and submit with enter key"
        startTime
        config
        [ loginFromHomepage
            True
            sessionId
            sessionId
            emailAddress
            (\{ clientFromEmail } ->
                checkLoadedFrontend
                    clientFromEmail.clientId
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
        ]
    , let
        sessionId =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start "Login from homepage and check that original clientId also got logged in since it's on the same session"
        startTime
        config
        [ loginFromHomepage
            True
            sessionId
            sessionId
            emailAddress
            (\{ client } ->
                checkLoadedFrontend
                    client.clientId
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
        ]
    , TF.start "Login from homepage and check that original clientId did not get logged since it has a different sessionId"
        startTime
        config
        [ loginFromHomepage
            True
            (Lamdera.sessionIdFromString "session0")
            (Lamdera.sessionIdFromString "session1")
            (Unsafe.emailAddress "the@email.com")
            (\{ client } ->
                checkLoadedFrontend
                    client.clientId
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
        ]
    , let
        emailAddress =
            Unsafe.emailAddress "the@email.com"

        sessionId =
            Lamdera.sessionIdFromString "session0"
      in
      TF.start "Login from homepage and check it's not possible to use the same login token twice"
        startTime
        config
        [ loginFromHomepage True
            sessionId
            sessionId
            emailAddress
            (\_ ->
                TF.andThen
                    100
                    (\data ->
                        case List.filterMap isLoginEmail data.httpRequests of
                            [ loginEmail ] ->
                                [ TF.connectFrontend
                                    100
                                    (Lamdera.sessionIdFromString "session1")
                                    (Backend.loginEmailLinkAbsolutePath
                                        loginEmail.route
                                        loginEmail.loginToken
                                        loginEmail.maybeJoinEvent
                                    )
                                    windowSize
                                    (\client3 ->
                                        [ checkLoadedFrontend
                                            client3.clientId
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
                                        ]
                                    )
                                ]

                            _ ->
                                Debug.todo "Didn't find login email"
                    )
            )
        ]
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        groupName =
            "It's my Group!"

        groupDescription =
            "This is the best group"
      in
      TF.start "Creating a group redirects to newly created group page"
        startTime
        config
        [ loginFromHomepage False
            session0
            session0
            (Unsafe.emailAddress "the@email.com")
            (\{ clientFromEmail } ->
                [ createGroup clientFromEmail groupName groupDescription
                , checkLoadedFrontend
                    clientFromEmail.clientId
                    (\loaded ->
                        case Dict.keys loaded.cachedGroups of
                            [ groupId ] ->
                                if loaded.route == Route.GroupRoute groupId (Unsafe.groupName groupName) then
                                    Ok ()

                                else
                                    Err "Was redirected to incorrect route"

                            _ ->
                                Err "No cached groups were found"
                    )
                , clientFromEmail.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.text groupName
                        , Test.Html.Selector.text groupDescription
                        ]
                    )
                ]
                    |> TF.group
            )
        ]
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start "Create an event and get an email a day before it occurs"
        startTime
        config
        [ loginFromHomepage False
            session0
            session0
            emailAddress
            (\{ client } ->
                [ createGroupAndEvent
                    client
                    { groupName = "It's my Group!"
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo startTime (Duration.days 1))
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                , TF.fastForward (Duration.days -0.001 |> Quantity.plus (Duration.hours 14))
                , TF.checkState
                    100
                    (\model ->
                        if gotReminder emailAddress model.httpRequests then
                            Err "Shouldn't have gotten an event notification yet"

                        else
                            Ok ()
                    )
                , TF.checkState
                    (Duration.days 0.002 |> Duration.inMilliseconds)
                    (\model ->
                        if gotReminder emailAddress model.httpRequests then
                            Ok ()

                        else
                            Err "Should have gotten an event notification"
                    )
                ]
                    |> TF.group
            )
        ]
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start "Create an event and but don't get a notification if it's occurring within 24 hours"
        startTime
        config
        [ loginFromHomepage False
            session0
            session0
            emailAddress
            (\{ client } ->
                [ createGroupAndEvent
                    client
                    { groupName = "It's my Group!"
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc startTime
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                , TF.fastForward (Duration.hours 1.99)
                , TF.checkState
                    (Duration.hours 0.02 |> Duration.inMilliseconds)
                    (\model ->
                        if gotReminder emailAddress model.httpRequests then
                            Err "Shouldn't have gotten an event notification"

                        else
                            Ok ()
                    )
                ]
                    |> TF.group
            )
        ]
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        session1 =
            Lamdera.sessionIdFromString "session1"

        emailAddress0 =
            Unsafe.emailAddress "the@email.com"

        emailAddress1 =
            Unsafe.emailAddress "jim@a.com"

        groupName =
            Unsafe.groupName "It's my Group!"
      in
      TF.start "Create an event and another user joins it and gets an event reminder"
        startTime
        config
        [ loginFromHomepage False
            session0
            session0
            emailAddress0
            (\{ client } ->
                createGroupAndEvent
                    client
                    { groupName = GroupName.toString groupName
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo startTime Duration.day)
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
            )
        , loginFromHomepage False
            session1
            session1
            emailAddress1
            (\{ client } ->
                findSingleGroup
                    (\groupId ->
                        [ client.input 100 Frontend.groupSearchId "my group!"
                        , client.keyDown 100 Frontend.groupSearchId "Enter" []
                        , client.clickLink 100 (Route.GroupRoute groupId groupName |> Route.encode)
                        , client.click 100 GroupPage.joinEventButtonId
                        , TF.fastForward (Duration.hours 14)
                        , TF.checkState
                            (Duration.seconds 30 |> Duration.inMilliseconds)
                            (\model ->
                                if gotReminder emailAddress1 model.httpRequests then
                                    Ok ()

                                else
                                    Err "Should have gotten an event notification"
                            )
                        ]
                    )
            )
        ]
    , createEventAndAnotherUserNotLoggedInJoinsIt
    , createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt
    , let
        connectAndLogin wait count =
            TF.connectFrontend
                wait
                (Lamdera.sessionIdFromString ("session " ++ String.fromInt count))
                "/"
                windowSize
                (\client ->
                    [ client.click 100 Frontend.signUpOrLoginButtonId
                    , client.input 100 LoginForm.emailAddressInputId "my+good@email.eu"
                    , client.click 100 LoginForm.submitButtonId
                    ]
                )
      in
      TF.start "Rate limit login for a given email address"
        startTime
        config
        [ connectAndLogin 100 1
        , connectAndLogin 100 2
        , connectAndLogin 100 3
        , connectAndLogin 100 4
        , TF.checkState
            100
            (\state2 ->
                if List.filterMap isLoginEmail state2.httpRequests |> List.length |> (==) 1 then
                    Ok ()

                else
                    Err "Only one email should have been sent"
            )
        , connectAndLogin (Duration.minutes 2 |> Duration.inMilliseconds) 5
        , TF.checkState
            100
            (\state2 ->
                if List.filterMap isLoginEmail state2.httpRequests |> List.length |> (==) 2 then
                    Ok ()

                else
                    Err "Two emails should have been sent"
            )
        ]
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"
      in
      TF.start "Rate limit login for a given session"
        startTime
        config
        [ TF.connectFrontend
            100
            session0
            "/"
            windowSize
            (\client ->
                [ client.click 100 Frontend.signUpOrLoginButtonId
                , client.input 100 LoginForm.emailAddressInputId "a@email.eu"
                , client.click 100 LoginForm.submitButtonId
                , client.input 100 LoginForm.emailAddressInputId "b@email.eu"
                , client.click 100 LoginForm.submitButtonId
                , client.input 100 LoginForm.emailAddressInputId "c@email.eu"
                , client.click 100 LoginForm.submitButtonId
                , client.input 100 LoginForm.emailAddressInputId "d@email.eu"
                , client.click 100 LoginForm.submitButtonId
                , client.input 100 LoginForm.emailAddressInputId "e@email.eu"
                , client.click 100 LoginForm.submitButtonId
                , TF.checkState
                    100
                    (\state2 ->
                        let
                            count =
                                List.filterMap isLoginEmail state2.httpRequests |> List.length
                        in
                        if count == 1 then
                            Ok ()

                        else
                            "Only one email should have been sent, got "
                                ++ String.fromInt count
                                ++ " instead"
                                |> Err
                    )
                , client.input (60 * 1000) LoginForm.emailAddressInputId "e@email.eu"
                , client.click 100 LoginForm.submitButtonId
                , TF.checkState
                    100
                    (\state2 ->
                        let
                            count =
                                List.filterMap isLoginEmail state2.httpRequests |> List.length
                        in
                        if count == 2 then
                            Ok ()

                        else
                            "Two emails should have been sent, got "
                                ++ String.fromInt count
                                ++ " instead"
                                |> Err
                    )
                ]
            )
        ]
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "a@email.eu"
      in
      TF.start "Rate limit delete account email"
        startTime
        config
        [ loginFromHomepage
            True
            session0
            session0
            emailAddress
            (\{ client } ->
                [ client.clickLink 100 (Route.encode Route.MyProfileRoute)
                , client.click 100 ProfilePage.deleteAccountButtonId
                , client.click 100 ProfilePage.deleteAccountButtonId
                , client.click 100 ProfilePage.deleteAccountButtonId
                , client.click 100 ProfilePage.deleteAccountButtonId
                , TF.checkState
                    100
                    (\state2 ->
                        let
                            count =
                                List.count
                                    (\httpRequest ->
                                        case isDeleteUserEmail httpRequest of
                                            Just deleteUserEmail ->
                                                deleteUserEmail.emailAddress == emailAddress

                                            Nothing ->
                                                False
                                    )
                                    state2.httpRequests
                        in
                        if count == 1 then
                            Ok ()

                        else
                            "Only one account deletion email should have been sent, got "
                                ++ String.fromInt count
                                ++ " instead"
                                |> Err
                    )
                , client.click (Duration.minutes 1.5 |> Duration.inMilliseconds) ProfilePage.deleteAccountButtonId
                , TF.checkState
                    100
                    (\state2 ->
                        let
                            count =
                                List.count
                                    (\httpRequest ->
                                        case isDeleteUserEmail httpRequest of
                                            Just deleteUserEmail ->
                                                deleteUserEmail.emailAddress == emailAddress

                                            Nothing ->
                                                False
                                    )
                                    state2.httpRequests
                        in
                        if count == 2 then
                            Ok ()

                        else
                            "Two account deletion emails should have been sent, got "
                                ++ String.fromInt count
                                ++ " instead"
                                |> Err
                    )
                ]
                    |> TF.group
            )
        ]
    , let
        sessionId =
            Lamdera.sessionIdFromString "sessionId"
      in
      TF.start "Not logged in users can't create groups"
        startTime
        config
        [ TF.connectFrontend
            100
            sessionId
            (Route.encode Route.HomepageRoute)
            windowSize
            (\client ->
                [ client.sendToBackend
                    100
                    (CreateGroupRequest
                        (Unsafe.groupName "group" |> Untrusted.untrust)
                        (Unsafe.description "description" |> Untrusted.untrust)
                        Group.PublicGroup
                    )
                ]
            )
        , TF.checkBackend
            100
            (\backend ->
                if Dict.isEmpty backend.groups then
                    Ok ()

                else
                    Err "No group should have been created"
            )
        ]
    , let
        sessionId =
            Lamdera.sessionIdFromString "sessionId"

        attackerSessionId =
            Lamdera.sessionIdFromString "sessionIdAttacker"

        emailAddress =
            Unsafe.emailAddress "my@email.com"

        attackerEmailAddress =
            Unsafe.emailAddress "hacker@email.com"
      in
      TF.start "Non-admin users can't delete groups"
        startTime
        config
        [ loginFromHomepage
            True
            sessionId
            sessionId
            emailAddress
            (\{ client } ->
                createGroup client "group" "description"
            )
        , loginFromHomepage
            False
            attackerSessionId
            attackerSessionId
            attackerEmailAddress
            (\{ client } ->
                findSingleGroup
                    (\groupId ->
                        [ client.sendToBackend
                            100
                            (GroupRequest groupId GroupPage.DeleteGroupAdminRequest)
                        ]
                    )
            )
        , TF.checkBackend
            100
            (\backend ->
                if Dict.isEmpty backend.deletedGroups && Dict.size backend.groups == 1 then
                    Ok ()

                else
                    Err "No group should have been deleted"
            )
        ]
    , let
        sessionId =
            Lamdera.sessionIdFromString "sessionId"

        subscriberSessionId =
            Lamdera.sessionIdFromString "sessionIdAttacker"

        emailAddress =
            Unsafe.emailAddress "my@email.com"

        subscriberEmail =
            Unsafe.emailAddress "a@email.com"

        groupName =
            Unsafe.groupName "group"
      in
      TF.start "Get new event notification"
        startTime
        config
        [ loginFromHomepage
            True
            sessionId
            sessionId
            emailAddress
            (\{ client } ->
                [ createGroup client (GroupName.toString groupName) "description"
                , loginFromHomepage
                    False
                    subscriberSessionId
                    subscriberSessionId
                    subscriberEmail
                    (\a ->
                        findSingleGroup
                            (\groupId ->
                                [ a.client.input 100 Frontend.groupSearchId "my group!"
                                , a.client.keyDown 100 Frontend.groupSearchId "Enter" []
                                , a.client.clickLink 100 (Route.GroupRoute groupId groupName |> Route.encode)
                                , a.client.click 100 GroupPage.subscribeButtonId
                                ]
                            )
                    )
                , client.click 100 GroupPage.createNewEventId
                , client.input 100 GroupPage.eventNameInputId "Event!"
                , client.input 100 GroupPage.eventDescriptionInputId "Event description"
                , client.click 100 (GroupPage.eventMeetingTypeId GroupPage.MeetOnline)
                , client.input 100 GroupPage.createEventStartDateId (Ui.datestamp (Date.fromRataDie 737485))
                , client.input 100 GroupPage.createEventStartTimeId (Ui.timestamp 10 12)
                , client.input 100 GroupPage.eventDurationId "1"
                , client.click 100 GroupPage.createEventSubmitId
                ]
                    |> TF.group
            )
        , TF.checkState
            100
            (\state ->
                case
                    ( Dict.toList state.backend.groups
                    , List.filterMap isNewEventNotificationEmail state.httpRequests
                    )
                of
                    ( [ ( groupId, group ) ], [ newEventNotification ] ) ->
                        if
                            newEventNotification
                                == { emailAddress = subscriberEmail, groupId = groupId, groupName = Group.name group }
                        then
                            Ok ()

                        else
                            Err "Incorrect notification"

                    _ ->
                        Err "New event notification email not found"
            )
        ]
    , snapshotPages
    ]


findSingleGroup :
    (Id GroupId
     -> List (TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
    )
    -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
findSingleGroup continueWith =
    TF.andThen
        100
        (\data ->
            case Dict.keys data.backend.groups of
                [ groupId ] ->
                    continueWith groupId

                keys ->
                    [ TF.checkState
                        100
                        (\_ ->
                            "Expected to find exactly one group, instead got "
                                ++ String.fromInt (List.length keys)
                                |> Err
                        )
                    ]
        )


findUser :
    Name
    ->
        (Id UserId
         -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
findUser name continueWith =
    TF.andThen
        100
        (\data ->
            [ case Dict.toList data.backend.users |> List.find (\( _, user ) -> user.name == name) of
                Just ( userId, _ ) ->
                    continueWith userId

                Nothing ->
                    TF.checkState
                        100
                        (\_ -> "Expected to find user named \"" ++ Name.toString name ++ "\"" |> Err)
            ]
        )


createEventAndAnotherUserNotLoggedInJoinsIt : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
createEventAndAnotherUserNotLoggedInJoinsIt =
    let
        session0 =
            Lamdera.sessionIdFromString "session0"

        session1 =
            Lamdera.sessionIdFromString "session1"

        emailAddress0 =
            Unsafe.emailAddress "the@email.se"

        emailAddress1 =
            Unsafe.emailAddress "jim@a.com"

        groupName =
            Unsafe.groupName "It's my Group!"
    in
    TF.start "Create an event and another user (who isn't logged in) joins it"
        startTime
        config
        [ loginFromHomepage False
            session0
            session0
            emailAddress0
            (\{ client } ->
                createGroupAndEvent
                    client
                    { groupName = GroupName.toString groupName
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo startTime Duration.day)
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
            )
        , TF.connectFrontend
            100
            session1
            (Route.encode Route.HomepageRoute)
            windowSize
            (\client ->
                [ findSingleGroup
                    (\groupId ->
                        [ client.input 100 Frontend.groupSearchId "my group!"
                        , client.keyDown 100 Frontend.groupSearchId "Enter" []
                        , client.clickLink 100 (Route.GroupRoute groupId groupName |> Route.encode)
                        , client.click 100 GroupPage.joinEventButtonId
                        , handleLoginForm
                            False
                            True
                            client
                            session1
                            emailAddress1
                            (\a ->
                                -- We are just clicking the leave button to test that we had joined the event.
                                a.clientFromEmail.click 100 GroupPage.leaveEventButtonId
                            )
                        ]
                    )
                ]
            )
        ]


createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt =
    let
        session0 =
            Lamdera.sessionIdFromString "session0"

        session1 =
            Lamdera.sessionIdFromString "session1"

        emailAddress0 =
            Unsafe.emailAddress "the@email.com"

        emailAddress1 =
            Unsafe.emailAddress "jim@a.com"

        groupName =
            Unsafe.groupName "It's my Group!"
    in
    TF.start "Create an event and another user (who isn't logged in but has an account) joins it"
        startTime
        config
        [ loginFromHomepage False
            session0
            session0
            emailAddress0
            (\{ client } ->
                createGroupAndEvent
                    client
                    { groupName = GroupName.toString groupName
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo startTime Duration.day)
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
            )
        , loginFromHomepage False
            session1
            session1
            emailAddress1
            (\{ clientFromEmail } ->
                clientFromEmail.click 100 Frontend.logOutButtonId
            )
        , TF.connectFrontend
            (60 * 1000)
            session1
            (Route.encode Route.HomepageRoute)
            windowSize
            (\client ->
                [ findSingleGroup
                    (\groupId ->
                        [ client.input 100 Frontend.groupSearchId "my group!"
                        , client.keyDown 100 Frontend.groupSearchId "Enter" []
                        , client.clickLink 100 (Route.GroupRoute groupId groupName |> Route.encode)
                        , client.click 100 GroupPage.joinEventButtonId
                        , handleLoginForm
                            False
                            True
                            client
                            session1
                            emailAddress1
                            (\a ->
                                -- We are just clicking the leave button to test that we had joined the event.
                                a.clientFromEmail.click 100 GroupPage.leaveEventButtonId
                            )
                        ]
                    )
                ]
            )
        ]


createGroup :
    TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
createGroup loggedInClient groupName groupDescription =
    [ loggedInClient.clickLink 100 (Route.encode Route.CreateGroupRoute)
    , loggedInClient.input 100 CreateGroupPage.nameInputId groupName
    , loggedInClient.input 100 CreateGroupPage.descriptionInputId groupDescription
    , loggedInClient.click 100 (CreateGroupPage.groupVisibilityId Group.PublicGroup)
    , loggedInClient.click 100 CreateGroupPage.submitButtonId
    ]
        |> TF.group


createGroupAndEvent :
    TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    ->
        { groupName : String
        , groupDescription : String
        , eventName : String
        , eventDescription : String
        , eventDate : Date.Date
        , eventHour : Int
        , eventMinute : Int
        , eventDuration : String
        }
    -> TF.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
createGroupAndEvent loggedInClient { groupName, groupDescription, eventName, eventDescription, eventDate, eventHour, eventMinute, eventDuration } =
    [ createGroup loggedInClient groupName groupDescription
    , loggedInClient.click 100 GroupPage.createNewEventId
    , loggedInClient.input 100 GroupPage.eventNameInputId eventName
    , loggedInClient.input 100 GroupPage.eventDescriptionInputId eventDescription
    , loggedInClient.click 100 (GroupPage.eventMeetingTypeId GroupPage.MeetOnline)
    , loggedInClient.input 100 GroupPage.createEventStartDateId (Ui.datestamp eventDate)
    , loggedInClient.input 100 GroupPage.createEventStartTimeId (Ui.timestamp eventHour eventMinute)
    , loggedInClient.input 100 GroupPage.eventDurationId eventDuration
    , loggedInClient.click 100 GroupPage.createEventSubmitId
    ]
        |> TF.group


snapshotPages : TF.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
snapshotPages =
    let
        emailAddress : EmailAddress
        emailAddress =
            Unsafe.emailAddress "the@email.com"

        groupName : GroupName
        groupName =
            Unsafe.groupName "The best group"

        name : Name
        name =
            Unsafe.name "Mr. Longnamingsson Jr."
    in
    TF.start "Snapshot pages"
        startTime
        config
        [ loginFromHomepage False
            (Lamdera.sessionIdFromString "sessionId0")
            (Lamdera.sessionIdFromString "sessionId0")
            emailAddress
            (\{ client } ->
                -- View miscellaneous pages
                [ client.clickLink 100 (Route.encode Route.FrequentQuestionsRoute)
                , client.snapshotView 100 { name = "FAQ page" }
                , client.clickLink 100 (Route.encode Route.CodeOfConductRoute)
                , client.snapshotView 100 { name = "Code of conduct page" }
                , client.clickLink 100 (Route.encode Route.TermsOfServiceRoute)
                , client.snapshotView 100 { name = "Terms of service page" }
                , client.clickLink 100 (Route.encode Route.PrivacyRoute)
                , client.snapshotView 100 { name = "Privacy page" }

                -- View my groups without group
                , client.clickLink 100 (Route.encode Route.MyGroupsRoute)
                , client.snapshotView 100 { name = "My groups page" }

                -- Create group
                , client.clickLink 100 (Route.encode Route.CreateGroupRoute)
                , client.snapshotView 100 { name = "Create group page" }
                , client.click 100 CreateGroupPage.submitButtonId
                , client.snapshotView 100 { name = "Fail to create group" }
                , client.input 100 CreateGroupPage.nameInputId (GroupName.toString groupName)
                , client.input 100 CreateGroupPage.descriptionInputId "groupDescription"
                , client.click 100 (CreateGroupPage.groupVisibilityId Group.PublicGroup)
                , client.snapshotView 100 { name = "Create group page with fields filled" }
                , client.click 100 CreateGroupPage.submitButtonId
                , client.snapshotView 100 { name = "Group page" }
                , client.click 100 GroupPage.createNewEventId

                -- Create group event
                , client.snapshotView 100 { name = "Create event page" }
                , client.click 100 GroupPage.createEventSubmitId
                , client.snapshotView 100 { name = "Fail to create event" }
                , client.input 100 GroupPage.eventNameInputId "First event!"
                , client.input 100 GroupPage.eventDescriptionInputId "Hey this is my cool first event! I'm so excited to host it and I hope a bunch of people join. We're going to have lots of fun doing stuff!"
                , client.click 100 (GroupPage.eventMeetingTypeId GroupPage.MeetOnline)
                , client.input 100 GroupPage.createEventStartDateId (Ui.datestamp (Date.fromCalendarDate 1970 Jan 2))
                , client.input 100 GroupPage.createEventStartTimeId (Ui.timestamp 0 1)
                , client.input 100 GroupPage.eventDurationId "2"
                , client.snapshotView 100 { name = "Create event page with fields filled" }
                , client.click 100 GroupPage.createEventSubmitId
                , client.snapshotView 100 { name = "Group page with new event" }
                , client.click 100 GroupPage.showAttendeesButtonId
                , client.snapshotView 100 { name = "Group page with new event and show attendees" }
                , client.click 100 GroupPage.hideAttendeesButtonId

                -- View default user profile
                , findUser
                    Name.anonymous
                    (\userId ->
                        client.clickLink 100 (Route.encode (Route.UserRoute userId Name.anonymous))
                    )
                , client.snapshotView 100 { name = "Default user profile page" }

                -- View my groups with group
                , client.clickLink 100 (Route.encode Route.MyGroupsRoute)
                , client.snapshotView 100 { name = "My groups page with group" }

                -- Edit profile
                , client.clickLink 100 (Route.encode Route.MyProfileRoute)
                , client.snapshotView 100 { name = "Profile page" }
                , client.input 100 ProfilePage.nameTextInputId (Name.toString name)
                , client.input 3000 ProfilePage.descriptionTextInputId "This is my description text that I have so thoughtfully written to take up at least one or two lines of spaces in the web page it's viewed on."
                , client.input 3000 Frontend.groupSearchId (GroupName.toString groupName)
                , client.snapshotView 3000 { name = "Profile page with changes and search prepared" }

                -- Search for group
                , client.keyDown 100 Frontend.groupSearchId "Enter" []
                , client.snapshotView 100 { name = "Search page" }
                , findSingleGroup
                    (\groupId ->
                        [ client.clickLink 100 (Route.encode (Route.GroupRoute groupId groupName)) ]
                    )
                , client.click 100 GroupPage.showAttendeesButtonId
                , client.snapshotView 100 { name = "Group page with updated profile" }
                , TF.fastForward (Duration.hours 23)
                , client.snapshotView (60 * 1000) { name = "Group page with less than 1 hour to event" }
                , TF.fastForward Duration.hour
                , client.snapshotView (60 * 1000) { name = "Group page with event ongoing" }
                , TF.fastForward (Duration.hours 3)
                , client.snapshotView (60 * 1000) { name = "Group page with event ended" }

                -- View user profile with edits
                , findUser
                    name
                    (\userId ->
                        client.clickLink 100 (Route.encode (Route.UserRoute userId name))
                    )
                , client.snapshotView 100 { name = "User profile page with edits" }
                ]
                    |> TF.group
            )
        ]
