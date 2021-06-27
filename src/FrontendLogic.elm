module FrontendLogic exposing (CropImageData, Effects, Subscriptions, createApp, groupSearchId, logOutButtonId, signUpOrLoginButtonId)

import AdminPage
import AssocList as Dict
import AssocSet as Set
import Browser exposing (UrlRequest(..))
import Browser.Dom
import Colors
import CreateGroupPage
import DictExtra as Dict
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Element.Region
import Env
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import GroupPage
import Html.Attributes
import Id exposing (ButtonId(..), GroupId, Id, UserId)
import LoginForm
import MarkdownThemed
import MockFile
import Pixels exposing (Pixels)
import Privacy
import ProfileImage
import ProfilePage
import Quantity exposing (Quantity)
import Route exposing (Route(..))
import SearchPage
import Terms
import Time
import TimeZone
import Types exposing (..)
import Ui
import Untrusted
import Url exposing (Url)
import Url.Parser exposing ((</>))
import UserPage


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
        , subs.timeEvery Duration.minute GotTime
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
                Route.LoginToken loginToken maybeJoinEvent ->
                    LoginWithTokenRequest loginToken maybeJoinEvent

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
            , groupForm = CreateGroupPage.init
            , groupCreated = False
            , accountDeletedResult = Nothing
            , searchText = ""
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
                Just (ItemCached group) ->
                    let
                        ownerId =
                            Group.ownerId group
                    in
                    case Dict.get ownerId model.cachedUsers of
                        Just _ ->
                            ( model, cmds.none )

                        Nothing ->
                            ( { model | cachedUsers = Dict.insert ownerId ItemRequestPending model.cachedUsers }
                            , cmds.sendToBackend (GetUserRequest ownerId)
                            )

                Just ItemRequestPending ->
                    ( model, cmds.none )

                Just ItemDoesNotExist ->
                    ( { model | cachedGroups = Dict.insert groupId ItemRequestPending model.cachedGroups }
                    , cmds.sendToBackend (GetGroupRequest groupId)
                    )

                Nothing ->
                    ( { model | cachedGroups = Dict.insert groupId ItemRequestPending model.cachedGroups }
                    , cmds.sendToBackend (GetGroupRequest groupId)
                    )

        HomepageRoute ->
            ( model, cmds.none )

        AdminRoute ->
            checkAdminState cmds model

        CreateGroupRoute ->
            ( model, cmds.sendToBackend GetMyGroupsRequest )

        MyProfileRoute ->
            ( model, cmds.none )

        SearchGroupsRoute searchText ->
            ( model, cmds.sendToBackend (SearchGroupsRequest searchText) )

        UserRoute userId _ ->
            case Dict.get userId model.cachedUsers of
                Just _ ->
                    ( model, cmds.none )

                Nothing ->
                    ( { model | cachedUsers = Dict.insert userId ItemRequestPending model.cachedUsers }
                    , cmds.sendToBackend (GetUserRequest userId)
                    )

        PrivacyRoute ->
            ( model, cmds.none )

        TermsOfServiceRoute ->
            ( model, cmds.none )

        CodeOfConductRoute ->
            ( model, cmds.none )


