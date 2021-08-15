module FrontendLogic exposing
    ( groupSearchId
    , init
    , logOutButtonId
    , onUrlChange
    , onUrlRequest
    , signUpOrLoginButtonId
    , subscriptions
    , update
    , updateFromBackend
    , view
    )

import AdminPage
import AdminStatus exposing (AdminStatus(..))
import AssocList as Dict
import AssocSet as Set
import Browser exposing (UrlRequest(..))
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
import FrontendEffect exposing (FrontendEffect)
import FrontendSub exposing (FrontendSub)
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import GroupPage
import Html.Attributes
import Id exposing (ButtonId(..), GroupId, Id, UserId)
import LoginForm
import NavigationKey exposing (NavigationKey)
import Pixels exposing (Pixels)
import Privacy
import ProfileImage
import ProfilePage
import Quantity exposing (Quantity)
import Route exposing (Route(..))
import SearchPage
import SimulatedTask
import Terms
import Time
import Types exposing (..)
import Ui
import Untrusted
import Url exposing (Url)
import Url.Parser exposing ((</>))
import UserPage


subscriptions : FrontendModel -> FrontendSub FrontendMsg
subscriptions _ =
    FrontendSub.Batch
        [ FrontendSub.CropImageFromJs CroppedImage
        , FrontendSub.OnResize GotWindowSize
        , FrontendSub.TimeEvery Duration.minute GotTime
        ]


onUrlRequest : UrlRequest -> FrontendMsg
onUrlRequest =
    UrlClicked


onUrlChange : Url -> FrontendMsg
onUrlChange =
    UrlChanged


init : Url -> NavigationKey -> ( FrontendModel, FrontendEffect ToBackend FrontendMsg )
init url key =
    let
        ( route, token ) =
            Route.decode url |> Maybe.withDefault ( HomepageRoute, Route.NoToken )
    in
    ( Loading
        { navigationKey = key
        , route = route
        , routeToken = token
        , windowSize = Nothing
        , time = Nothing
        , timezone = Nothing
        }
    , FrontendEffect.Batch
        [ SimulatedTask.getTime |> FrontendEffect.taskPerform GotTime
        , FrontendEffect.GetWindowSize GotWindowSize
        , FrontendEffect.GetTimeZone GotTimeZone
        ]
    )


initLoadedFrontend :
    NavigationKey
    -> Quantity Int Pixels
    -> Quantity Int Pixels
    -> Route
    -> Route.Token
    -> Time.Posix
    -> Time.Zone
    -> ( LoadedFrontend, FrontendEffect ToBackend FrontendMsg )
initLoadedFrontend navigationKey windowWidth windowHeight route maybeLoginToken time timezone =
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
            routeRequest route model
    in
    ( model2
    , FrontendEffect.Batch
        [ FrontendEffect.Batch [ FrontendEffect.SendToBackend login, cmd ]
        , FrontendEffect.NavigationReplaceUrl navigationKey (Route.encode route)
        ]
    )


