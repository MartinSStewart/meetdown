port module Frontend exposing (CropImageData, Effects, Subscriptions, app, createApp, groupSearchId, logOutButtonId, signUpOrLoginButtonId)

import AssocList as Dict
import AssocSet as Set
import Browser exposing (UrlRequest(..))
import Browser.Dom
import Browser.Events
import Browser.Navigation
import CreateGroupForm
import Description
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Element.Region
import File
import File.Select
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import GroupName exposing (GroupName)
import GroupPage
import Html.Attributes
import Id exposing (ButtonId(..), GroupId, Id, UserId)
import Lamdera
import List.Nonempty
import LoginForm
import MockFile
import Pixels exposing (Pixels)
import Process
import ProfileForm
import ProfileImage
import Quantity exposing (Quantity)
import Route exposing (Route(..))
import Task
import Time
import TimeZone
import Types exposing (..)
import Ui
import Untrusted
import Url exposing (Url)
import Url.Parser exposing ((</>))


port supermario_copy_to_clipboard_to_js : String -> Cmd msg


port martinsstewart_crop_image_to_js :
    { requestId : Int
    , imageUrl : String
    , cropX : Int
    , cropY : Int
    , cropWidth : Int
    , cropHeight : Int
    , width : Int
    , height : Int
    }
    -> Cmd msg


type alias CropImageData =
    { requestId : Int
    , imageUrl : String
    , cropX : Quantity Int Pixels
    , cropY : Quantity Int Pixels
    , cropWidth : Quantity Int Pixels
    , cropHeight : Quantity Int Pixels
    , width : Quantity Int Pixels
    , height : Quantity Int Pixels
    }


port martinsstewart_crop_image_from_js : ({ requestId : Int, croppedImageUrl : String } -> msg) -> Sub msg


type alias Effects cmd =
    { batch : List cmd -> cmd
    , none : cmd
    , sendToBackend : ToBackend -> cmd
    , navigationPushUrl : NavigationKey -> String -> cmd
    , navigationReplaceUrl : NavigationKey -> String -> cmd
    , navigationPushRoute : NavigationKey -> Route -> cmd
    , navigationReplaceRoute : NavigationKey -> Route -> cmd
    , navigationLoad : String -> cmd
    , getTime : (Time.Posix -> FrontendMsg) -> cmd
    , wait : Duration -> FrontendMsg -> cmd
    , selectFile : List String -> (MockFile.File -> FrontendMsg) -> cmd
    , copyToClipboard : String -> cmd
    , cropImage : CropImageData -> cmd
    , fileToUrl : (String -> FrontendMsg) -> MockFile.File -> cmd
    , getElement : (Result Browser.Dom.Error Browser.Dom.Element -> FrontendMsg) -> String -> cmd
    , getWindowSize : (Quantity Int Pixels -> Quantity Int Pixels -> FrontendMsg) -> cmd
    , getTimeZone : (Result TimeZone.Error ( String, Time.Zone ) -> FrontendMsg) -> cmd
    }


type alias Subscriptions sub =
    { batch : List sub -> sub
    , timeEvery : Duration -> (Time.Posix -> FrontendMsg) -> sub
    , onResize : (Quantity Int Pixels -> Quantity Int Pixels -> FrontendMsg) -> sub
    , cropImageFromJs : ({ requestId : Int, croppedImageUrl : String } -> FrontendMsg) -> sub
    }


allEffects : Effects (Cmd FrontendMsg)
allEffects =
    { batch = Cmd.batch
    , none = Cmd.none
    , sendToBackend = Lamdera.sendToBackend
    , navigationPushUrl =
        \navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.pushUrl key string

                MockNavigationKey ->
                    Cmd.none
    , navigationReplaceUrl =
        \navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.replaceUrl key string

                MockNavigationKey ->
                    Cmd.none
    , navigationPushRoute =
        \navigationKey route ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.pushUrl key (Route.encode route)

                MockNavigationKey ->
                    Cmd.none
    , navigationReplaceRoute =
        \navigationKey route ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.replaceUrl key (Route.encode route)

                MockNavigationKey ->
                    Cmd.none
    , navigationLoad = Browser.Navigation.load
    , getTime = \msg -> Time.now |> Task.perform msg
    , wait = \duration msg -> Process.sleep (Duration.inMilliseconds duration) |> Task.perform (always msg)
    , selectFile = \mimeTypes msg -> File.Select.file mimeTypes (MockFile.RealFile >> msg)
    , copyToClipboard = supermario_copy_to_clipboard_to_js
    , cropImage =
        \data ->
            martinsstewart_crop_image_to_js
                { requestId = data.requestId
                , imageUrl = data.imageUrl
                , cropX = Pixels.inPixels data.cropX
                , cropY = Pixels.inPixels data.cropY
                , cropWidth = Pixels.inPixels data.cropWidth
                , cropHeight = Pixels.inPixels data.cropHeight
                , width = Pixels.inPixels data.width
                , height = Pixels.inPixels data.height
                }
    , fileToUrl =
        \msg file ->
            case file of
                MockFile.RealFile realFile ->
                    File.toUrl realFile |> Task.perform msg

                MockFile.MockFile _ ->
                    Cmd.none
    , getElement = \msg elementId -> Browser.Dom.getElement elementId |> Task.attempt msg
    , getWindowSize =
        \msg ->
            Browser.Dom.getViewport
                |> Task.perform
                    (\{ scene } ->
                        msg (Pixels.pixels (round scene.width)) (Pixels.pixels (round scene.height))
                    )
    , getTimeZone = \msg -> TimeZone.getZone |> Task.attempt msg
    }