checkAdminState : Effects cmd -> LoadedFrontend -> ( LoadedFrontend, cmd )
checkAdminState cmds model =
    case model.loginStatus of
        LoggedIn loggedIn_ ->
            if loggedIn_.adminState == AdminCacheNotRequested && loggedIn_.isAdmin then
                ( { model | loginStatus = LoggedIn { loggedIn_ | adminState = AdminCachePending } }
                , cmds.sendToBackend GetAdminDataRequest
                )

            else
                ( model, cmds.none )

        NotLoggedIn _ ->
            ( model, cmds.none )

        LoginStatusPending ->
            ( model, cmds.none )


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
                    ( { model | route = route, hasLoginTokenError = False } |> closeLoginForm
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
                    ( { model
                        | loginStatus = NotLoggedIn { notLoggedIn | showLogin = True }
                        , hasLoginTokenError = False
                      }
                    , cmds.none
                    )

                LoggedIn _ ->
                    ( model, cmds.none )

        PressedLogout ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing } }
            , cmds.sendToBackend LogoutRequest
            )

        TypedEmail text ->
            ( { model | loginForm = LoginForm.typedEmail text model.loginForm }, cmds.none )

        PressedSubmitLogin ->
            case model.loginStatus of
                NotLoggedIn { joiningEvent } ->
                    LoginForm.submitForm cmds model.route joiningEvent model.loginForm
                        |> Tuple.mapFirst (\a -> { model | loginForm = a })

                LoginStatusPending ->
                    ( model, cmds.none )

                LoggedIn _ ->
                    ( model, cmds.none )

        PressedCreateGroup ->
            ( model, cmds.navigationPushRoute model.navigationKey CreateGroupRoute )

        CreateGroupPageMsg groupFormMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case loggedIn.myGroups of
                        Just myGroups ->
                            let
                                ( newModel, outMsg ) =
                                    CreateGroupPage.update (Set.isEmpty myGroups) groupFormMsg model.groupForm
                                        |> Tuple.mapFirst (\a -> { model | groupForm = a })
                            in
                            case outMsg of
                                CreateGroupPage.Submitted submitted ->
                                    ( newModel
                                    , CreateGroupRequest
                                        (Untrusted.untrust submitted.name)
                                        (Untrusted.untrust submitted.description)
                                        submitted.visibility
                                        |> cmds.sendToBackend
                                    )

                                CreateGroupPage.NoChange ->
                                    ( newModel, cmds.none )

                        Nothing ->
                            ( model, cmds.none )

                NotLoggedIn _ ->
                    ( model, cmds.none )

                LoginStatusPending ->
                    ( model, cmds.none )

        ProfileFormMsg profileFormMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( newModel, effects ) =
                            ProfilePage.update
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
                                    ProfilePage.cropImageResponse imageData loggedIn.profileForm
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
            ( { model | searchText = searchText }, cmds.none )

        SubmittedSearchBox ->
            ( closeLoginForm model, cmds.navigationPushRoute model.navigationKey (SearchGroupsRoute model.searchText) )

        GroupPageMsg groupPageMsg ->
            case model.route of
                GroupRoute groupId _ ->
                    case Dict.get groupId model.cachedGroups of
                        Just (ItemCached group) ->
                            let
                                ( newModel, effects, { joinEvent } ) =
                                    GroupPage.update
                                        { none = cmds.none
                                        , changeName = ChangeGroupNameRequest groupId >> cmds.sendToBackend
                                        , changeDescription =
                                            ChangeGroupDescriptionRequest groupId >> cmds.sendToBackend
                                        , createEvent =
                                            \a b c d e f -> CreateEventRequest groupId a b c d e f |> cmds.sendToBackend
                                        , leaveEvent = \eventId -> LeaveEventRequest groupId eventId |> cmds.sendToBackend
                                        , joinEvent = \eventId -> JoinEventRequest groupId eventId |> cmds.sendToBackend
                                        , editEvent =
                                            \a b c d e f g -> EditEventRequest groupId a b c d e f g |> cmds.sendToBackend
                                        , changeCancellationStatus =
                                            \a b -> ChangeEventCancellationStatusRequest groupId a b |> cmds.sendToBackend
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
                            ( { model
                                | groupPage = Dict.insert groupId newModel model.groupPage
                                , loginStatus =
                                    case model.loginStatus of
                                        NotLoggedIn notLoggedIn ->
                                            case joinEvent of
                                                Just eventId ->
                                                    NotLoggedIn { notLoggedIn | showLogin = True, joiningEvent = Just ( groupId, eventId ) }

                                                Nothing ->
                                                    model.loginStatus

                                        _ ->
                                            model.loginStatus
                              }
                            , effects
                            )

                        _ ->
                            ( model, cmds.none )

                _ ->
                    ( model, cmds.none )

        GotWindowSize width height ->
            ( { model | windowWidth = width, windowHeight = height }, cmds.none )

        GotTimeZone _ ->
            ( model, cmds.none )

        PressedCancelLogin ->
            ( closeLoginForm model, cmds.none )


closeLoginForm : LoadedFrontend -> LoadedFrontend
closeLoginForm model =
    { model
        | loginStatus =
            case model.loginStatus of
                NotLoggedIn notLoggedIn ->
                    NotLoggedIn { notLoggedIn | showLogin = False, joiningEvent = Nothing }

                LoginStatusPending ->
                    LoginStatusPending

                LoggedIn loggedIn_ ->
                    LoggedIn loggedIn_
    }


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
                                ItemCached group

                            GroupNotFound_ ->
                                ItemDoesNotExist
                        )
                        model.cachedGroups
                , cachedUsers =
                    case result of
                        GroupFound_ _ users ->
                            Dict.union (Dict.map (\_ v -> ItemCached v) users) model.cachedUsers

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
                                ItemCached user

                            Err () ->
                                ItemDoesNotExist
                        )
                        model.cachedUsers
              }
            , cmds.none
            )

        LoginWithTokenResponse result ->
            case result of
                Ok { userId, user, isAdmin } ->
                    { model
                        | loginStatus =
                            LoggedIn
                                { userId = userId
                                , emailAddress = user.emailAddress
                                , profileForm = ProfilePage.init
                                , myGroups = Nothing
                                , adminState = AdminCacheNotRequested
                                , isAdmin = isAdmin
                                }
                        , cachedUsers = Dict.insert userId (userToFrontend user |> ItemCached) model.cachedUsers
                    }
                        |> checkAdminState cmds

                Err () ->
                    ( { model
                        | hasLoginTokenError = True
                        , loginStatus = NotLoggedIn { showLogin = True, joiningEvent = Nothing }
                      }
                    , cmds.none
                    )

        CheckLoginResponse loginStatus ->
            case loginStatus of
                Just { userId, user, isAdmin } ->
                    { model
                        | loginStatus =
                            LoggedIn
                                { userId = userId
                                , emailAddress = user.emailAddress
                                , profileForm = ProfilePage.init
                                , myGroups = Nothing
                                , adminState = AdminCacheNotRequested
                                , isAdmin = isAdmin
                                }
                        , cachedUsers = Dict.insert userId (userToFrontend user |> ItemCached) model.cachedUsers
                    }
                        |> checkAdminState cmds

                Nothing ->
                    ( { model | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing } }
                    , cmds.none
                    )

        GetAdminDataResponse adminData ->
            case model.loginStatus of
                LoggedIn loggedIn_ ->
                    ( { model | loginStatus = LoggedIn { loggedIn_ | adminState = AdminCached adminData } }
                    , cmds.none
                    )

                LoginStatusPending ->
                    ( model, cmds.none )

                NotLoggedIn _ ->
                    ( model, cmds.none )

        CreateGroupResponse result ->
            case model.loginStatus of
                LoggedIn _ ->
                    case result of
                        Ok ( groupId, groupData ) ->
                            ( { model
                                | cachedGroups =
                                    Dict.insert groupId (ItemCached groupData) model.cachedGroups
                                , groupForm = CreateGroupPage.init
                              }
                            , cmds.navigationReplaceRoute
                                model.navigationKey
                                (GroupRoute groupId (Group.name groupData))
                            )

                        Err error ->
                            ( { model | groupForm = CreateGroupPage.submitFailed error model.groupForm }
                            , cmds.none
                            )

                NotLoggedIn _ ->
                    ( model, cmds.none )

                LoginStatusPending ->
                    ( model, cmds.none )

        LogoutResponse ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing } }, cmds.none )

        ChangeNameResponse name ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.updateJust
                                loggedIn.userId
                                (Types.mapCache (\a -> { a | name = name }))
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
                            Dict.updateJust
                                loggedIn.userId
                                (Types.mapCache (\a -> { a | description = description }))
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
                        | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing }
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
                            Dict.updateJust
                                loggedIn.userId
                                (Types.mapCache (\a -> { a | profileImage = profileImage }))
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
                                    Dict.insert groupId (ItemCached group) cached
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
                            Dict.insert groupId (ItemCached group) cached
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
                    Dict.updateJust groupId
                        (Types.mapCache (Group.withName groupName))
                        model.cachedGroups
                , groupPage = Dict.updateJust groupId GroupPage.savedName model.groupPage
              }
            , cmds.none
            )

        ChangeGroupDescriptionResponse groupId description ->
            ( { model
                | cachedGroups =
                    Dict.updateJust groupId
                        (Types.mapCache (Group.withDescription description))
                        model.cachedGroups
                , groupPage = Dict.updateJust groupId GroupPage.savedDescription model.groupPage
              }
            , cmds.none
            )

        CreateEventResponse groupId result ->
            ( { model
                | cachedGroups =
                    case result of
                        Ok event ->
                            Dict.updateJust groupId
                                (Types.mapCache (\group -> Group.addEvent event group |> Result.withDefault group))
                                model.cachedGroups

                        Err _ ->
                            model.cachedGroups
                , groupPage = Dict.updateJust groupId (GroupPage.addedNewEvent result) model.groupPage
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
                                    Dict.updateJust groupId
                                        (Types.mapCache
                                            (\group ->
                                                case Group.joinEvent loggedIn.userId eventId group of
                                                    Ok newGroup ->
                                                        newGroup

                                                    Err _ ->
                                                        group
                                            )
                                        )
                                        model.cachedGroups
                                , groupPage =
                                    Dict.updateJust
                                        groupId
                                        (GroupPage.joinEventResponse eventId result)
                                        model.groupPage
                            }

                        Err _ ->
                            { model
                                | groupPage =
                                    Dict.updateJust
                                        groupId
                                        (GroupPage.joinEventResponse eventId result)
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
                                    Dict.updateJust groupId
                                        (Types.mapCache (Group.leaveEvent loggedIn.userId eventId))
                                        model.cachedGroups
                                , groupPage =
                                    Dict.updateJust
                                        groupId
                                        (GroupPage.leaveEventResponse eventId result)
                                        model.groupPage
                            }

                        Err () ->
                            { model
                                | groupPage =
                                    Dict.updateJust
                                        groupId
                                        (GroupPage.leaveEventResponse eventId result)
                                        model.groupPage
                            }

                LoginStatusPending ->
                    model

                NotLoggedIn _ ->
                    model
            , cmds.none
            )

        EditEventResponse groupId eventId result backendTime ->
            ( { model
                | cachedGroups =
                    case result of
                        Ok event ->
                            Dict.updateJust groupId
                                (Types.mapCache
                                    (\group ->
                                        case Group.editEvent backendTime eventId (\_ -> event) group of
                                            Ok ( _, newGroup ) ->
                                                newGroup

                                            Err _ ->
                                                group
                                    )
                                )
                                model.cachedGroups

                        Err _ ->
                            model.cachedGroups
                , groupPage =
                    Dict.updateJust groupId (GroupPage.editEventResponse result) model.groupPage
              }
            , cmds.none
            )

        ChangeEventCancellationStatusResponse groupId eventId result backendTime ->
            ( { model
                | cachedGroups =
                    case result of
                        Ok cancellationStatus ->
                            Dict.updateJust groupId
                                (Types.mapCache
                                    (\group ->
                                        case
                                            Group.editCancellationStatus
                                                backendTime
                                                eventId
                                                cancellationStatus
                                                group
                                        of
                                            Ok newGroup ->
                                                newGroup

                                            Err _ ->
                                                group
                                    )
                                )
                                model.cachedGroups

                        Err _ ->
                            model.cachedGroups
                , groupPage =
                    Dict.updateJust groupId (GroupPage.editCancellationStatusResponse eventId result) model.groupPage
              }
            , cmds.none
            )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Meetdown"
    , body =
        [ Ui.css
        , Element.layoutWith
            { options = [ Element.noStaticStyleSheet ] }
            [ Ui.defaultFontSize, Ui.defaultFont, Ui.defaultFontColor ]
            (case model of
                Loading _ ->
                    Element.none

                Loaded loaded ->
                    viewLoaded loaded
            )
        ]
    }


