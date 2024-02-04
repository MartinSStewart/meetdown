module Tests exposing (tests)

import AssocList as Dict
import Backend
import Bytes exposing (Bytes)
import Bytes.Encode
import Codec
import CreateGroupPage
import Date
import Dict as RegularDict
import Duration
import Effect.Http as Http
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


handleHttpRequests : { currentRequest : TF.HttpRequest, pastRequests : List TF.HttpRequest } -> HttpResponse
handleHttpRequests { currentRequest } =
    StringHttpResponse
        { url = currentRequest.url
        , statusCode = 200
        , statusText = "OK"
        , headers = RegularDict.empty
        }
        ""


handlePortToJs :
    { currentRequest : TF.PortToJs, pastRequests : List TF.PortToJs }
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


handleFileRequest :
    { mimeTypes : List String }
    -> TF.FileUpload
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
    -> TF.Instructions ToBackend FrontendMsg FrontendModel toFrontend backendMsg backendModel
    -> TF.Instructions ToBackend FrontendMsg FrontendModel toFrontend backendMsg backendModel
checkLoadedFrontend clientId checkFunc =
    TF.checkState
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    case frontend.model of
                        Loaded loaded ->
                            checkFunc loaded

                        Loading _ ->
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
        ({ instructions : TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , client : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , clientFromEmail : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         }
         -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
loginFromHomepage loginWithEnterKey sessionId sessionIdFromEmail emailAddress stateFunc =
    TF.connectFrontend
        sessionId
        (Unsafe.url Env.domain)
        windowSize
        (\( state3, client ) ->
            state3
                |> shortWait
                |> client.clickButton Frontend.signUpOrLoginButtonId
                |> handleLoginForm False loginWithEnterKey client sessionIdFromEmail emailAddress stateFunc
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
        ({ instructions : TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , client : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , clientFromEmail : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         }
         -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
handleLoginForm takeSnapshots loginWithEnterKey client sessionIdFromEmail emailAddress andThenFunc state =
    let
        takeSnapshot name =
            if takeSnapshots then
                client.snapshotView { name = name }

            else
                identity
    in
    state
        |> shortWait
        |> takeSnapshot "Login page"
        |> client.inputText LoginForm.emailAddressInputId (EmailAddress.toString emailAddress)
        |> shortWait
        |> takeSnapshot "Login page with email"
        |> (if loginWithEnterKey then
                client.keyDownEvent LoginForm.emailAddressInputId { keyCode = Ui.enterKeyCode }

            else
                client.clickButton LoginForm.submitButtonId
           )
        |> shortWait
        |> TF.andThen
            (\state3 ->
                case List.filterMap isLoginEmail state3.httpRequests |> List.head of
                    Just loginEmail ->
                        if loginEmail.emailAddress == emailAddress then
                            TF.continueWith state3
                                |> TF.connectFrontend
                                    sessionIdFromEmail
                                    (Unsafe.url (Backend.loginEmailLink loginEmail.route loginEmail.loginToken loginEmail.maybeJoinEvent))
                                    windowSize
                                    (\( state4, clientFromEmail ) ->
                                        andThenFunc
                                            { instructions = state4 |> shortWait
                                            , client = client
                                            , clientFromEmail = clientFromEmail
                                            }
                                    )

                        else
                            TF.continueWith state3 |> TF.checkState (\_ -> Err "Got a login email but it was to the wrong address")

                    _ ->
                        TF.continueWith state3 |> TF.checkState (\_ -> Err "Should have gotten a login email")
            )


loginFromHomepageWithSnapshots :
    SessionId
    -> SessionId
    -> EmailAddress.EmailAddress
    ->
        ({ instructions : TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , client : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         , clientFromEmail : TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         }
         -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
loginFromHomepageWithSnapshots sessionId sessionIdFromEmail emailAddress stateFunc =
    TF.connectFrontend
        sessionId
        (Unsafe.url Env.domain)
        windowSize
        (\( state3, client ) ->
            state3
                |> shortWait
                |> client.snapshotView { name = "Homepage" }
                |> client.clickButton Frontend.signUpOrLoginButtonId
                |> handleLoginForm True False client sessionIdFromEmail emailAddress stateFunc
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


tests : List (TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests =
    [ let
        sessionId =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start config "Login from homepage and submit with login button"
        |> loginFromHomepageWithSnapshots
            sessionId
            sessionId
            emailAddress
            (\{ instructions, clientFromEmail } ->
                instructions
                    |> checkLoadedFrontend
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
    , TF.start config "Attempt login with invalid email address"
        |> TF.connectFrontend
            (Lamdera.sessionIdFromString "session0")
            (Unsafe.url Env.domain)
            windowSize
            (\( state3, client ) ->
                state3
                    |> shortWait
                    |> client.clickButton Frontend.signUpOrLoginButtonId
                    |> shortWait
                    |> client.inputText LoginForm.emailAddressInputId "123"
                    |> shortWait
                    |> client.clickButton LoginForm.submitButtonId
                    |> shortWait
                    |> client.snapshotView { name = "Invalid login email" }
            )
    , let
        sessionId =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start config "Login from homepage and submit with enter key"
        |> loginFromHomepage
            True
            sessionId
            sessionId
            emailAddress
            (\{ instructions, clientFromEmail } ->
                instructions
                    |> checkLoadedFrontend
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
    , let
        sessionId =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start config "Login from homepage and check that original clientId also got logged in since it's on the same session"
        |> loginFromHomepage
            True
            sessionId
            sessionId
            emailAddress
            (\{ instructions, client } ->
                instructions
                    |> checkLoadedFrontend
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
    , TF.start config "Login from homepage and check that original clientId did not get logged since it has a different sessionId"
        |> loginFromHomepage
            True
            (Lamdera.sessionIdFromString "session0")
            (Lamdera.sessionIdFromString "session1")
            (Unsafe.emailAddress "the@email.com")
            (\{ instructions, client } ->
                instructions
                    |> checkLoadedFrontend
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
    , let
        emailAddress =
            Unsafe.emailAddress "the@email.com"

        sessionId =
            Lamdera.sessionIdFromString "session0"
      in
      TF.start config "Login from homepage and check it's not possible to use the same login token twice"
        |> loginFromHomepage True
            sessionId
            sessionId
            emailAddress
            (\{ instructions } ->
                instructions
                    |> TF.andThen
                        (\state ->
                            case List.filterMap isLoginEmail state.httpRequests of
                                [ loginEmail ] ->
                                    TF.continueWith state
                                        |> TF.connectFrontend
                                            (Lamdera.sessionIdFromString "session1")
                                            (Unsafe.url
                                                (Backend.loginEmailLink
                                                    loginEmail.route
                                                    loginEmail.loginToken
                                                    loginEmail.maybeJoinEvent
                                                )
                                            )
                                            windowSize
                                            (\( state2, client3 ) ->
                                                state2
                                                    |> shortWait
                                                    |> checkLoadedFrontend
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
                                            )

                                _ ->
                                    Debug.todo "Didn't find login email"
                        )
            )
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        groupName =
            "It's my Group!"

        groupDescription =
            "This is the best group"
      in
      TF.start config "Creating a group redirects to newly created group page"
        |> loginFromHomepage False
            session0
            session0
            (Unsafe.emailAddress "the@email.com")
            (\{ instructions, clientFromEmail } ->
                createGroup clientFromEmail groupName groupDescription instructions
                    |> checkLoadedFrontend
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
                    |> clientFromEmail.checkView
                        (Test.Html.Query.has
                            [ Test.Html.Selector.text groupName
                            , Test.Html.Selector.text groupDescription
                            ]
                        )
            )
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start config "Create an event and get an email a day before it occurs"
        |> loginFromHomepage False
            session0
            session0
            emailAddress
            (\{ instructions, client } ->
                createGroupAndEvent
                    client
                    { groupName = "It's my Group!"
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo TF.startTime (Duration.days 3))
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                    instructions
                    |> TF.fastForward (Duration.days 1.999 |> Quantity.plus (Duration.hours 14))
                    |> TF.checkState
                        (\model ->
                            if gotReminder emailAddress model.httpRequests then
                                Err "Shouldn't have gotten an event notification yet"

                            else
                                Ok ()
                        )
                    |> TF.simulateTime (Duration.days 0.002)
                    |> TF.checkState
                        (\model ->
                            if gotReminder emailAddress model.httpRequests then
                                Ok ()

                            else
                                Err "Should have gotten an event notification"
                        )
            )
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "the@email.com"
      in
      TF.start config "Create an event and but don't get a notification if it's occurring within 24 hours"
        |> loginFromHomepage False
            session0
            session0
            emailAddress
            (\{ instructions, client } ->
                createGroupAndEvent
                    client
                    { groupName = "It's my Group!"
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc TF.startTime
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                    instructions
                    |> TF.fastForward (Duration.hours 1.99)
                    |> TF.simulateTime (Duration.hours 0.02)
                    |> TF.checkState
                        (\model ->
                            if gotReminder emailAddress model.httpRequests then
                                Err "Shouldn't have gotten an event notification"

                            else
                                Ok ()
                        )
            )
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
      TF.start config "Create an event and another user joins it and gets an event reminder"
        |> loginFromHomepage False
            session0
            session0
            emailAddress0
            (\{ instructions, client } ->
                createGroupAndEvent
                    client
                    { groupName = GroupName.toString groupName
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo TF.startTime Duration.day)
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                    instructions
            )
        |> loginFromHomepage False
            session1
            session1
            emailAddress1
            (\{ instructions, client } ->
                findSingleGroup
                    (\groupId inProgress2 ->
                        inProgress2
                            |> client.inputText Frontend.groupSearchId "my group!"
                            |> client.keyDownEvent Frontend.groupSearchId { keyCode = Ui.enterKeyCode }
                            |> shortWait
                            |> client.clickLink { href = Route.GroupRoute groupId groupName |> Route.encode }
                            |> shortWait
                            |> client.clickButton GroupPage.joinEventButtonId
                            |> shortWait
                            |> TF.fastForward (Duration.hours 14)
                            |> TF.simulateTime (Duration.seconds 30)
                            |> TF.checkState
                                (\model ->
                                    if gotReminder emailAddress1 model.httpRequests then
                                        Ok ()

                                    else
                                        Err "Should have gotten an event notification"
                                )
                    )
                    instructions
            )
    , createEventAndAnotherUserNotLoggedInJoinsIt
    , createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt
    , let
        connectAndLogin count =
            TF.connectFrontend
                (Lamdera.sessionIdFromString ("session " ++ String.fromInt count))
                (Unsafe.url Env.domain)
                windowSize
                (\( state, client ) ->
                    state
                        |> shortWait
                        |> client.clickButton Frontend.signUpOrLoginButtonId
                        |> client.inputText LoginForm.emailAddressInputId "my+good@email.eu"
                        |> client.clickButton LoginForm.submitButtonId
                        |> shortWait
                )
      in
      TF.start config "Rate limit login for a given email address"
        |> connectAndLogin 1
        |> connectAndLogin 2
        |> connectAndLogin 3
        |> connectAndLogin 4
        |> TF.checkState
            (\state2 ->
                if List.filterMap isLoginEmail state2.httpRequests |> List.length |> (==) 1 then
                    Ok ()

                else
                    Err "Only one email should have been sent"
            )
        |> TF.simulateTime (Duration.minutes 2)
        |> connectAndLogin 5
        |> TF.checkState
            (\state2 ->
                if List.filterMap isLoginEmail state2.httpRequests |> List.length |> (==) 2 then
                    Ok ()

                else
                    Err "Two emails should have been sent"
            )
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"
      in
      TF.start config "Rate limit login for a given session"
        |> TF.connectFrontend
            session0
            (Unsafe.url Env.domain)
            windowSize
            (\( state, client ) ->
                state
                    |> shortWait
                    |> client.clickButton Frontend.signUpOrLoginButtonId
                    |> client.inputText LoginForm.emailAddressInputId "a@email.eu"
                    |> client.clickButton LoginForm.submitButtonId
                    |> shortWait
                    |> client.inputText LoginForm.emailAddressInputId "b@email.eu"
                    |> client.clickButton LoginForm.submitButtonId
                    |> shortWait
                    |> client.inputText LoginForm.emailAddressInputId "c@email.eu"
                    |> client.clickButton LoginForm.submitButtonId
                    |> shortWait
                    |> client.inputText LoginForm.emailAddressInputId "d@email.eu"
                    |> client.clickButton LoginForm.submitButtonId
                    |> shortWait
                    |> client.inputText LoginForm.emailAddressInputId "e@email.eu"
                    |> client.clickButton LoginForm.submitButtonId
                    |> shortWait
                    |> TF.checkState
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
                    |> TF.simulateTime Duration.minute
                    |> client.inputText LoginForm.emailAddressInputId "e@email.eu"
                    |> client.clickButton LoginForm.submitButtonId
                    |> shortWait
                    |> TF.checkState
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
            )
    , let
        session0 =
            Lamdera.sessionIdFromString "session0"

        emailAddress =
            Unsafe.emailAddress "a@email.eu"
      in
      TF.start config "Rate limit delete account email"
        |> loginFromHomepage
            True
            session0
            session0
            emailAddress
            (\{ instructions, client } ->
                instructions
                    |> shortWait
                    |> client.clickLink { href = Route.encode Route.MyProfileRoute }
                    |> client.clickButton ProfilePage.deleteAccountButtonId
                    |> shortWait
                    |> client.clickButton ProfilePage.deleteAccountButtonId
                    |> shortWait
                    |> client.clickButton ProfilePage.deleteAccountButtonId
                    |> shortWait
                    |> client.clickButton ProfilePage.deleteAccountButtonId
                    |> shortWait
                    |> TF.checkState
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
                    |> TF.simulateTime (Duration.minutes 1.5)
                    |> client.clickButton ProfilePage.deleteAccountButtonId
                    |> shortWait
                    |> TF.checkState
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
            )
    , let
        sessionId =
            Lamdera.sessionIdFromString "sessionId"
      in
      TF.start config "Not logged in users can't create groups"
        |> TF.connectFrontend
            sessionId
            (Env.domain ++ Route.encode Route.HomepageRoute |> Unsafe.url)
            windowSize
            (\( instructions, client ) ->
                instructions
                    |> TF.sendToBackend
                        sessionId
                        client.clientId
                        (CreateGroupRequest
                            (Unsafe.groupName "group" |> Untrusted.untrust)
                            (Unsafe.description "description" |> Untrusted.untrust)
                            Group.PublicGroup
                        )
            )
        |> shortWait
        |> TF.checkBackend
            (\backend ->
                if Dict.isEmpty backend.groups then
                    Ok ()

                else
                    Err "No group should have been created"
            )
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
      TF.start config "Non-admin users can't delete groups"
        |> loginFromHomepage
            True
            sessionId
            sessionId
            emailAddress
            (\{ instructions, client } ->
                instructions |> createGroup client "group" "description"
            )
        |> shortWait
        |> loginFromHomepage
            False
            attackerSessionId
            attackerSessionId
            attackerEmailAddress
            (\{ instructions, client } ->
                findSingleGroup
                    (\groupId instructions2 ->
                        instructions2
                            |> TF.sendToBackend
                                sessionId
                                client.clientId
                                (GroupRequest groupId GroupPage.DeleteGroupAdminRequest)
                    )
                    instructions
            )
        |> shortWait
        |> TF.checkBackend
            (\backend ->
                if Dict.isEmpty backend.deletedGroups && Dict.size backend.groups == 1 then
                    Ok ()

                else
                    Err "No group should have been deleted"
            )
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
      TF.start config "Get new event notification"
        |> loginFromHomepage
            True
            sessionId
            sessionId
            emailAddress
            (\{ instructions, client } ->
                instructions
                    |> createGroup client (GroupName.toString groupName) "description"
                    |> shortWait
                    |> loginFromHomepage
                        False
                        subscriberSessionId
                        subscriberSessionId
                        subscriberEmail
                        (\a ->
                            findSingleGroup
                                (\groupId instructions2 ->
                                    instructions2
                                        |> shortWait
                                        |> a.client.inputText Frontend.groupSearchId "my group!"
                                        |> a.client.keyDownEvent Frontend.groupSearchId { keyCode = Ui.enterKeyCode }
                                        |> shortWait
                                        |> a.client.clickLink { href = Route.GroupRoute groupId groupName |> Route.encode }
                                        |> shortWait
                                        |> a.client.clickButton GroupPage.subscribeButtonId
                                )
                                a.instructions
                        )
                    |> shortWait
                    |> client.clickButton GroupPage.createNewEventId
                    |> client.inputText GroupPage.eventNameInputId "Event!"
                    |> client.inputText GroupPage.eventDescriptionInputId "Event description"
                    |> client.clickButton (GroupPage.eventMeetingTypeId GroupPage.MeetOnline)
                    |> client.inputText GroupPage.createEventStartDateId (Ui.datestamp (Date.fromRataDie 737485))
                    |> client.inputText GroupPage.createEventStartTimeId (Ui.timestamp 10 12)
                    |> client.inputText GroupPage.eventDurationId "1"
                    |> client.clickButton GroupPage.createEventSubmitId
                    |> shortWait
            )
        |> shortWait
        |> TF.checkState
            (\state ->
                case
                    ( Dict.toList state.model.groups
                    , List.filterMap isNewEventNotificationEmail state.httpRequests
                    )
                of
                    ( [ ( groupId, group ) ], [ newEventNotification ] ) ->
                        if
                            newEventNotification
                                == { emailAddress = subscriberEmail
                                   , groupId = groupId
                                   , groupName = Group.name group
                                   }
                        then
                            Ok ()

                        else
                            Err "Incorrect notification"

                    _ ->
                        Err "New event notification email not found"
            )
    , snapshotPages
    ]


shortWait =
    TF.simulateTime (Duration.milliseconds 100)


findSingleGroup :
    (Id GroupId
     -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
     -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    )
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
findSingleGroup continueWith inProgress =
    inProgress
        |> TF.andThen
            (\state ->
                case Dict.keys state.model.groups of
                    [ groupId ] ->
                        TF.continueWith state
                            |> continueWith groupId

                    keys ->
                        TF.continueWith state
                            |> TF.checkState
                                (\_ ->
                                    "Expected to find exactly one group, instead got "
                                        ++ String.fromInt (List.length keys)
                                        |> Err
                                )
            )


findUser :
    Name
    ->
        (Id UserId
         -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
findUser name continueWith inProgress =
    inProgress
        |> TF.andThen
            (\state ->
                case Dict.toList state.model.users |> List.find (\( _, user ) -> user.name == name) of
                    Just ( userId, _ ) ->
                        continueWith userId inProgress

                    Nothing ->
                        TF.continueWith state
                            |> TF.checkState
                                (\_ -> "Expected to find user named \"" ++ Name.toString name ++ "\"" |> Err)
            )


createEventAndAnotherUserNotLoggedInJoinsIt : TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
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
    TF.start config "Create an event and another user (who isn't logged in) joins it"
        |> loginFromHomepage False
            session0
            session0
            emailAddress0
            (\{ instructions, client } ->
                createGroupAndEvent
                    client
                    { groupName = GroupName.toString groupName
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo TF.startTime Duration.day)
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                    instructions
            )
        |> TF.connectFrontend session1
            (Env.domain ++ Route.encode Route.HomepageRoute |> Unsafe.url)
            windowSize
            (\( instructions, client ) ->
                findSingleGroup
                    (\groupId inProgress2 ->
                        inProgress2
                            |> shortWait
                            |> client.inputText Frontend.groupSearchId "my group!"
                            |> client.keyDownEvent Frontend.groupSearchId { keyCode = Ui.enterKeyCode }
                            |> shortWait
                            |> client.clickLink { href = Route.GroupRoute groupId groupName |> Route.encode }
                            |> shortWait
                            |> client.clickButton GroupPage.joinEventButtonId
                            |> shortWait
                            |> handleLoginForm
                                False
                                True
                                client
                                session1
                                emailAddress1
                                (\a ->
                                    a.instructions
                                        |> shortWait
                                        -- We are just clicking the leave button to test that we had joined the event.
                                        |> a.clientFromEmail.clickButton GroupPage.leaveEventButtonId
                                )
                    )
                    instructions
            )


createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt : TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
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
    TF.start config "Create an event and another user (who isn't logged in but has an account) joins it"
        |> loginFromHomepage False
            session0
            session0
            emailAddress0
            (\{ instructions, client } ->
                createGroupAndEvent
                    client
                    { groupName = GroupName.toString groupName
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo TF.startTime Duration.day)
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                    instructions
            )
        |> loginFromHomepage False
            session1
            session1
            emailAddress1
            (\{ instructions, clientFromEmail } ->
                instructions
                    |> shortWait
                    |> clientFromEmail.clickButton Frontend.logOutButtonId
                    |> TF.simulateTime Duration.minute
            )
        |> TF.connectFrontend session1
            (Env.domain ++ Route.encode Route.HomepageRoute |> Unsafe.url)
            windowSize
            (\( instructions, client ) ->
                findSingleGroup
                    (\groupId inProgress2 ->
                        inProgress2
                            |> shortWait
                            |> client.inputText Frontend.groupSearchId "my group!"
                            |> client.keyDownEvent Frontend.groupSearchId { keyCode = Ui.enterKeyCode }
                            |> shortWait
                            |> client.clickLink { href = Route.GroupRoute groupId groupName |> Route.encode }
                            |> shortWait
                            |> client.clickButton GroupPage.joinEventButtonId
                            |> shortWait
                            |> handleLoginForm
                                False
                                True
                                client
                                session1
                                emailAddress1
                                (\a ->
                                    a.instructions
                                        |> shortWait
                                        -- We are just clicking the leave button to test that we had joined the event.
                                        |> a.clientFromEmail.clickButton GroupPage.leaveEventButtonId
                                )
                    )
                    instructions
            )


createGroup :
    TF.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
createGroup loggedInClient groupName groupDescription state =
    state
        |> loggedInClient.clickLink { href = Route.encode Route.CreateGroupRoute }
        |> shortWait
        |> loggedInClient.inputText CreateGroupPage.nameInputId groupName
        |> loggedInClient.inputText CreateGroupPage.descriptionInputId groupDescription
        |> loggedInClient.clickButton (CreateGroupPage.groupVisibilityId Group.PublicGroup)
        |> loggedInClient.clickButton CreateGroupPage.submitButtonId
        |> shortWait


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
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
createGroupAndEvent loggedInClient { groupName, groupDescription, eventName, eventDescription, eventDate, eventHour, eventMinute, eventDuration } state =
    createGroup loggedInClient groupName groupDescription state
        |> loggedInClient.clickButton GroupPage.createNewEventId
        |> loggedInClient.inputText GroupPage.eventNameInputId eventName
        |> loggedInClient.inputText GroupPage.eventDescriptionInputId eventDescription
        |> loggedInClient.clickButton (GroupPage.eventMeetingTypeId GroupPage.MeetOnline)
        |> loggedInClient.inputText GroupPage.createEventStartDateId (Ui.datestamp eventDate)
        |> loggedInClient.inputText GroupPage.createEventStartTimeId (Ui.timestamp eventHour eventMinute)
        |> loggedInClient.inputText GroupPage.eventDurationId eventDuration
        |> loggedInClient.clickButton GroupPage.createEventSubmitId
        |> shortWait


snapshotPages : TF.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
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
    TF.start config "Snapshot pages"
        |> loginFromHomepage False
            (Lamdera.sessionIdFromString "sessionId0")
            (Lamdera.sessionIdFromString "sessionId0")
            emailAddress
            (\{ instructions, client } ->
                instructions
                    -- View miscellaneous pages
                    |> client.clickLink { href = Route.encode Route.FrequentQuestionsRoute }
                    |> shortWait
                    |> client.snapshotView { name = "FAQ page" }
                    |> client.clickLink { href = Route.encode Route.CodeOfConductRoute }
                    |> shortWait
                    |> client.snapshotView { name = "Code of conduct page" }
                    |> client.clickLink { href = Route.encode Route.TermsOfServiceRoute }
                    |> shortWait
                    |> client.snapshotView { name = "Terms of service page" }
                    |> client.clickLink { href = Route.encode Route.PrivacyRoute }
                    |> shortWait
                    |> client.snapshotView { name = "Privacy page" }
                    -- View my groups without group
                    |> client.clickLink { href = Route.encode Route.MyGroupsRoute }
                    |> shortWait
                    |> client.snapshotView { name = "My groups page" }
                    -- Create group
                    |> client.clickLink { href = Route.encode Route.CreateGroupRoute }
                    |> shortWait
                    |> client.snapshotView { name = "Create group page" }
                    |> client.clickButton CreateGroupPage.submitButtonId
                    |> shortWait
                    |> client.snapshotView { name = "Fail to create group" }
                    |> client.inputText CreateGroupPage.nameInputId (GroupName.toString groupName)
                    |> client.inputText CreateGroupPage.descriptionInputId "groupDescription"
                    |> client.clickButton (CreateGroupPage.groupVisibilityId Group.PublicGroup)
                    |> shortWait
                    |> client.snapshotView { name = "Create group page with fields filled" }
                    |> client.clickButton CreateGroupPage.submitButtonId
                    |> shortWait
                    |> client.snapshotView { name = "Group page" }
                    |> client.clickButton GroupPage.createNewEventId
                    |> shortWait
                    -- Create group event
                    |> client.snapshotView { name = "Create event page" }
                    |> client.clickButton GroupPage.createEventSubmitId
                    |> shortWait
                    |> client.snapshotView { name = "Fail to create event" }
                    |> client.inputText GroupPage.eventNameInputId "First event!"
                    |> client.inputText GroupPage.eventDescriptionInputId "Hey this is my cool first event! I'm so excited to host it and I hope a bunch of people join. We're going to have lots of fun doing stuff!"
                    |> client.clickButton (GroupPage.eventMeetingTypeId GroupPage.MeetOnline)
                    |> client.inputText GroupPage.createEventStartDateId (Ui.datestamp (Date.fromCalendarDate 1970 Jan 2))
                    |> client.inputText GroupPage.createEventStartTimeId (Ui.timestamp 0 1)
                    |> client.inputText GroupPage.eventDurationId "2"
                    |> shortWait
                    |> client.snapshotView { name = "Create event page with fields filled" }
                    |> client.clickButton GroupPage.createEventSubmitId
                    |> shortWait
                    |> client.snapshotView { name = "Group page with new event" }
                    |> client.clickButton GroupPage.showAttendeesButtonId
                    |> shortWait
                    |> client.snapshotView { name = "Group page with new event and show attendees" }
                    |> client.clickButton GroupPage.hideAttendeesButtonId
                    |> shortWait
                    -- View default user profile
                    |> findUser
                        Name.anonymous
                        (\userId instructions2 ->
                            instructions2 |> client.clickLink { href = Route.encode (Route.UserRoute userId Name.anonymous) }
                        )
                    |> shortWait
                    |> client.snapshotView { name = "Default user profile page" }
                    -- View my groups with group
                    |> client.clickLink { href = Route.encode Route.MyGroupsRoute }
                    |> shortWait
                    |> client.snapshotView { name = "My groups page with group" }
                    -- Edit profile
                    |> client.clickLink { href = Route.encode Route.MyProfileRoute }
                    |> shortWait
                    |> client.snapshotView { name = "Profile page" }
                    |> client.inputText ProfilePage.nameTextInputId (Name.toString name)
                    |> TF.simulateTime (Duration.seconds 3)
                    |> client.inputText ProfilePage.descriptionTextInputId "This is my description text that I have so thoughtfully written to take up at least one or two lines of spaces in the web page it's viewed on."
                    |> TF.simulateTime (Duration.seconds 3)
                    |> client.inputText Frontend.groupSearchId (GroupName.toString groupName)
                    |> TF.simulateTime (Duration.seconds 3)
                    |> client.snapshotView { name = "Profile page with changes and search prepared" }
                    -- Search for group
                    |> client.keyDownEvent Frontend.groupSearchId { keyCode = Ui.enterKeyCode }
                    |> shortWait
                    |> client.snapshotView { name = "Search page" }
                    |> findSingleGroup
                        (\groupId instructions2 ->
                            instructions2
                                |> client.clickLink { href = Route.encode (Route.GroupRoute groupId groupName) }
                        )
                    |> shortWait
                    |> client.clickButton GroupPage.showAttendeesButtonId
                    |> shortWait
                    |> client.snapshotView { name = "Group page with updated profile" }
                    |> TF.fastForward (Duration.hours 23)
                    |> TF.simulateTime Duration.minute
                    |> client.snapshotView { name = "Group page with less than 1 hour to event" }
                    |> TF.fastForward Duration.hour
                    |> TF.simulateTime Duration.minute
                    |> client.snapshotView { name = "Group page with event ongoing" }
                    |> TF.fastForward (Duration.hours 3)
                    |> TF.simulateTime Duration.minute
                    |> client.snapshotView { name = "Group page with event ended" }
                    -- View user profile with edits
                    |> findUser
                        name
                        (\userId instructions2 ->
                            instructions2 |> client.clickLink { href = Route.encode (Route.UserRoute userId name) }
                        )
                    |> shortWait
                    |> client.snapshotView { name = "User profile page with edits" }
            )