allSubscriptions : Subscriptions (Sub FrontendMsg)
allSubscriptions =
    { batch = Sub.batch
    , timeEvery = \duration msg -> Time.every (Duration.inMilliseconds duration) msg
    , onResize = \msg -> Browser.Events.onResize (\w h -> msg (Pixels.pixels w) (Pixels.pixels h))
    , cropImageFromJs = martinsstewart_crop_image_from_js
    }


app =
    let
        app_ =
            createApp allEffects allSubscriptions
    in
    Lamdera.frontend
        { init = \url navKey -> app_.init url (RealNavigationKey navKey)
        , onUrlRequest = app_.onUrlRequest
        , onUrlChange = app_.onUrlChange
        , update = app_.update
        , updateFromBackend = app_.updateFromBackend
        , subscriptions = app_.subscriptions
        , view = app_.view
        }


createApp :
    Effects cmd
    -> Subscriptions sub
    ->
        { init : Url -> NavigationKey -> ( FrontendModel, cmd )
        , onUrlRequest : UrlRequest -> FrontendMsg
        , onUrlChange : Url -> FrontendMsg
        , update : FrontendMsg -> FrontendModel -> ( FrontendModel, cmd )
        , updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, cmd )
        , subscriptions : FrontendModel -> sub
        , view : FrontendModel -> Browser.Document FrontendMsg
        }
createApp cmds subs =
    { init = \url key -> init cmds url key
    , onUrlRequest = UrlClicked
    , onUrlChange = UrlChanged
    , update = update cmds
    , updateFromBackend = updateFromBackend cmds
    , subscriptions = subscriptions subs
    , view = view
    }


subscriptions : Subscriptions sub -> FrontendModel -> sub
subscriptions subs _ =
    subs.batch
        [ subs.cropImageFromJs CroppedImage
        , subs.onResize GotWindowSize
        ]


init : Effects cmd -> Url -> NavigationKey -> ( FrontendModel, cmd )
init cmds url key =
    let
        ( route, token ) =
            Url.Parser.parse Route.decode url |> Maybe.withDefault ( HomepageRoute, Route.NoToken )
    in
    ( Loading
        { navigationKey = key
        , route = route
        , routeToken = token
        , windowSize = Nothing
        , time = Nothing
        , timezone = Nothing
        }
    , cmds.batch
        [ cmds.getTime GotTime
        , cmds.getWindowSize GotWindowSize
        , cmds.getTimeZone GotTimeZone
        ]
    )


initLoadedFrontend :
    Effects cmd
    -> NavigationKey
    -> Quantity Int Pixels
    -> Quantity Int Pixels
    -> Route
    -> Route.Token
    -> Time.Posix
    -> Time.Zone
    -> ( LoadedFrontend, cmd )
initLoadedFrontend cmds navigationKey windowWidth windowHeight route maybeLoginToken time timezone =
    let
        login =
            case maybeLoginToken of
                Route.LoginToken loginToken ->
                    LoginWithTokenRequest loginToken

                Route.DeleteUserToken deleteUserToken ->
                    DeleteUserRequest deleteUserToken

                Route.NoToken ->
                    CheckLoginRequest

        model : LoadedFrontend
        model =
            { navigationKey = navigationKey
            , loginStatus = LoginStatusPending
            , route = route
            , cachedGroups = Dict.empty
            , cachedUsers = Dict.empty
            , time = time
            , timezone = timezone
            , lastConnectionCheck = time
            , loginForm =
                { email = ""
                , pressedSubmitEmail = False
                , emailSent = Nothing
                }
            , logs = Nothing
            , hasLoginTokenError = False
            , groupForm = CreateGroupForm.init
            , groupCreated = False
            , accountDeletedResult = Nothing
            , searchBox = ""
            , searchList = []
            , windowWidth = windowWidth
            , windowHeight = windowHeight
            , groupPage = Dict.empty
            }

        ( model2, cmd ) =
            routeRequest cmds route model
    in
    ( model2
    , cmds.batch
        [ cmds.batch [ cmds.sendToBackend login, cmd ]
        , cmds.navigationReplaceUrl navigationKey (Route.encode route)
        ]
    )