isMobile : { a | windowWidth : Quantity Int Pixels } -> Bool
isMobile { windowWidth } =
    windowWidth |> Quantity.lessThan (Pixels.pixels 600)


viewLoaded : LoadedFrontend -> Element FrontendMsg
viewLoaded model =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ case model.loginStatus of
            LoginStatusPending ->
                Element.none

            LoggedIn loggedIn ->
                if ProfilePage.imageEditorIsActive loggedIn.profileForm then
                    Element.none

                else
                    header (isMobile model) (Just loggedIn) model.route model.searchText

            NotLoggedIn _ ->
                header (isMobile model) Nothing model.route model.searchText
        , Element.el
            [ Element.Region.mainContent
            , Element.width Element.fill
            , Element.height Element.fill
            ]
            (if model.hasLoginTokenError then
                Element.column
                    (Element.centerY :: Ui.pageContentAttributes ++ [ Element.spacing 16 ])
                    [ Element.paragraph
                        [ Element.Font.center ]
                        [ Element.text "The link you used is either invalid or has expired." ]
                    , Element.el
                        [ Element.centerX ]
                        (Ui.linkButton { route = Route.HomepageRoute, label = "Go to homepage" })
                    ]

             else
                case model.loginStatus of
                    NotLoggedIn { showLogin, joiningEvent } ->
                        if showLogin then
                            LoginForm.view joiningEvent model.cachedGroups model.loginForm

                        else
                            viewPage model

                    LoggedIn _ ->
                        viewPage model

                    LoginStatusPending ->
                        Element.none
            )
        , footer (isMobile model) model.route
        ]