tryInitLoadedFrontend : LoadingFrontend -> ( FrontendModel, FrontendEffect ToBackend FrontendMsg )
tryInitLoadedFrontend loading =
    Maybe.map3
        (\( windowWidth, windowHeight ) time zone ->
            initLoadedFrontend
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
        |> Maybe.withDefault ( Loading loading, FrontendEffect.None )


gotTimeZone : Result error ( a, Time.Zone ) -> { b | timezone : Maybe Time.Zone } -> { b | timezone : Maybe Time.Zone }
gotTimeZone result model =
    case result of
        Ok ( _, timezone ) ->
            { model | timezone = Just timezone }

        Err _ ->
            { model | timezone = Just Time.utc }


update : FrontendMsg -> FrontendModel -> ( FrontendModel, FrontendEffect ToBackend FrontendMsg )
update msg model =
    case model of
        Loading loading ->
            case msg of
                GotTime time ->
                    tryInitLoadedFrontend { loading | time = Just time }

                GotWindowSize width height ->
                    tryInitLoadedFrontend { loading | windowSize = Just ( width, height ) }

                GotTimeZone result ->
                    gotTimeZone result loading |> tryInitLoadedFrontend

                _ ->
                    ( model, FrontendEffect.None )

        Loaded loaded ->
            updateLoaded msg loaded |> Tuple.mapFirst Loaded


routeRequest : Route -> LoadedFrontend -> ( LoadedFrontend, FrontendEffect ToBackend FrontendMsg )
routeRequest route model =
    case route of
        MyGroupsRoute ->
            ( model, FrontendEffect.SendToBackend GetMyGroupsRequest )

        GroupRoute groupId _ ->
            case Dict.get groupId model.cachedGroups of
                Just (ItemCached group) ->
                    let
                        ownerId =
                            Group.ownerId group
                    in
                    case Dict.get ownerId model.cachedUsers of
                        Just _ ->
                            ( model, FrontendEffect.None )

                        Nothing ->
                            ( { model | cachedUsers = Dict.insert ownerId ItemRequestPending model.cachedUsers }
                            , FrontendEffect.SendToBackend (GetUserRequest ownerId)
                            )

                Just ItemRequestPending ->
                    ( model, FrontendEffect.None )

                Just ItemDoesNotExist ->
                    ( { model | cachedGroups = Dict.insert groupId ItemRequestPending model.cachedGroups }
                    , FrontendEffect.SendToBackend (GetGroupRequest groupId)
                    )

                Nothing ->
                    ( { model | cachedGroups = Dict.insert groupId ItemRequestPending model.cachedGroups }
                    , FrontendEffect.SendToBackend (GetGroupRequest groupId)
                    )

        HomepageRoute ->
            ( model, FrontendEffect.None )

        AdminRoute ->
            checkAdminState model

        CreateGroupRoute ->
            ( model, FrontendEffect.SendToBackend GetMyGroupsRequest )

        MyProfileRoute ->
            ( model, FrontendEffect.None )

        SearchGroupsRoute searchText ->
            ( model, FrontendEffect.SendToBackend (SearchGroupsRequest searchText) )

        UserRoute userId _ ->
            case Dict.get userId model.cachedUsers of
                Just _ ->
                    ( model, FrontendEffect.None )

                Nothing ->
                    ( { model | cachedUsers = Dict.insert userId ItemRequestPending model.cachedUsers }
                    , FrontendEffect.SendToBackend (GetUserRequest userId)
                    )

        PrivacyRoute ->
            ( model, FrontendEffect.None )

        TermsOfServiceRoute ->
            ( model, FrontendEffect.None )

        CodeOfConductRoute ->
            ( model, FrontendEffect.None )

        FrequentQuestionsRoute ->
            ( model, FrontendEffect.None )


checkAdminState : LoadedFrontend -> ( LoadedFrontend, FrontendEffect ToBackend FrontendMsg )
checkAdminState model =
    case model.loginStatus of
        LoggedIn loggedIn_ ->
            if loggedIn_.adminState == AdminCacheNotRequested && loggedIn_.adminStatus /= IsNotAdmin then
                ( { model | loginStatus = LoggedIn { loggedIn_ | adminState = AdminCachePending } }
                , FrontendEffect.SendToBackend GetAdminDataRequest
                )

            else
                ( model, FrontendEffect.None )

        NotLoggedIn _ ->
            ( model, FrontendEffect.None )

        LoginStatusPending ->
            ( model, FrontendEffect.None )


navigationReplaceRoute navKey route =
    Route.encode route |> FrontendEffect.NavigationReplaceUrl navKey


navigationPushRoute navKey route =
    Route.encode route |> FrontendEffect.NavigationPushUrl navKey


updateLoaded : FrontendMsg -> LoadedFrontend -> ( LoadedFrontend, FrontendEffect ToBackend FrontendMsg )
updateLoaded msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    let
                        route =
                            Route.decode url
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault HomepageRoute
                    in
                    ( { model | route = route, hasLoginTokenError = False } |> closeLoginForm
                    , FrontendEffect.NavigationPushUrl model.navigationKey (Route.encode route)
                    )

                External url ->
                    ( model, FrontendEffect.NavigationLoad url )

        UrlChanged url ->
            let
                route =
                    Route.decode url
                        |> Maybe.map Tuple.first
                        |> Maybe.withDefault HomepageRoute
            in
            routeRequest route { model | route = route }
                |> Tuple.mapSecond (\a -> FrontendEffect.Batch [ a, FrontendEffect.ScrollToTop ScrolledToTop ])

        GotTime time ->
            ( { model | time = time }, FrontendEffect.None )

        PressedLogin ->
            case model.loginStatus of
                LoginStatusPending ->
                    ( model, FrontendEffect.None )

                NotLoggedIn notLoggedIn ->
                    ( { model
                        | loginStatus = NotLoggedIn { notLoggedIn | showLogin = True }
                        , hasLoginTokenError = False
                      }
                    , FrontendEffect.None
                    )

                LoggedIn _ ->
                    ( model, FrontendEffect.None )

        PressedLogout ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing } }
            , FrontendEffect.SendToBackend LogoutRequest
            )

        TypedEmail text ->
            ( { model | loginForm = LoginForm.typedEmail text model.loginForm }, FrontendEffect.None )

        PressedSubmitLogin ->
            case model.loginStatus of
                NotLoggedIn { joiningEvent } ->
                    LoginForm.submitForm model.route joiningEvent model.loginForm
                        |> Tuple.mapFirst (\a -> { model | loginForm = a })

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

                LoggedIn _ ->
                    ( model, FrontendEffect.None )

        PressedCreateGroup ->
            ( model, navigationPushRoute model.navigationKey CreateGroupRoute )

        CreateGroupPageMsg groupFormMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case loggedIn.myGroups of
                        Just _ ->
                            let
                                ( newModel, outMsg ) =
                                    CreateGroupPage.update groupFormMsg model.groupForm
                                        |> Tuple.mapFirst (\a -> { model | groupForm = a })
                            in
                            case outMsg of
                                CreateGroupPage.Submitted submitted ->
                                    ( newModel
                                    , CreateGroupRequest
                                        (Untrusted.untrust submitted.name)
                                        (Untrusted.untrust submitted.description)
                                        submitted.visibility
                                        |> FrontendEffect.SendToBackend
                                    )

                                CreateGroupPage.NoChange ->
                                    ( newModel, FrontendEffect.None )

                        Nothing ->
                            ( model, FrontendEffect.None )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

        ProfileFormMsg profileFormMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( newModel, effects ) =
                            ProfilePage.update
                                model
                                { wait =
                                    \duration waitMsg ->
                                        SimulatedTask.wait duration
                                            |> FrontendEffect.taskPerform (\() -> ProfileFormMsg waitMsg)
                                , none = FrontendEffect.None
                                , changeName = ChangeNameRequest >> FrontendEffect.SendToBackend
                                , changeDescription = ChangeDescriptionRequest >> FrontendEffect.SendToBackend
                                , changeEmailAddress = ChangeEmailAddressRequest >> FrontendEffect.SendToBackend
                                , selectFile =
                                    \mimeTypes fileMsg ->
                                        FrontendEffect.SelectFile mimeTypes (fileMsg >> ProfileFormMsg)
                                , getFileContents =
                                    \fileMsg file -> FrontendEffect.FileToUrl (fileMsg >> ProfileFormMsg) file
                                , setCanvasImage = FrontendEffect.CropImage
                                , sendDeleteAccountEmail = FrontendEffect.SendToBackend SendDeleteUserEmailRequest
                                , getElement =
                                    \getElementMsg id -> FrontendEffect.GetElement (getElementMsg >> ProfileFormMsg) id
                                , batch = FrontendEffect.Batch
                                }
                                profileFormMsg
                                loggedIn.profileForm
                    in
                    ( { model | loginStatus = LoggedIn { loggedIn | profileForm = newModel } }
                    , effects
                    )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

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
                                |> FrontendEffect.SendToBackend
                            )

                        Err _ ->
                            ( model, FrontendEffect.None )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

        TypedSearchText searchText ->
            ( { model | searchText = searchText }, FrontendEffect.None )

        SubmittedSearchBox ->
            ( closeLoginForm model, navigationPushRoute model.navigationKey (SearchGroupsRoute model.searchText) )

        GroupPageMsg groupPageMsg ->
            case model.route of
                GroupRoute groupId _ ->
                    case Dict.get groupId model.cachedGroups of
                        Just (ItemCached group) ->
                            let
                                ( newModel, effects, { joinEvent } ) =
                                    GroupPage.update
                                        model
                                        group
                                        (case model.loginStatus of
                                            LoggedIn loggedIn ->
                                                Just loggedIn

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
                            , FrontendEffect.map (GroupRequest groupId) GroupPageMsg effects
                            )

                        _ ->
                            ( model, FrontendEffect.None )

                _ ->
                    ( model, FrontendEffect.None )

        GotWindowSize width height ->
            ( { model | windowWidth = width, windowHeight = height }, FrontendEffect.None )

        GotTimeZone _ ->
            ( model, FrontendEffect.None )

        PressedCancelLogin ->
            ( closeLoginForm model, FrontendEffect.None )

        ScrolledToTop ->
            ( model, FrontendEffect.None )

        PressedEnableAdmin ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    case loggedIn.adminStatus of
                        IsAdminButDisabled ->
                            { model | loginStatus = LoggedIn { loggedIn | adminStatus = IsAdminAndEnabled } }

                        IsAdminAndEnabled ->
                            model

                        IsNotAdmin ->
                            model

                _ ->
                    model
            , FrontendEffect.None
            )

        PressedDisableAdmin ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    case loggedIn.adminStatus of
                        IsAdminButDisabled ->
                            model

                        IsAdminAndEnabled ->
                            { model | loginStatus = LoggedIn { loggedIn | adminStatus = IsAdminButDisabled } }

                        IsNotAdmin ->
                            model

                _ ->
                    model
            , FrontendEffect.None
            )


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


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, FrontendEffect ToBackend FrontendMsg )
updateFromBackend msg model =
    case model of
        Loading _ ->
            ( model, FrontendEffect.None )

        Loaded loaded ->
            updateLoadedFromBackend msg loaded |> Tuple.mapFirst Loaded