tryInitLoadedFrontend : Effects cmd -> LoadingFrontend -> ( FrontendModel, cmd )
tryInitLoadedFrontend cmds loading =
    Maybe.map3
        (\( windowWidth, windowHeight ) time zone ->
            initLoadedFrontend
                cmds
                loading.navigationKey
                windowWidth
                windowHeight
                loading.route
                loading.routeToken
                time
                zone
                |> Tuple.mapFirst Loaded
        )
        loading.windowSize
        loading.time
        loading.timezone
        |> Maybe.withDefault ( Loading loading, cmds.none )


gotTimeZone : Result error ( a, Time.Zone ) -> { b | timezone : Maybe Time.Zone } -> { b | timezone : Maybe Time.Zone }
gotTimeZone result model =
    case result of
        Ok ( _, timezone ) ->
            { model | timezone = Just timezone }

        Err _ ->
            { model | timezone = Just Time.utc }


update : Effects cmd -> FrontendMsg -> FrontendModel -> ( FrontendModel, cmd )
update cmds msg model =
    case model of
        Loading loading ->
            case msg of
                GotTime time ->
                    tryInitLoadedFrontend cmds { loading | time = Just time }

                GotWindowSize width height ->
                    tryInitLoadedFrontend cmds { loading | windowSize = Just ( width, height ) }

                GotTimeZone result ->
                    gotTimeZone result loading |> tryInitLoadedFrontend cmds

                _ ->
                    ( model, cmds.none )

        Loaded loaded ->
            updateLoaded cmds msg loaded |> Tuple.mapFirst Loaded


routeRequest : Effects cmd -> Route -> LoadedFrontend -> ( LoadedFrontend, cmd )
routeRequest cmds route model =
    case route of
        MyGroupsRoute ->
            ( model, cmds.sendToBackend GetMyGroupsRequest )

        GroupRoute groupId _ ->
            case Dict.get groupId model.cachedGroups of
                Just (GroupFound group) ->
                    let
                        ownerId =
                            Group.ownerId group
                    in
                    case Dict.get ownerId model.cachedUsers of
                        Just _ ->
                            ( model, cmds.none )

                        Nothing ->
                            ( { model | cachedUsers = Dict.insert ownerId UserRequestPending model.cachedUsers }
                            , cmds.sendToBackend (GetUserRequest ownerId)
                            )

                Just GroupRequestPending ->
                    ( model, cmds.none )

                Just GroupNotFound ->
                    ( { model | cachedGroups = Dict.insert groupId GroupRequestPending model.cachedGroups }
                    , cmds.sendToBackend (GetGroupRequest groupId)
                    )

                Nothing ->
                    ( { model | cachedGroups = Dict.insert groupId GroupRequestPending model.cachedGroups }
                    , cmds.sendToBackend (GetGroupRequest groupId)
                    )

        HomepageRoute ->
            ( model, cmds.none )

        AdminRoute ->
            ( model, cmds.none )

        CreateGroupRoute ->
            ( model, cmds.none )

        MyProfileRoute ->
            ( model, cmds.none )

        SearchGroupsRoute searchText ->
            ( model, cmds.sendToBackend (SearchGroupsRequest searchText) )