loginRequiredPage : LoadedFrontend -> (LoggedIn_ -> Element FrontendMsg) -> Element FrontendMsg
loginRequiredPage model pageView =
    case model.loginStatus of
        LoggedIn loggedIn ->
            pageView loggedIn

        NotLoggedIn { joiningEvent } ->
            LoginForm.view joiningEvent model.cachedGroups model.loginForm

        LoginStatusPending ->
            Element.none


getCachedUser : Id UserId -> LoadedFrontend -> Maybe FrontendUser
getCachedUser userId loadedFrontend =
    case Dict.get userId loadedFrontend.cachedUsers of
        Just (ItemCached user) ->
            Just user

        _ ->
            Nothing


viewPage : LoadedFrontend -> Element FrontendMsg
viewPage model =
    case model.route of
        HomepageRoute ->
            Element.column
                [ Element.padding 8, Element.width Element.fill, Element.spacing 30 ]
                [ Element.el [ Element.paddingEach { top = 40, right = 0, bottom = 20, left = 0 }, Element.centerX ] <|
                    Element.image
                        [ Element.width <| (Element.fill |> Element.maximum 650) ]
                        { src = "/homepage-hero.jpg", description = "Two people on a video conference" }
                , Element.paragraph
                    [ Element.Font.center ]
                    [ Element.text "A place to join groups of people with shared interests." ]
                , Element.paragraph
                    [ Element.Font.center ]
                    [ Element.text " We don't sell your data, we don't show ads, and it's free." ]
                , searchInputLarge model.searchText
                ]

        GroupRoute groupId _ ->
            case Dict.get groupId model.cachedGroups of
                Just (ItemCached group) ->
                    case getCachedUser (Group.ownerId group) model of
                        Just owner ->
                            GroupPage.view
                                (isMobile model)
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
                            Ui.loadingView

                Just ItemDoesNotExist ->
                    Ui.loadingError "Group not found"

                Just ItemRequestPending ->
                    Ui.loadingView

                Nothing ->
                    Element.none

        AdminRoute ->
            loginRequiredPage model (AdminPage.view model.timezone)

        CreateGroupRoute ->
            loginRequiredPage
                model
                (\loggedIn ->
                    case loggedIn.myGroups of
                        Just myGroups ->
                            CreateGroupPage.view (isMobile model) (Set.isEmpty myGroups) model.groupForm
                                |> Element.map CreateGroupPageMsg

                        Nothing ->
                            Ui.loadingView
                )

        MyGroupsRoute ->
            loginRequiredPage model (myGroupsView model)

        MyProfileRoute ->
            loginRequiredPage
                model
                (\loggedIn ->
                    case Dict.get loggedIn.userId model.cachedUsers of
                        Just (ItemCached user) ->
                            ProfilePage.view
                                model
                                { name = user.name
                                , description = user.description
                                , emailAddress = loggedIn.emailAddress
                                , profileImage = user.profileImage
                                }
                                loggedIn.profileForm
                                |> Element.map ProfileFormMsg

                        Just ItemRequestPending ->
                            Ui.loadingView

                        Just ItemDoesNotExist ->
                            Ui.loadingError "User not found"

                        Nothing ->
                            Ui.loadingError "User not found"
                )

        SearchGroupsRoute searchText ->
            SearchPage.view searchText model

        UserRoute userId _ ->
            case getCachedUser userId model of
                Just user ->
                    UserPage.view user

                Nothing ->
                    Ui.loadingView

        PrivacyRoute ->
            Element.column
                Ui.pageContentAttributes
                [ Ui.title "Privacy"
                , MarkdownThemed.render False Privacy.text
                ]

        TermsOfServiceRoute ->
            Element.column
                Ui.pageContentAttributes
                [ Ui.title "Terms of service"
                , MarkdownThemed.render False Terms.text
                ]

        CodeOfConductRoute ->
            Element.column
                Ui.pageContentAttributes
                [ Ui.title "Code of conduct"
                , Element.paragraph []
                    [ Element.text "The most important rule is, "
                    , Element.el [ Element.Font.bold ] (Element.text "don't be a jerk")
                    , Element.text "."
                    ]
                , Element.paragraph [] [ Element.text "Here is some guidance in order to fulfill the \"don't be a jerk\" rule:" ]
                , Element.paragraph [] [ Element.text "• Respect people regardless of their race, gender, sexual identity, nationality, appearance, or related characteristics." ]
                , Element.paragraph
                    []
                    [ Element.text "• Be respectful to the group organizer. They put in the time to coordinate an event and they are willing to invite strangers. Don't betray their trust in you!" ]
                , Element.paragraph
                    []
                    [ Element.text "• To group organizers: Make people feel included. It's hard for people to participate if they feel like an outsider." ]
                , Element.paragraph
                    []
                    [ Element.text "• If someone is being a jerk that is not an excuse to be a jerk back. Ask them to stop, and if that doesn't work, avoid them and explain the problem here "
                    , Ui.mailToLink Env.contactEmailAddress (Just "Moderation help request")
                    , Element.text "."
                    ]
                ]