updateLoadedFromBackend : ToFrontend -> LoadedFrontend -> ( LoadedFrontend, FrontendEffect ToBackend FrontendMsg )
updateLoadedFromBackend msg model =
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
                    navigationReplaceRoute
                        model.navigationKey
                        (GroupRoute groupId (Group.name groupData))

                GroupNotFound_ ->
                    FrontendEffect.None
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
            , FrontendEffect.None
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
                                , adminStatus =
                                    if isAdmin then
                                        IsAdminButDisabled

                                    else
                                        IsNotAdmin
                                }
                        , cachedUsers = Dict.insert userId (userToFrontend user |> ItemCached) model.cachedUsers
                    }
                        |> checkAdminState

                Err () ->
                    ( { model
                        | hasLoginTokenError = True
                        , loginStatus = NotLoggedIn { showLogin = True, joiningEvent = Nothing }
                      }
                    , FrontendEffect.None
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
                                , adminStatus =
                                    if isAdmin then
                                        IsAdminButDisabled

                                    else
                                        IsNotAdmin
                                }
                        , cachedUsers = Dict.insert userId (userToFrontend user |> ItemCached) model.cachedUsers
                    }
                        |> checkAdminState

                Nothing ->
                    ( { model | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing } }
                    , FrontendEffect.None
                    )

        GetAdminDataResponse adminData ->
            case model.loginStatus of
                LoggedIn loggedIn_ ->
                    ( { model | loginStatus = LoggedIn { loggedIn_ | adminState = AdminCached adminData } }
                    , FrontendEffect.None
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

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
                            , navigationReplaceRoute
                                model.navigationKey
                                (GroupRoute groupId (Group.name groupData))
                            )

                        Err error ->
                            ( { model | groupForm = CreateGroupPage.submitFailed error model.groupForm }
                            , FrontendEffect.None
                            )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

        LogoutResponse ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing } }, FrontendEffect.None )

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
                    , FrontendEffect.None
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

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
                    , FrontendEffect.None
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

        ChangeEmailAddressResponse emailAddress ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model | loginStatus = LoggedIn { loggedIn | emailAddress = emailAddress } }
                    , FrontendEffect.None
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

        DeleteUserResponse result ->
            case result of
                Ok () ->
                    ( { model
                        | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing }
                        , accountDeletedResult = Just result
                      }
                    , FrontendEffect.None
                    )

                Err () ->
                    ( { model | accountDeletedResult = Just result }, FrontendEffect.None )

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
                    , FrontendEffect.None
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.None )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.None )

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
            , FrontendEffect.None
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
            , FrontendEffect.None
            )

        ChangeGroupNameResponse groupId groupName ->
            ( { model
                | cachedGroups =
                    Dict.updateJust groupId
                        (Types.mapCache (Group.withName groupName))
                        model.cachedGroups
                , groupPage = Dict.updateJust groupId GroupPage.savedName model.groupPage
              }
            , FrontendEffect.None
            )

        ChangeGroupDescriptionResponse groupId description ->
            ( { model
                | cachedGroups =
                    Dict.updateJust groupId
                        (Types.mapCache (Group.withDescription description))
                        model.cachedGroups
                , groupPage = Dict.updateJust groupId GroupPage.savedDescription model.groupPage
              }
            , FrontendEffect.None
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
            , FrontendEffect.None
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
            , FrontendEffect.None
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
            , FrontendEffect.None
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
            , FrontendEffect.None
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
            , FrontendEffect.None
            )

        ChangeGroupVisibilityResponse groupId visibility ->
            ( { model
                | cachedGroups =
                    Dict.updateJust groupId (Types.mapCache (Group.withVisibility visibility)) model.cachedGroups
                , groupPage = Dict.updateJust groupId (GroupPage.changeVisibilityResponse visibility) model.groupPage
              }
            , FrontendEffect.None
            )

        DeleteGroupAdminResponse groupId ->
            ( { model | cachedGroups = Dict.updateJust groupId (\_ -> ItemDoesNotExist) model.cachedGroups }
            , FrontendEffect.None
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
                    header (Just loggedIn) model

            NotLoggedIn _ ->
                header Nothing model
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
        , footer (isMobile model)
            model.route
            (case model.loginStatus of
                LoggedIn loggedIn ->
                    Just loggedIn

                LoginStatusPending ->
                    Nothing

                NotLoggedIn _ ->
                    Nothing
            )
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
                    [ Element.text " We don't sell your data, we don't show ads, and it's free. "
                    , Ui.routeLink Route.FrequentQuestionsRoute "Read more"
                    ]
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
                                        Just loggedIn

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
            SearchPage.view (isMobile model) searchText model

        UserRoute userId _ ->
            case getCachedUser userId model of
                Just user ->
                    UserPage.view user

                Nothing ->
                    Ui.loadingView

        PrivacyRoute ->
            Privacy.view

        TermsOfServiceRoute ->
            Terms.view

        CodeOfConductRoute ->
            Element.column
                (Ui.pageContentAttributes ++ [ Element.spacing 28 ])
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

        FrequentQuestionsRoute ->
            let
                questionAndAnswer : String -> List (Element msg) -> Element msg
                questionAndAnswer question answer =
                    Element.column
                        [ Element.spacing 8 ]
                        [ Element.paragraph [ Element.Font.bold ] [ Element.text ("\"" ++ question ++ "\"") ]
                        , Element.paragraph [] answer
                        ]
            in
            Element.column
                (Ui.pageContentAttributes ++ [ Element.spacing 28 ])
                [ Ui.title "Frequently asked questions"
                , questionAndAnswer "Who is behind all this?"
                    [ Element.text "It is I, "
                    , Ui.externalLink "https://github.com/MartinSStewart/" "Martin"
                    , Element.text ". Credit goes to "
                    , Ui.externalLink "https://twitter.com/realmario" "Mario Rogic"
                    , Element.text " for helping me out with parts of the app."
                    ]
                , questionAndAnswer
                    "Why was this website made?"
                    [ Element.text "I dislike that meetup.com charges money, spams me with emails, and feels bloated. Also I wanted to try making something more substantial using "
                    , Ui.externalLink "https://www.lamdera.com/" "Lamdera"
                    , Element.text " to see if it's feasible to use at work."
                    ]
                , questionAndAnswer
                    "If this website is free and doesn't run ads or sell data, how does it sustain itself?"
                    [ Element.text "I just spend my own money to host it. That's okay because it's designed to cost very little to run. In the unlikely even that Meetdown gets very popular and hosting costs become too expensive, I'll ask for donations." ]
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
                                SearchPage.groupPreview (isMobile model) model.time groupId group
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


adminStatusColor maybeLoggedIn =
    case Maybe.map .adminStatus maybeLoggedIn of
        Just IsNotAdmin ->
            if Env.isProduction then
                Colors.grey

            else
                Colors.green

        Just IsAdminButDisabled ->
            if Env.isProduction then
                Colors.grey

            else
                Colors.green

        Just IsAdminAndEnabled ->
            if Env.isProduction then
                Colors.red

            else
                Colors.green

        Nothing ->
            if Env.isProduction then
                Colors.grey

            else
                Colors.green


header : Maybe LoggedIn_ -> LoadedFrontend -> Element FrontendMsg
header maybeLoggedIn model =
    let
        isMobile_ =
            isMobile model
    in
    Element.column [ Element.width Element.fill, Element.spacing 10, Element.padding 10 ]
        [ Element.row
            [ Element.width Element.fill
            , Element.paddingEach { left = 4, right = 0, top = 0, bottom = 0 }
            , Element.Region.navigation
            , Element.spacing 8
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
            , searchInput model.searchText
            , Element.row
                [ Element.alignRight ]
                (case maybeLoggedIn of
                    Just loggedIn ->
                        headerButtons isMobile_ (loggedIn.adminStatus /= IsNotAdmin) model.route
                            ++ [ Ui.headerButton isMobile_
                                    logOutButtonId
                                    { onPress = PressedLogout
                                    , label = "Logout"
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
        , largeLine maybeLoggedIn
        ]


largeLine : Maybe LoggedIn_ -> Element msg
largeLine maybeLoggedIn =
    Element.row
        [ Element.Background.color (adminStatusColor maybeLoggedIn)
        , Element.width Element.fill
        , Element.height (Element.px 2)
        ]
        []


footer : Bool -> Route -> Maybe LoggedIn_ -> Element msg
footer isMobile_ route maybeLoggedIn =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 8
        , Element.padding 8
        ]
        [ largeLine maybeLoggedIn
        , Element.row
            [ Element.width Element.fill, Element.alignBottom, Element.spacing 8 ]
            [ Ui.headerLink isMobile_ (route == PrivacyRoute) { route = PrivacyRoute, label = "Privacy" }
            , Ui.headerLink isMobile_ (route == TermsOfServiceRoute) { route = TermsOfServiceRoute, label = "Terms of service" }
            , Ui.headerLink isMobile_ (route == CodeOfConductRoute) { route = CodeOfConductRoute, label = "Code of conduct" }
            , Ui.headerLink isMobile_ (route == FrequentQuestionsRoute) { route = FrequentQuestionsRoute, label = "FaQ" }
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
        , label = "New group"
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