updateLoaded : Effects cmd -> FrontendMsg -> LoadedFrontend -> ( LoadedFrontend, cmd )
updateLoaded cmds msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    let
                        route =
                            Url.Parser.parse Route.decode url
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault HomepageRoute
                    in
                    ( { model | route = route }
                    , cmds.navigationPushUrl model.navigationKey (Route.encode route)
                    )

                External url ->
                    ( model, cmds.navigationLoad url )

        UrlChanged url ->
            let
                route =
                    Url.Parser.parse Route.decode url
                        |> Maybe.map Tuple.first
                        |> Maybe.withDefault HomepageRoute
            in
            routeRequest cmds route { model | route = route }

        GotTime time ->
            ( { model | time = time }, cmds.none )

        PressedLogin ->
            case model.loginStatus of
                LoginStatusPending ->
                    ( model, cmds.none )

                NotLoggedIn notLoggedIn ->
                    ( { model | loginStatus = NotLoggedIn { notLoggedIn | showLogin = True } }, cmds.none )

                LoggedIn _ ->
                    ( model, cmds.none )

        PressedLogout ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False } }
            , cmds.sendToBackend LogoutRequest
            )

        TypedEmail text ->
            ( { model | loginForm = LoginForm.typedEmail text model.loginForm }, cmds.none )

        PressedSubmitEmail ->
            LoginForm.submitForm cmds model.route model.loginForm
                |> Tuple.mapFirst (\a -> { model | loginForm = a })

        PressedCreateGroup ->
            ( model, cmds.navigationPushRoute model.navigationKey CreateGroupRoute )

        GroupFormMsg groupFormMsg ->
            let
                ( newModel, outMsg ) =
                    CreateGroupForm.update groupFormMsg model.groupForm
                        |> Tuple.mapFirst (\a -> { model | groupForm = a })
            in
            case outMsg of
                CreateGroupForm.Submitted submitted ->
                    ( newModel
                    , CreateGroupRequest
                        (Untrusted.untrust submitted.name)
                        (Untrusted.untrust submitted.description)
                        submitted.visibility
                        |> cmds.sendToBackend
                    )

                CreateGroupForm.NoChange ->
                    ( newModel, cmds.none )

        ProfileFormMsg profileFormMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( newModel, effects ) =
                            ProfileForm.update
                                model
                                { wait = \duration waitMsg -> cmds.wait duration (ProfileFormMsg waitMsg)
                                , none = cmds.none
                                , changeName = ChangeNameRequest >> cmds.sendToBackend
                                , changeDescription = ChangeDescriptionRequest >> cmds.sendToBackend
                                , changeEmailAddress = ChangeEmailAddressRequest >> cmds.sendToBackend
                                , selectFile =
                                    \mimeTypes fileMsg ->
                                        cmds.selectFile mimeTypes (fileMsg >> ProfileFormMsg)
                                , getFileContents =
                                    \fileMsg file -> cmds.fileToUrl (fileMsg >> ProfileFormMsg) file
                                , setCanvasImage = cmds.cropImage
                                , sendDeleteAccountEmail = cmds.sendToBackend SendDeleteUserEmailRequest
                                , getElement =
                                    \getElementMsg id -> cmds.getElement (getElementMsg >> ProfileFormMsg) id
                                , batch = cmds.batch
                                }
                                profileFormMsg
                                loggedIn.profileForm
                    in
                    ( { model | loginStatus = LoggedIn { loggedIn | profileForm = newModel } }
                    , effects
                    )

                NotLoggedIn _ ->
                    ( model, cmds.none )

                LoginStatusPending ->
                    ( model, cmds.none )

        CroppedImage imageData ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case ProfileImage.customImage imageData.croppedImageUrl of
                        Ok profileImage ->
                            let
                                newModel =
                                    ProfileForm.cropImageResponse imageData loggedIn.profileForm
                            in
                            ( { model | loginStatus = LoggedIn { loggedIn | profileForm = newModel } }
                            , Untrusted.untrust profileImage
                                |> ChangeProfileImageRequest
                                |> cmds.sendToBackend
                            )

                        Err _ ->
                            ( model, cmds.none )

                NotLoggedIn _ ->
                    ( model, cmds.none )

                LoginStatusPending ->
                    ( model, cmds.none )

        TypedSearchText searchText ->
            ( { model | searchBox = searchText }, cmds.none )

        SubmittedSearchBox ->
            ( model, cmds.navigationPushRoute model.navigationKey (SearchGroupsRoute model.searchBox) )

        GroupPageMsg groupPageMsg ->
            case model.route of
                GroupRoute groupId _ ->
                    case Dict.get groupId model.cachedGroups of
                        Just (GroupFound group) ->
                            let
                                ( newModel, effects ) =
                                    GroupPage.update
                                        { none = cmds.none
                                        , changeName = ChangeGroupNameRequest groupId >> cmds.sendToBackend
                                        , changeDescription =
                                            ChangeGroupDescriptionRequest groupId >> cmds.sendToBackend
                                        , createEvent =
                                            \a b c d e -> CreateEventRequest groupId a b c d e |> cmds.sendToBackend
                                        , leaveEvent = \eventId -> LeaveEventRequest groupId eventId |> cmds.sendToBackend
                                        , joinEvent = \eventId -> JoinEventRequest groupId eventId |> cmds.sendToBackend
                                        }
                                        model
                                        group
                                        (case model.loginStatus of
                                            LoggedIn loggedIn ->
                                                Just loggedIn.userId

                                            LoginStatusPending ->
                                                Nothing

                                            NotLoggedIn _ ->
                                                Nothing
                                        )
                                        groupPageMsg
                                        (Dict.get groupId model.groupPage |> Maybe.withDefault GroupPage.init)
                            in
                            ( { model | groupPage = Dict.insert groupId newModel model.groupPage }, effects )

                        _ ->
                            ( model, cmds.none )

                _ ->
                    ( model, cmds.none )

        GotWindowSize width height ->
            ( { model | windowWidth = width, windowHeight = height }, cmds.none )

        GotTimeZone _ ->
            ( model, cmds.none )


updateFromBackend : Effects cmd -> ToFrontend -> FrontendModel -> ( FrontendModel, cmd )
updateFromBackend cmds msg model =
    case model of
        Loading _ ->
            ( model, cmds.none )

        Loaded loaded ->
            updateLoadedFromBackend cmds msg loaded |> Tuple.mapFirst Loaded