myGroupsView : LoadedFrontend -> LoggedIn_ -> Element FrontendMsg
myGroupsView model loggedIn =
    case loggedIn.myGroups of
        Just myGroups ->
            let
                myGroupsList : List (Element msg)
                myGroupsList =
                    SearchPage.getGroupsFromIds (Set.toList myGroups) model
                        |> List.map
                            (\( groupId, group ) ->
                                SearchPage.groupPreview model.time groupId group
                            )

                mySubscriptionsList =
                    []
            in
            Element.column
                Ui.pageContentAttributes
                [ Ui.title "My groups"
                , if List.isEmpty myGroupsList && List.isEmpty mySubscriptionsList then
                    Element.paragraph
                        []
                        [ Element.text "You don't have any groups. Get started by "
                        , Ui.routeLink CreateGroupRoute "creating one"
                        , Element.text "."

                        --, Element.text " or "
                        --, Ui.routeLink (SearchGroupsRoute "") "joining one."
                        ]

                  else
                    Element.column
                        [ Element.width Element.fill, Element.spacing 8 ]
                        [ if List.isEmpty myGroupsList then
                            Element.paragraph []
                                [ Element.text "You haven't created any groups. "
                                , Ui.routeLink CreateGroupRoute "You can do that here."
                                ]

                          else
                            Element.column [ Element.spacing 8, Element.width Element.fill ] myGroupsList

                        --, Ui.section "Events I've joined"
                        --    (if List.isEmpty mySubscriptionsList then
                        --        Element.paragraph []
                        --            [ Element.text "You haven't joined any events. "
                        --            , Ui.routeLink (SearchGroupsRoute "") "You can do that here."
                        --            ]
                        --
                        --     else
                        --        Element.column [ Element.spacing 8 ] []
                        --    )
                        ]
                ]

        Nothing ->
            Ui.loadingView


searchInput : String -> Element FrontendMsg
searchInput searchText =
    Element.Input.text
        [ Element.width (Element.maximum 400 Element.fill)
        , Element.Border.rounded 5
        , Element.Border.color Colors.darkGrey
        , Element.paddingEach { left = 24, right = 8, top = 4, bottom = 4 }
        , Ui.onEnter SubmittedSearchBox
        , Id.htmlIdToString groupSearchId |> Html.Attributes.id |> Element.htmlAttribute
        , Element.inFront
            (Element.el
                [ Element.Font.size 12
                , Element.moveDown 6
                , Element.moveRight 4
                , Element.alpha 0.8
                , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                ]
                (Element.text "🔍")
            )
        ]
        { text = searchText
        , onChange = TypedSearchText
        , placeholder = Nothing
        , label = Element.Input.labelHidden "Search for groups"
        }


searchInputLarge : String -> Element FrontendMsg
searchInputLarge searchText =
    Element.row
        [ Element.width <| Element.maximum 400 Element.fill
        , Element.centerX
        ]
        [ Element.Input.text
            [ Element.Border.roundEach { topLeft = 5, bottomLeft = 5, bottomRight = 0, topRight = 0 }
            , Element.Border.color Colors.darkGrey
            , Element.Border.widthEach { bottom = 1, left = 1, right = 0, top = 1 }
            , Element.paddingEach { left = 30, right = 8, top = 8, bottom = 8 }
            , Ui.onEnter SubmittedSearchBox
            , Id.htmlIdToString groupSearchLargeId |> Html.Attributes.id |> Element.htmlAttribute
            , Element.inFront
                (Element.el
                    [ Element.Font.size 14
                    , Element.moveDown 9
                    , Element.moveRight 6
                    , Element.alpha 0.8
                    , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                    ]
                    (Element.text "🔍")
                )
            ]
            { text = searchText
            , onChange = TypedSearchText
            , placeholder = Nothing
            , label = Element.Input.labelHidden "Search for groups"
            }
        , Element.Input.button
            [ Element.Background.color Ui.submitColor
            , Element.Border.roundEach { topLeft = 0, bottomLeft = 0, bottomRight = 5, topRight = 5 }
            , Element.height Element.fill
            , Element.Font.color Colors.white
            , Element.paddingXY 16 0
            ]
            { onPress = Just SubmittedSearchBox
            , label = Element.text "Search"
            }
        ]