updateLoadedFromBackend : Effects cmd -> ToFrontend -> LoadedFrontend -> ( LoadedFrontend, cmd )
updateLoadedFromBackend cmds msg model =
    case msg of
        GetGroupResponse groupId result ->
            ( { model
                | cachedGroups =
                    Dict.insert groupId
                        (case result of
                            GroupFound_ group _ ->
                                GroupFound group

                            GroupNotFound_ ->
                                GroupNotFound
                        )
                        model.cachedGroups
                , cachedUsers =
                    case result of
                        GroupFound_ _ users ->
                            Dict.union (Dict.map (\_ v -> UserFound v) users) model.cachedUsers

                        GroupNotFound_ ->
                            model.cachedUsers
              }
            , case result of
                GroupFound_ groupData _ ->
                    cmds.navigationReplaceRoute
                        model.navigationKey
                        (GroupRoute groupId (Group.name groupData))

                GroupNotFound_ ->
                    cmds.none
            )

        GetUserResponse userId result ->
            ( { model
                | cachedUsers =
                    Dict.insert
                        userId
                        (case result of
                            Ok user ->
                                UserFound user

                            Err () ->
                                UserNotFound
                        )
                        model.cachedUsers
              }
            , cmds.none
            )

        LoginWithTokenResponse result ->
            case result of
                Ok ( userId, user ) ->
                    ( { model
                        | loginStatus =
                            LoggedIn
                                { userId = userId
                                , emailAddress = user.emailAddress
                                , profileForm = ProfileForm.init
                                , myGroups = Nothing
                                , adminState = Nothing
                                }
                        , cachedUsers = Dict.insert userId (userToFrontend user |> UserFound) model.cachedUsers
                      }
                    , cmds.none
                    )

                Err () ->
                    ( { model | hasLoginTokenError = True, loginStatus = NotLoggedIn { showLogin = True } }, cmds.none )

        CheckLoginResponse loginStatus ->
            case loginStatus of
                Just ( userId, user ) ->
                    ( { model
                        | loginStatus =
                            LoggedIn
                                { userId = userId
                                , emailAddress = user.emailAddress
                                , profileForm = ProfileForm.init
                                , myGroups = Nothing
                                , adminState = Nothing
                                }
                        , cachedUsers = Dict.insert userId (userToFrontend user |> UserFound) model.cachedUsers
                      }
                    , cmds.none
                    )

                Nothing ->
                    ( { model | loginStatus = NotLoggedIn { showLogin = False } }
                    , cmds.none
                    )

        GetAdminDataResponse logs ->
            ( { model | logs = Just logs }, cmds.none )

        CreateGroupResponse result ->
            case model.loginStatus of
                LoggedIn _ ->
                    case result of
                        Ok ( groupId, groupData ) ->
                            ( { model
                                | cachedGroups =
                                    Dict.insert groupId (GroupFound groupData) model.cachedGroups
                                , groupForm = CreateGroupForm.init
                              }
                            , cmds.navigationReplaceRoute
                                model.navigationKey
                                (GroupRoute groupId (Group.name groupData))
                            )

                        Err error ->
                            ( { model | groupForm = CreateGroupForm.submitFailed error model.groupForm }
                            , cmds.none
                            )

                NotLoggedIn _ ->
                    ( model, cmds.none )

                LoginStatusPending ->
                    ( model, cmds.none )

        LogoutResponse ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False } }, cmds.none )

        ChangeNameResponse name ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.update
                                loggedIn.userId
                                (Maybe.map (Types.mapUserCache (\a -> { a | name = name })))
                                model.cachedUsers
                      }
                    , cmds.none
                    )

                LoginStatusPending ->
                    ( model, cmds.none )

                NotLoggedIn _ ->
                    ( model, cmds.none )

        ChangeDescriptionResponse description ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.update
                                loggedIn.userId
                                (Maybe.map (Types.mapUserCache (\a -> { a | description = description })))
                                model.cachedUsers
                      }
                    , cmds.none
                    )

                LoginStatusPending ->
                    ( model, cmds.none )

                NotLoggedIn _ ->
                    ( model, cmds.none )

        ChangeEmailAddressResponse emailAddress ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model | loginStatus = LoggedIn { loggedIn | emailAddress = emailAddress } }
                    , cmds.none
                    )

                LoginStatusPending ->
                    ( model, cmds.none )

                NotLoggedIn _ ->
                    ( model, cmds.none )

        DeleteUserResponse result ->
            case result of
                Ok () ->
                    ( { model
                        | loginStatus = NotLoggedIn { showLogin = False }
                        , accountDeletedResult = Just result
                      }
                    , cmds.none
                    )

                Err () ->
                    ( { model | accountDeletedResult = Just result }, cmds.none )

        ChangeProfileImageResponse profileImage ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.update
                                loggedIn.userId
                                (Maybe.map (Types.mapUserCache (\a -> { a | profileImage = profileImage })))
                                model.cachedUsers
                      }
                    , cmds.none
                    )

                LoginStatusPending ->
                    ( model, cmds.none )

                NotLoggedIn _ ->
                    ( model, cmds.none )

        GetMyGroupsResponse myGroups ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    { model
                        | loginStatus =
                            LoggedIn { loggedIn | myGroups = List.map Tuple.first myGroups |> Set.fromList |> Just }
                        , cachedGroups =
                            List.foldl
                                (\( groupId, group ) cached ->
                                    Dict.insert groupId (GroupFound group) cached
                                )
                                model.cachedGroups
                                myGroups
                    }

                NotLoggedIn _ ->
                    model

                LoginStatusPending ->
                    model
            , cmds.none
            )

        SearchGroupsResponse _ groups ->
            ( { model
                | cachedGroups =
                    List.foldl
                        (\( groupId, group ) cached ->
                            Dict.insert groupId (GroupFound group) cached
                        )
                        model.cachedGroups
                        groups
                , searchList = List.map Tuple.first groups
              }
            , cmds.none
            )

        ChangeGroupNameResponse groupId groupName ->
            ( { model
                | cachedGroups =
                    Dict.update groupId
                        (Maybe.map
                            (\a ->
                                case a of
                                    GroupFound group ->
                                        Group.withName groupName group |> GroupFound

                                    GroupNotFound ->
                                        GroupNotFound

                                    GroupRequestPending ->
                                        GroupRequestPending
                            )
                        )
                        model.cachedGroups
                , groupPage = Dict.update groupId (Maybe.map GroupPage.savedName) model.groupPage
              }
            , cmds.none
            )

        ChangeGroupDescriptionResponse groupId description ->
            ( { model
                | cachedGroups =
                    Dict.update groupId
                        (Maybe.map
                            (\a ->
                                case a of
                                    GroupFound group ->
                                        Group.withDescription description group |> GroupFound

                                    GroupNotFound ->
                                        GroupNotFound

                                    GroupRequestPending ->
                                        GroupRequestPending
                            )
                        )
                        model.cachedGroups
                , groupPage = Dict.update groupId (Maybe.map GroupPage.savedDescription) model.groupPage
              }
            , cmds.none
            )

        CreateEventResponse groupId result ->
            ( { model
                | cachedGroups =
                    case result of
                        Ok event ->
                            Dict.update groupId
                                (Maybe.map
                                    (\a ->
                                        case a of
                                            GroupFound group ->
                                                Group.addEvent event group
                                                    |> Result.withDefault group
                                                    |> GroupFound

                                            GroupNotFound ->
                                                GroupNotFound

                                            GroupRequestPending ->
                                                GroupRequestPending
                                    )
                                )
                                model.cachedGroups

                        Err _ ->
                            model.cachedGroups
                , groupPage = Dict.update groupId (Maybe.map (GroupPage.addedNewEvent result)) model.groupPage
              }
            , cmds.none
            )

        JoinEventResponse groupId eventId result ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    case result of
                        Ok () ->
                            { model
                                | cachedGroups =
                                    Dict.update groupId
                                        (Maybe.map
                                            (\a ->
                                                case a of
                                                    GroupFound group ->
                                                        Group.joinEvent loggedIn.userId eventId group |> GroupFound

                                                    GroupNotFound ->
                                                        GroupNotFound

                                                    GroupRequestPending ->
                                                        GroupRequestPending
                                            )
                                        )
                                        model.cachedGroups
                                , groupPage =
                                    Dict.update
                                        groupId
                                        (Maybe.map (GroupPage.joinOrLeaveResponse eventId result))
                                        model.groupPage
                            }

                        Err () ->
                            { model
                                | groupPage =
                                    Dict.update
                                        groupId
                                        (Maybe.map (GroupPage.joinOrLeaveResponse eventId result))
                                        model.groupPage
                            }

                LoginStatusPending ->
                    model

                NotLoggedIn _ ->
                    model
            , cmds.none
            )

        LeaveEventResponse groupId eventId result ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    case result of
                        Ok () ->
                            { model
                                | cachedGroups =
                                    Dict.update groupId
                                        (Maybe.map
                                            (\a ->
                                                case a of
                                                    GroupFound group ->
                                                        Group.leaveEvent loggedIn.userId eventId group |> GroupFound

                                                    GroupNotFound ->
                                                        GroupNotFound

                                                    GroupRequestPending ->
                                                        GroupRequestPending
                                            )
                                        )
                                        model.cachedGroups
                                , groupPage =
                                    Dict.update
                                        groupId
                                        (Maybe.map (GroupPage.joinOrLeaveResponse eventId result))
                                        model.groupPage
                            }

                        Err () ->
                            { model
                                | groupPage =
                                    Dict.update
                                        groupId
                                        (Maybe.map (GroupPage.joinOrLeaveResponse eventId result))
                                        model.groupPage
                            }

                LoginStatusPending ->
                    model

                NotLoggedIn _ ->
                    model
            , cmds.none
            )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Meetdown"
    , body =
        [ Ui.css
        , Element.layout
            []
            (case model of
                Loading _ ->
                    Element.none

                Loaded loaded ->
                    viewLoaded loaded
            )
        ]
    }