header : Bool -> Maybe LoggedIn_ -> Route -> String -> Element FrontendMsg
header isMobile_ maybeLoggedIn route searchText =
    Element.column [ Element.width Element.fill, Element.spacing 10, Element.padding 10 ]
        [ Element.row
            [ Element.width Element.fill
            , Element.paddingEach { left = 4, right = 0, top = 0, bottom = 0 }
            , Element.Region.navigation
            , Element.spacing 10
            ]
            [ if isMobile_ then
                Element.none

              else
                Element.link [ Element.paddingEach { left = 0, right = 10, top = 0, bottom = 0 } ]
                    { url = "/"
                    , label =
                        Element.row [ Element.spacing 10 ]
                            [ Element.image
                                [ Element.width <| Element.px 30 ]
                                { src = "/meetdown-logo.png", description = "Meetdown logo" }
                            , Element.text "Meetdown"
                            ]
                    }
            , searchInput searchText
            , Element.row
                [ Element.alignRight ]
                (case maybeLoggedIn of
                    Just loggedIn ->
                        headerButtons isMobile_ loggedIn.isAdmin route
                            ++ [ Ui.headerButton isMobile_
                                    logOutButtonId
                                    { onPress = PressedLogout
                                    , label = "Log out"
                                    }
                               ]

                    Nothing ->
                        [ Ui.headerButton
                            isMobile_
                            signUpOrLoginButtonId
                            { onPress = PressedLogin
                            , label = "Sign up / Login"
                            }
                        ]
                )
            ]
        , Element.row [ Element.Background.color Colors.grey, Element.width Element.fill, Element.height (Element.px 2) ] []
        ]


footer : Bool -> Route -> Element msg
footer isMobile_ route =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 8
        , Element.padding 8
        ]
        [ Element.row [ Element.Background.color Colors.grey, Element.width Element.fill, Element.height (Element.px 2) ] []
        , Element.row
            [ Element.width Element.fill, Element.alignBottom, Element.spacing 8 ]
            [ Ui.headerLink isMobile_ (route == PrivacyRoute) { route = PrivacyRoute, label = "Privacy" }
            , Ui.headerLink isMobile_ (route == TermsOfServiceRoute) { route = TermsOfServiceRoute, label = "Terms of service" }
            , Ui.headerLink isMobile_ (route == CodeOfConductRoute) { route = CodeOfConductRoute, label = "Code of conduct" }
            ]
        ]


headerButtons : Bool -> Bool -> Route -> List (Element msg)
headerButtons isMobile_ isAdmin route =
    [ if isAdmin then
        Ui.headerLink isMobile_
            (route == AdminRoute)
            { route = AdminRoute
            , label = "Admin"
            }

      else
        Element.none
    , Ui.headerLink isMobile_
        (route == CreateGroupRoute)
        { route = CreateGroupRoute
        , label = "Create group"
        }
    , Ui.headerLink isMobile_
        (route == MyGroupsRoute)
        { route = MyGroupsRoute
        , label = "My groups"
        }
    , Ui.headerLink isMobile_
        (route == MyProfileRoute)
        { route = MyProfileRoute
        , label = "Profile"
        }
    ]


groupSearchId =
    Id.textInputId "headerGroupSearch"


groupSearchLargeId =
    Id.textInputId "headerGroupSearchLarge"


logOutButtonId =
    Id.buttonId "headerLogOut"


signUpOrLoginButtonId =
    Id.buttonId "headerSignUpOrLogin"