viewLoaded : LoadedFrontend -> Element FrontendMsg
viewLoaded model =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.inFront
            (if model.hasLoginTokenError then
                Element.el
                    [ Element.width Element.fill
                    , Element.height Element.fill
                    , Element.Background.color <| Element.rgb 1 1 1
                    ]
                    (Element.text "Sorry, the link you used is either invalid or has expired.")

             else
                Element.none
            )
        ]
        [ case model.loginStatus of
            LoginStatusPending ->
                Element.none

            _ ->
                header (isLoggedIn model) model.route model.searchBox
        , Element.el
            [ Element.Region.mainContent, Element.width Element.fill, Element.height Element.fill ]
            (case model.loginStatus of
                NotLoggedIn { showLogin } ->
                    if showLogin then
                        LoginForm.view model.loginForm

                    else
                        viewPage model

                LoggedIn _ ->
                    viewPage model

                LoginStatusPending ->
                    Element.none
            )
        ]


loginRequiredPage : LoadedFrontend -> (LoggedIn_ -> Element FrontendMsg) -> Element FrontendMsg
loginRequiredPage model pageView =
    case model.loginStatus of
        LoggedIn loggedIn ->
            pageView loggedIn

        NotLoggedIn _ ->
            LoginForm.view model.loginForm

        LoginStatusPending ->
            Element.none


getCachedUser : Id UserId -> LoadedFrontend -> Maybe FrontendUser
getCachedUser userId loadedFrontend =
    case Dict.get userId loadedFrontend.cachedUsers of
        Just (UserFound user) ->
            Just user

        _ ->
            Nothing


viewPage : LoadedFrontend -> Element FrontendMsg
viewPage model =
    case model.route of
        HomepageRoute ->
            Element.paragraph
                [ Element.padding 8 ]
                [ Element.text "A place to find people with shared interests. We don't sell your data, we don't show ads, we don't charge money, and it's all open source." ]

        GroupRoute groupId _ ->
            case Dict.get groupId model.cachedGroups of
                Just (GroupFound group) ->
                    case getCachedUser (Group.ownerId group) model of
                        Just owner ->
                            GroupPage.view
                                model.time
                                model.timezone
                                owner
                                group
                                (Dict.get groupId model.groupPage |> Maybe.withDefault GroupPage.init)
                                (case model.loginStatus of
                                    LoggedIn loggedIn ->
                                        Just loggedIn.userId

                                    NotLoggedIn _ ->
                                        Nothing

                                    LoginStatusPending ->
                                        Nothing
                                )
                                |> Element.map GroupPageMsg

                        Nothing ->
                            Element.text "Error loading group owner"

                Just GroupNotFound ->
                    Element.text "Group not found"

                Just GroupRequestPending ->
                    Element.text "Loading group"

                Nothing ->
                    Element.none

        AdminRoute ->
            loginRequiredPage
                model
                (\_ -> Element.text "Admin panel")

        CreateGroupRoute ->
            loginRequiredPage
                model
                (\_ ->
                    CreateGroupForm.view model.groupForm
                        |> Element.el
                            [ Element.width <| Element.maximum 800 Element.fill
                            , Element.centerX
                            ]
                        |> Element.map GroupFormMsg
                )

        MyGroupsRoute ->
            loginRequiredPage model (myGroupsView model)

        MyProfileRoute ->
            loginRequiredPage
                model
                (\loggedIn ->
                    case Dict.get loggedIn.userId model.cachedUsers of
                        Just (UserFound user) ->
                            ProfileForm.view
                                model
                                { name = user.name
                                , description = user.description
                                , emailAddress = loggedIn.emailAddress
                                , profileImage = user.profileImage
                                }
                                loggedIn.profileForm
                                |> Element.el
                                    [ Element.width <| Element.maximum 800 Element.fill
                                    , Element.centerX
                                    ]
                                |> Element.map ProfileFormMsg

                        Just UserRequestPending ->
                            Element.text "Loading user"

                        Just UserNotFound ->
                            Element.text "Failed to find user"

                        Nothing ->
                            Element.text "Failed to find user"
                )

        SearchGroupsRoute searchText ->
            searchGroupsView searchText model


searchGroupsView : String -> LoadedFrontend -> Element FrontendMsg
searchGroupsView searchText model =
    Element.column
        [ Element.padding 8
        , Element.width <| Element.maximum 800 Element.fill
        , Element.centerX
        , Element.spacing 8
        ]
        [ if searchText == "" then
            Element.none

          else
            Element.paragraph [] [ Element.text <| "Search results for \"" ++ searchText ++ "\"" ]
        , Element.column
            [ Element.width Element.fill, Element.spacing 8 ]
            (getGroupsFromIds model.searchList model
                |> List.map
                    (\( groupId, group ) ->
                        Element.link
                            [ Ui.inputBackground False
                            , Element.Border.rounded 4
                            , Element.Border.width 2
                            , Element.Border.color Ui.linkColor
                            , Element.padding 8
                            , Element.width Element.fill
                            , Ui.inputFocusClass
                            ]
                            { url = Route.encode (GroupRoute groupId (Group.name group))
                            , label =
                                Element.column
                                    [ Element.width Element.fill, Element.spacing 8 ]
                                    [ Group.name group
                                        |> GroupName.toString
                                        |> Element.text
                                        |> List.singleton
                                        |> Element.paragraph [ Element.Font.bold ]
                                    , Group.description group
                                        |> Description.toString
                                        |> Element.text
                                        |> List.singleton
                                        |> Element.paragraph []
                                    ]
                            }
                    )
            )
        ]


getGroupsFromIds : List GroupId -> LoadedFrontend -> List ( GroupId, Group )
getGroupsFromIds groups model =
    List.filterMap
        (\groupId ->
            Dict.get groupId model.cachedGroups
                |> Maybe.andThen
                    (\group ->
                        case group of
                            GroupFound groupFound ->
                                Just ( groupId, groupFound )

                            GroupNotFound ->
                                Nothing

                            GroupRequestPending ->
                                Nothing
                    )
        )
        groups


myGroupsView : LoadedFrontend -> LoggedIn_ -> Element FrontendMsg
myGroupsView model loggedIn =
    case loggedIn.myGroups of
        Just myGroups ->
            let
                myGroupsList =
                    getGroupsFromIds (Set.toList myGroups) model
                        |> List.map
                            (\( groupId, group ) ->
                                Element.row
                                    []
                                    [ Ui.routeLink
                                        (GroupRoute groupId (Group.name group))
                                        (Group.name group |> GroupName.toString)
                                    ]
                            )

                mySubscriptionsList =
                    []
            in
            Element.column
                [ Element.padding 8, Element.width Element.fill, Element.spacing 8 ]
                [ Ui.title "My groups"
                , if List.isEmpty myGroupsList && List.isEmpty mySubscriptionsList then
                    Element.paragraph
                        []
                        [ Element.text "You don't have any groups. Get started by "
                        , Ui.routeLink CreateGroupRoute "creating one"
                        , Element.text " or "
                        , Ui.routeLink (SearchGroupsRoute "") "joining one."
                        ]

                  else
                    Element.column
                        [ Element.width Element.fill, Element.spacing 8 ]
                        [ Ui.section "Groups I created"
                            (if List.isEmpty myGroupsList then
                                Element.paragraph []
                                    [ Element.text "You haven't created any groups. "
                                    , Ui.routeLink CreateGroupRoute "You can do that here."
                                    ]

                             else
                                Element.column [ Element.spacing 8 ] myGroupsList
                            )
                        , Ui.section "Groups I've joined"
                            (if List.isEmpty mySubscriptionsList then
                                Element.paragraph []
                                    [ Element.text "You haven't joined any groups. "
                                    , Ui.routeLink (SearchGroupsRoute "") "You can do that here."
                                    ]

                             else
                                Element.column [ Element.spacing 8 ] []
                            )
                        ]
                ]

        Nothing ->
            Element.paragraph [] [ Element.text "Loading..." ]


isLoggedIn : LoadedFrontend -> Bool
isLoggedIn model =
    case model.loginStatus of
        LoggedIn _ ->
            True

        NotLoggedIn _ ->
            False

        LoginStatusPending ->
            False


header : Bool -> Route -> String -> Element FrontendMsg
header isLoggedIn_ route searchText =
    Element.row
        [ Element.width Element.fill
        , Element.Background.color <| Element.rgb 0.8 0.8 0.8
        , Element.paddingEach { left = 4, right = 0, top = 0, bottom = 0 }
        , Element.Region.navigation
        ]
        [ Element.Input.text
            [ Element.width <| Element.maximum 400 Element.fill
            , Element.paddingEach { left = 32, right = 8, top = 4, bottom = 4 }
            , Ui.onEnter SubmittedSearchBox
            , Id.htmlIdToString groupSearchId |> Html.Attributes.id |> Element.htmlAttribute
            , Element.inFront
                (Element.el
                    [ Element.Font.size 16
                    , Element.moveDown 6
                    , Element.moveRight 4
                    , Element.alpha 0.8
                    ]
                    (Element.text "🔍")
                )
            ]
            { text = searchText
            , onChange = TypedSearchText
            , placeholder = Nothing
            , label = Element.Input.labelHidden "Search groups"
            }
        , Element.row
            [ Element.alignRight ]
            (if isLoggedIn_ then
                [ if route == CreateGroupRoute then
                    Element.none

                  else
                    Ui.headerLink
                        { route = CreateGroupRoute
                        , label = "Create group"
                        }
                , if route == MyGroupsRoute then
                    Element.none

                  else
                    Ui.headerLink
                        { route = MyGroupsRoute
                        , label = "My groups"
                        }
                , if route == MyProfileRoute then
                    Element.none

                  else
                    Ui.headerLink
                        { route = MyProfileRoute
                        , label = "Profile"
                        }
                , Ui.headerButton
                    logOutButtonId
                    { onPress = PressedLogout
                    , label = "Log out"
                    }
                ]

             else
                [ Ui.headerButton
                    signUpOrLoginButtonId
                    { onPress = PressedLogin
                    , label = "Sign up/Login"
                    }
                ]
            )
        ]


groupSearchId =
    Id.textInputId "headerGroupSearch"


logOutButtonId =
    Id.buttonId "headerLogOut"


signUpOrLoginButtonId =
    Id.buttonId "headerSignUpOrLogin"
