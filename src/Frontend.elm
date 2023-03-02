module Frontend exposing
    ( app
    , groupSearchId
    , init
    , logOutButtonId
    , signUpOrLoginButtonId
    , subscriptions
    , update
    , updateFromBackend
    , view
    )

import AdminPage
import AdminStatus exposing (AdminStatus(..))
import AssocList as Dict exposing (Dict)
import AssocSet as Set
import Browser exposing (UrlRequest(..))
import Cache exposing (Cache(..))
import CreateGroupPage
import DictExtra as Dict
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events as BrowserEvents
import Effect.Browser.Navigation as BrowserNavigation exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Effect.Time as Time
import Element exposing (Color, Element)
import Element.Background
import Element.Border
import Element.Events
import Element.Font
import Element.Input
import Element.Region
import Env
import FrontendUser exposing (FrontendUser)
import Group
import GroupPage
import Html
import Html.Attributes
import HtmlId
import Id exposing (Id, UserId)
import Lamdera
import List.Nonempty
import LoginForm
import Pixels exposing (Pixels)
import Ports
import Privacy
import ProfilePage
import Quantity exposing (Quantity)
import Route exposing (Route(..))
import SearchPage
import Terms
import TimeZone
import Types exposing (..)
import Ui
import Untrusted
import Url exposing (Url)
import UserConfig exposing (Theme, UserConfig)
import UserPage


app =
    Effect.Lamdera.frontend
        Lamdera.sendToBackend
        { init = init
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view =
            \model ->
                let
                    document =
                        view model
                in
                { document | body = Html.div [] [ Element.layout [] Element.none ] :: document.body }
        }


subscriptions : FrontendModel -> Subscription FrontendOnly FrontendMsg
subscriptions model =
    Subscription.batch
        [ case model of
            Loaded _ ->
                ProfilePage.subscriptions ProfileFormMsg

            Loading _ ->
                Subscription.none
        , BrowserEvents.onResize GotWindowSize
        , Time.every Duration.minute GotTime
        , Ports.gotPrefersDarkTheme GotPrefersDarkTheme
        , Ports.gotLanguage GotLanguage
        ]


onUrlRequest : UrlRequest -> FrontendMsg
onUrlRequest =
    UrlClicked


onUrlChange : Url -> FrontendMsg
onUrlChange =
    UrlChanged


init : Url -> Key -> ( FrontendModel, Command FrontendOnly toMsg FrontendMsg )
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
    , Command.batch
        [ Time.now |> Task.perform GotTime
        , Dom.getViewport
            |> Task.perform
                (\{ scene } -> GotWindowSize (round scene.width) (round scene.height))
        , TimeZone.getZone |> Task.attempt GotTimeZone
        , Ports.getPrefersDarkTheme
        , Ports.getLanguage
        ]
    )


initLoadedFrontend :
    Key
    -> Quantity Int Pixels
    -> Quantity Int Pixels
    -> Route
    -> Route.Token
    -> Time.Posix
    -> Time.Zone
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
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
            , loadedUserConfig = { theme = DarkTheme, language = English }
            , miniLanguageSelectorOpened = False
            }

        ( model2, cmd ) =
            routeRequest route model
    in
    ( model2
    , Command.batch
        [ Command.batch [ Effect.Lamdera.sendToBackend login, cmd ]
        , BrowserNavigation.replaceUrl navigationKey (Route.encode route)
        ]
    )


tryInitLoadedFrontend : LoadingFrontend -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
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
        |> Maybe.withDefault ( Loading loading, Command.none )


gotTimeZone : Result error ( a, Time.Zone ) -> { b | timezone : Maybe Time.Zone } -> { b | timezone : Maybe Time.Zone }
gotTimeZone result model =
    case result of
        Ok ( _, timezone ) ->
            { model | timezone = Just timezone }

        Err _ ->
            { model | timezone = Just Time.utc }


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
update msg model =
    case model of
        Loading loading ->
            case msg of
                GotTime time ->
                    tryInitLoadedFrontend { loading | time = Just time }

                GotWindowSize width height ->
                    tryInitLoadedFrontend { loading | windowSize = Just ( Pixels.pixels width, Pixels.pixels height ) }

                GotTimeZone result ->
                    gotTimeZone result loading |> tryInitLoadedFrontend

                _ ->
                    ( model, Command.none )

        Loaded loaded ->
            updateLoaded msg loaded |> Tuple.mapFirst Loaded


routeRequest : Route -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
routeRequest route model =
    case route of
        MyGroupsRoute ->
            ( model, Effect.Lamdera.sendToBackend GetMyGroupsRequest )

        GroupRoute groupId _ ->
            case Dict.get groupId model.cachedGroups of
                Just (ItemCached group) ->
                    let
                        ownerId =
                            Group.ownerId group
                    in
                    case Dict.get ownerId model.cachedUsers of
                        Just _ ->
                            ( model, Command.none )

                        Nothing ->
                            ( { model | cachedUsers = Dict.insert ownerId ItemRequestPending model.cachedUsers }
                            , List.Nonempty.fromElement ownerId
                                |> GetUserRequest
                                |> Effect.Lamdera.sendToBackend
                            )

                Just ItemRequestPending ->
                    ( model, Command.none )

                Just ItemDoesNotExist ->
                    ( { model | cachedGroups = Dict.insert groupId ItemRequestPending model.cachedGroups }
                    , Effect.Lamdera.sendToBackend (GetGroupRequest groupId)
                    )

                Nothing ->
                    ( { model | cachedGroups = Dict.insert groupId ItemRequestPending model.cachedGroups }
                    , Effect.Lamdera.sendToBackend (GetGroupRequest groupId)
                    )

        HomepageRoute ->
            ( model, Command.none )

        AdminRoute ->
            checkAdminState model

        CreateGroupRoute ->
            ( model, Effect.Lamdera.sendToBackend GetMyGroupsRequest )

        MyProfileRoute ->
            ( model, Command.none )

        SearchGroupsRoute searchText ->
            ( model, Effect.Lamdera.sendToBackend (SearchGroupsRequest searchText) )

        UserRoute userId _ ->
            case Dict.get userId model.cachedUsers of
                Just _ ->
                    ( model, Command.none )

                Nothing ->
                    ( { model | cachedUsers = Dict.insert userId ItemRequestPending model.cachedUsers }
                    , List.Nonempty.fromElement userId
                        |> GetUserRequest
                        |> Effect.Lamdera.sendToBackend
                    )

        PrivacyRoute ->
            ( model, Command.none )

        TermsOfServiceRoute ->
            ( model, Command.none )

        CodeOfConductRoute ->
            ( model, Command.none )

        FrequentQuestionsRoute ->
            ( model, Command.none )


checkAdminState : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
checkAdminState model =
    case model.loginStatus of
        LoggedIn loggedIn_ ->
            if loggedIn_.adminState == AdminCacheNotRequested && loggedIn_.adminStatus /= IsNotAdmin then
                ( { model | loginStatus = LoggedIn { loggedIn_ | adminState = AdminCachePending } }
                , Effect.Lamdera.sendToBackend GetAdminDataRequest
                )

            else
                ( model, Command.none )

        NotLoggedIn _ ->
            ( model, Command.none )

        LoginStatusPending ->
            ( model, Command.none )


navigationReplaceRoute : Key -> Route -> Command FrontendOnly toMsg msg
navigationReplaceRoute navKey route =
    Route.encode route |> BrowserNavigation.replaceUrl navKey


navigationPushRoute : Key -> Route -> Command FrontendOnly toMsg msg
navigationPushRoute navKey route =
    Route.encode route |> BrowserNavigation.pushUrl navKey


updateLoaded : FrontendMsg -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
updateLoaded msg ({ loadedUserConfig } as model) =
    case msg of
        NoOpFrontendMsg ->
            ( model, Command.none )

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
                    , BrowserNavigation.pushUrl model.navigationKey (Route.encode route)
                    )

                External url ->
                    ( model, BrowserNavigation.load url )

        UrlChanged url ->
            let
                route =
                    Route.decode url
                        |> Maybe.map Tuple.first
                        |> Maybe.withDefault HomepageRoute
            in
            routeRequest route { model | route = route }
                |> Tuple.mapSecond
                    (\a ->
                        Command.batch
                            [ a
                            , Dom.setViewport 0 0
                                |> Task.perform (\() -> ScrolledToTop)
                            ]
                    )

        GotTime time ->
            ( { model | time = time }, Command.none )

        PressedLogin ->
            case model.loginStatus of
                LoginStatusPending ->
                    ( model, Command.none )

                NotLoggedIn notLoggedIn ->
                    ( { model
                        | loginStatus = NotLoggedIn { notLoggedIn | showLogin = True }
                        , hasLoginTokenError = False
                      }
                    , Command.none
                    )

                LoggedIn _ ->
                    ( model, Command.none )

        PressedLogout ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing } }
            , Effect.Lamdera.sendToBackend LogoutRequest
            )

        TypedEmail text ->
            ( { model | loginForm = LoginForm.typedEmail text model.loginForm }, Command.none )

        PressedSubmitLogin ->
            case model.loginStatus of
                NotLoggedIn { joiningEvent } ->
                    LoginForm.submitForm model.route joiningEvent model.loginForm
                        |> Tuple.mapFirst (\a -> { model | loginForm = a })

                LoginStatusPending ->
                    ( model, Command.none )

                LoggedIn _ ->
                    ( model, Command.none )

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
                                        |> Effect.Lamdera.sendToBackend
                                    )

                                CreateGroupPage.NoChange ->
                                    ( newModel, Command.none )

                        Nothing ->
                            ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

                LoginStatusPending ->
                    ( model, Command.none )

        ProfileFormMsg profileFormMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( newModel, effects ) =
                            ProfilePage.update model profileFormMsg loggedIn.profileForm
                                |> Tuple.mapSecond (Command.map ProfileFormRequest ProfileFormMsg)
                    in
                    ( { model | loginStatus = LoggedIn { loggedIn | profileForm = newModel } }
                    , effects
                    )

                NotLoggedIn _ ->
                    ( model, Command.none )

                LoginStatusPending ->
                    ( model, Command.none )

        TypedSearchText searchText ->
            ( { model | searchText = searchText }, Command.none )

        SubmittedSearchBox ->
            ( closeLoginForm model, navigationPushRoute model.navigationKey (SearchGroupsRoute model.searchText) )

        GroupPageMsg groupPageMsg ->
            case model.route of
                GroupRoute groupId _ ->
                    case Dict.get groupId model.cachedGroups of
                        Just (ItemCached group) ->
                            let
                                ( newModel, effects, { joinEvent, requestUserData } ) =
                                    GroupPage.update
                                        (loadedUserConfigToUserConfig loadedUserConfig).texts
                                        model
                                        group
                                        (case model.loginStatus of
                                            LoggedIn loggedIn ->
                                                Just
                                                    { userId = loggedIn.userId
                                                    , adminStatus = loggedIn.adminStatus
                                                    , isSubscribed = Set.member groupId loggedIn.subscribedGroups
                                                    }

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
                                , cachedUsers =
                                    Dict.union
                                        model.cachedUsers
                                        (Set.toList requestUserData
                                            |> List.map (\userId -> ( userId, ItemRequestPending ))
                                            |> Dict.fromList
                                        )
                              }
                            , Command.batch
                                [ Command.map (GroupRequest groupId) GroupPageMsg effects
                                , case Set.toList requestUserData |> List.Nonempty.fromList of
                                    Just userIds ->
                                        Effect.Lamdera.sendToBackend (GetUserRequest userIds)

                                    Nothing ->
                                        Command.none
                                ]
                            )

                        _ ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        GotWindowSize width height ->
            ( { model | windowWidth = Pixels.pixels width, windowHeight = Pixels.pixels height }, Command.none )

        GotTimeZone _ ->
            ( model, Command.none )

        PressedCancelLogin ->
            ( closeLoginForm model, Command.none )

        ScrolledToTop ->
            ( model, Command.none )

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
            , Command.none
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
            , Command.none
            )

        PressedThemeToggle ->
            let
                newTheme =
                    case loadedUserConfig.theme of
                        LightTheme ->
                            DarkTheme

                        DarkTheme ->
                            LightTheme
            in
            ( { model | loadedUserConfig = { loadedUserConfig | theme = newTheme } }
            , Ports.setPrefersDarkTheme (newTheme == DarkTheme)
            )

        GotPrefersDarkTheme prefersDarkTheme ->
            ( { model
                | loadedUserConfig =
                    { loadedUserConfig
                        | theme =
                            if prefersDarkTheme then
                                DarkTheme

                            else
                                LightTheme
                    }
              }
            , Command.none
            )

        LanguageSelected language ->
            ( { model | miniLanguageSelectorOpened = False, loadedUserConfig = { loadedUserConfig | language = language } }
            , Ports.setLanguage (languageToString language)
            )

        GotLanguage language ->
            case languageFromString language of
                Just languageStr ->
                    ( { model
                        | loadedUserConfig =
                            { loadedUserConfig
                                | language = languageStr
                            }
                      }
                    , Command.none
                    )

                Nothing ->
                    ( model
                    , Command.none
                    )

        ToggleLanguageSelect ->
            ( { model | miniLanguageSelectorOpened = not model.miniLanguageSelectorOpened }, Command.none )


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


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case model of
        Loading _ ->
            ( model, Command.none )

        Loaded loaded ->
            updateLoadedFromBackend msg loaded |> Tuple.mapFirst Loaded


updateLoadedFromBackend : ToFrontend -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
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
                    Command.none
            )

        GetUserResponse userData ->
            let
                newUserData : Dict (Id UserId) (Cache FrontendUser)
                newUserData =
                    Dict.map
                        (\_ result ->
                            case result of
                                Ok user ->
                                    ItemCached user

                                Err () ->
                                    ItemDoesNotExist
                        )
                        userData
            in
            ( { model | cachedUsers = Dict.union newUserData model.cachedUsers }, Command.none )

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
                                , subscribedGroups = user.subscribedGroups
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
                    , Command.none
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
                                , subscribedGroups = user.subscribedGroups
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
                    , Command.none
                    )

        GetAdminDataResponse adminData ->
            case model.loginStatus of
                LoggedIn loggedIn_ ->
                    ( { model | loginStatus = LoggedIn { loggedIn_ | adminState = AdminCached adminData } }
                    , Command.none
                    )

                LoginStatusPending ->
                    ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

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
                            , Command.none
                            )

                NotLoggedIn _ ->
                    ( model, Command.none )

                LoginStatusPending ->
                    ( model, Command.none )

        LogoutResponse ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing } }, Command.none )

        ChangeNameResponse name ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.updateJust
                                loggedIn.userId
                                (Cache.map (\a -> { a | name = name }))
                                model.cachedUsers
                      }
                    , Command.none
                    )

                LoginStatusPending ->
                    ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        ChangeDescriptionResponse description ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.updateJust
                                loggedIn.userId
                                (Cache.map (\a -> { a | description = description }))
                                model.cachedUsers
                      }
                    , Command.none
                    )

                LoginStatusPending ->
                    ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        ChangeEmailAddressResponse emailAddress ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model | loginStatus = LoggedIn { loggedIn | emailAddress = emailAddress } }
                    , Command.none
                    )

                LoginStatusPending ->
                    ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        DeleteUserResponse result ->
            case result of
                Ok () ->
                    ( { model
                        | loginStatus = NotLoggedIn { showLogin = False, joiningEvent = Nothing }
                        , accountDeletedResult = Just result
                      }
                    , Command.none
                    )

                Err () ->
                    ( { model | accountDeletedResult = Just result }, Command.none )

        ChangeProfileImageResponse profileImage ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.updateJust
                                loggedIn.userId
                                (Cache.map (\a -> { a | profileImage = profileImage }))
                                model.cachedUsers
                      }
                    , Command.none
                    )

                LoginStatusPending ->
                    ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        GetMyGroupsResponse { myGroups, subscribedGroups } ->
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
                                (myGroups ++ subscribedGroups)
                    }

                NotLoggedIn _ ->
                    model

                LoginStatusPending ->
                    model
            , Command.none
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
            , Command.none
            )

        ChangeGroupNameResponse groupId groupName ->
            ( { model
                | cachedGroups =
                    Dict.updateJust groupId
                        (Cache.map (Group.withName groupName))
                        model.cachedGroups
                , groupPage = Dict.updateJust groupId GroupPage.savedName model.groupPage
              }
            , Command.none
            )

        ChangeGroupDescriptionResponse groupId description ->
            ( { model
                | cachedGroups =
                    Dict.updateJust groupId
                        (Cache.map (Group.withDescription description))
                        model.cachedGroups
                , groupPage = Dict.updateJust groupId GroupPage.savedDescription model.groupPage
              }
            , Command.none
            )

        CreateEventResponse groupId result ->
            ( { model
                | cachedGroups =
                    case result of
                        Ok event ->
                            Dict.updateJust groupId
                                (Cache.map (\group -> Group.addEvent event group |> Result.withDefault group))
                                model.cachedGroups

                        Err _ ->
                            model.cachedGroups
                , groupPage = Dict.updateJust groupId (GroupPage.addedNewEvent result) model.groupPage
              }
            , Command.none
            )

        JoinEventResponse groupId eventId result ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    case result of
                        Ok () ->
                            { model
                                | cachedGroups =
                                    Dict.updateJust groupId
                                        (Cache.map
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
            , Command.none
            )

        LeaveEventResponse groupId eventId result ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    case result of
                        Ok () ->
                            { model
                                | cachedGroups =
                                    Dict.updateJust groupId
                                        (Cache.map (Group.leaveEvent loggedIn.userId eventId))
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
            , Command.none
            )

        EditEventResponse groupId eventId result backendTime ->
            ( { model
                | cachedGroups =
                    case result of
                        Ok event ->
                            Dict.updateJust groupId
                                (Cache.map
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
            , Command.none
            )

        ChangeEventCancellationStatusResponse groupId eventId result backendTime ->
            ( { model
                | cachedGroups =
                    case result of
                        Ok cancellationStatus ->
                            Dict.updateJust groupId
                                (Cache.map
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
            , Command.none
            )

        ChangeGroupVisibilityResponse groupId visibility ->
            ( { model
                | cachedGroups =
                    Dict.updateJust groupId (Cache.map (Group.withVisibility visibility)) model.cachedGroups
                , groupPage = Dict.updateJust groupId (GroupPage.changeVisibilityResponse visibility) model.groupPage
              }
            , Command.none
            )

        DeleteGroupAdminResponse groupId ->
            ( { model | cachedGroups = Dict.updateJust groupId (\_ -> ItemDoesNotExist) model.cachedGroups }
            , Command.none
            )

        SubscribeResponse groupId ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    { model
                        | loginStatus =
                            LoggedIn { loggedIn | subscribedGroups = Set.insert groupId loggedIn.subscribedGroups }
                    }

                LoginStatusPending ->
                    model

                NotLoggedIn _ ->
                    model
            , Command.none
            )

        UnsubscribeResponse groupId ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    { model
                        | loginStatus =
                            LoggedIn { loggedIn | subscribedGroups = Set.remove groupId loggedIn.subscribedGroups }
                    }

                LoginStatusPending ->
                    model

                NotLoggedIn _ ->
                    model
            , Command.none
            )


loadedUserConfigToUserConfig : LoadedUserConfig -> UserConfig
loadedUserConfigToUserConfig config =
    { theme = loadedColorThemeToColorTheme config.theme
    , texts = loadedLanguageToLanguage config.language
    }


loadedColorThemeToColorTheme : ColorTheme -> UserConfig.Theme
loadedColorThemeToColorTheme theme =
    case theme of
        LightTheme ->
            UserConfig.lightTheme

        DarkTheme ->
            UserConfig.darkTheme


loadedLanguageToLanguage : Language -> UserConfig.Texts
loadedLanguageToLanguage language =
    case language of
        English ->
            UserConfig.englishTexts

        French ->
            UserConfig.frenchTexts

        Spanish ->
            UserConfig.spanishTexts


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    let
        userConfig : UserConfig
        userConfig =
            case model of
                Loading _ ->
                    UserConfig.default

                Loaded loaded ->
                    loadedUserConfigToUserConfig loaded.loadedUserConfig
    in
    { title = "Meetdown"
    , body =
        [ Ui.css userConfig.theme
        , Element.layoutWith
            { options = [ Element.noStaticStyleSheet ] }
            [ Ui.defaultFontSize
            , Ui.defaultFont
            , Ui.defaultFontColor userConfig.theme
            ]
            (case model of
                Loading _ ->
                    Element.none

                Loaded loaded ->
                    viewLoaded userConfig loaded
            )
        ]
    }


isMobile : { a | windowWidth : Quantity Int Pixels } -> Bool
isMobile { windowWidth } =
    windowWidth |> Quantity.lessThan (Pixels.pixels 600)


viewLoaded : UserConfig -> LoadedFrontend -> Element FrontendMsg
viewLoaded userConfig model =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , if model.miniLanguageSelectorOpened then
            Element.Events.onClick ToggleLanguageSelect

          else
            Ui.attributeNone
        ]
        (Element.column
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
                        header userConfig (Just loggedIn) model

                NotLoggedIn _ ->
                    header userConfig Nothing model
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
                            [ Element.text userConfig.texts.theLinkYouUsedIsEitherInvalidOrHasExpired ]
                        , Element.el
                            [ Element.centerX ]
                            (Ui.linkButton userConfig.theme { route = Route.HomepageRoute, label = userConfig.texts.goToHomepage })
                        ]

                 else
                    case model.loginStatus of
                        NotLoggedIn { showLogin, joiningEvent } ->
                            if showLogin then
                                LoginForm.view userConfig joiningEvent model.cachedGroups model.loginForm

                            else
                                viewPage userConfig model

                        LoggedIn _ ->
                            viewPage userConfig model

                        LoginStatusPending ->
                            Element.none
                )
            , footer
                userConfig
                (isMobile model)
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
        )


loginRequiredPage : UserConfig -> LoadedFrontend -> (LoggedIn_ -> Element FrontendMsg) -> Element FrontendMsg
loginRequiredPage userConfig model pageView =
    case model.loginStatus of
        LoggedIn loggedIn ->
            pageView loggedIn

        NotLoggedIn { joiningEvent } ->
            LoginForm.view userConfig joiningEvent model.cachedGroups model.loginForm

        LoginStatusPending ->
            Element.none


getCachedUser : Id UserId -> LoadedFrontend -> Maybe FrontendUser
getCachedUser userId loadedFrontend =
    case Dict.get userId loadedFrontend.cachedUsers of
        Just (ItemCached user) ->
            Just user

        _ ->
            Nothing


viewPage : UserConfig -> LoadedFrontend -> Element FrontendMsg
viewPage ({ theme, texts } as userConfig) model =
    case model.route of
        HomepageRoute ->
            Element.column
                [ Element.padding 8, Element.width Element.fill, Element.spacing 30 ]
                [ Element.el [ Element.paddingEach { top = 40, right = 0, bottom = 20, left = 0 }, Element.centerX ]
                    (Element.image
                        [ Element.width (Element.fill |> Element.maximum 650) ]
                        { src = theme.heroSvg, description = texts.twoPeopleOnAVideoConference }
                    )
                , Element.paragraph
                    [ Element.Font.center ]
                    [ Element.text texts.aPlaceToJoinGroupsOfPeopleWithSharedInterests ]
                , Element.paragraph
                    [ Element.Font.center ]
                    [ Element.text (texts.weDontSellYourDataWeDontShowAdsAndItsFree ++ " ")
                    , Ui.routeLink theme Route.FrequentQuestionsRoute texts.readMore
                    ]
                , searchInputLarge userConfig model.searchText
                ]

        GroupRoute groupId _ ->
            case Dict.get groupId model.cachedGroups of
                Just (ItemCached group) ->
                    case getCachedUser (Group.ownerId group) model of
                        Just owner ->
                            GroupPage.view
                                userConfig
                                (isMobile model)
                                model.time
                                model.timezone
                                owner
                                model.cachedUsers
                                group
                                (Dict.get groupId model.groupPage |> Maybe.withDefault GroupPage.init)
                                (case model.loginStatus of
                                    LoggedIn loggedIn ->
                                        Just
                                            { userId = loggedIn.userId
                                            , adminStatus = loggedIn.adminStatus
                                            , isSubscribed = Set.member groupId loggedIn.subscribedGroups
                                            }

                                    NotLoggedIn _ ->
                                        Nothing

                                    LoginStatusPending ->
                                        Nothing
                                )
                                |> Element.map GroupPageMsg

                        Nothing ->
                            Ui.loadingView texts

                Just ItemDoesNotExist ->
                    Ui.loadingError theme texts.groupNotFound

                Just ItemRequestPending ->
                    Ui.loadingView texts

                Nothing ->
                    Element.none

        AdminRoute ->
            loginRequiredPage userConfig model (AdminPage.view userConfig model.timezone)

        CreateGroupRoute ->
            loginRequiredPage
                userConfig
                model
                (\loggedIn ->
                    case loggedIn.myGroups of
                        Just myGroups ->
                            CreateGroupPage.view userConfig (isMobile model) (Set.isEmpty myGroups) model.groupForm
                                |> Element.map CreateGroupPageMsg

                        Nothing ->
                            Ui.loadingView texts
                )

        MyGroupsRoute ->
            loginRequiredPage userConfig model (myGroupsView userConfig model)

        MyProfileRoute ->
            loginRequiredPage
                userConfig
                model
                (\loggedIn ->
                    case Dict.get loggedIn.userId model.cachedUsers of
                        Just (ItemCached user) ->
                            ProfilePage.view
                                userConfig
                                model
                                { name = user.name
                                , description = user.description
                                , emailAddress = loggedIn.emailAddress
                                , profileImage = user.profileImage
                                }
                                loggedIn.profileForm
                                |> Element.map ProfileFormMsg

                        Just ItemRequestPending ->
                            Ui.loadingView texts

                        Just ItemDoesNotExist ->
                            Ui.loadingError theme texts.userNotFound

                        Nothing ->
                            Ui.loadingError theme texts.userNotFound
                )

        SearchGroupsRoute searchText ->
            SearchPage.view userConfig (isMobile model) searchText model

        UserRoute userId _ ->
            case getCachedUser userId model of
                Just user ->
                    UserPage.view userConfig user

                Nothing ->
                    Ui.loadingView texts

        PrivacyRoute ->
            Privacy.view userConfig

        TermsOfServiceRoute ->
            Terms.view userConfig

        CodeOfConductRoute ->
            Element.column
                (Ui.pageContentAttributes ++ [ Element.spacing 28 ])
                [ Ui.title texts.codeOfConduct
                , Element.paragraph []
                    [ Element.text (texts.theMostImportantRuleIs ++ ", ")
                    , Element.el [ Element.Font.bold ] (Element.text texts.dontBeAJerk)
                    , Element.text "."
                    ]
                , Element.paragraph [] [ Element.text texts.codeOfConduct1 ]
                , Element.paragraph [] [ Element.text texts.codeOfConduct2 ]
                , Element.paragraph [] [ Element.text texts.codeOfConduct3 ]
                , Element.paragraph [] [ Element.text texts.codeOfConduct4 ]
                , Element.paragraph
                    []
                    [ Element.text texts.codeOfConduct5
                    , Ui.mailToLink theme Env.contactEmailAddress (Just texts.moderationHelpRequest)
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
                [ Ui.title texts.frequentQuestions
                , questionAndAnswer
                    texts.faqQuestion1
                    [ Element.text texts.isItI
                    , Ui.externalLink theme "https://github.com/MartinSStewart/" "Martin"
                    , Element.text texts.creditGoesTo
                    , Ui.externalLink theme "https://twitter.com/realmario" "Mario Rogic"
                    , Element.text texts.forHelpingMeOutWithPartsOfTheApp
                    ]
                , questionAndAnswer
                    texts.faqQuestion2
                    [ Element.text texts.faq1
                    , Ui.externalLink theme "https://www.lamdera.com/" "Lamdera"
                    , Element.text texts.faq2
                    ]
                , questionAndAnswer
                    texts.faqQuestion3
                    [ Element.text texts.faq3
                    ]
                ]


myGroupsView : UserConfig -> LoadedFrontend -> LoggedIn_ -> Element FrontendMsg
myGroupsView ({ texts } as userConfig) model loggedIn =
    case loggedIn.myGroups of
        Just myGroups ->
            let
                myGroupsList : List (Element msg)
                myGroupsList =
                    SearchPage.getGroupsFromIds (Set.toList myGroups) model
                        |> List.map
                            (\( groupId, group ) ->
                                SearchPage.groupPreview userConfig (isMobile model) model.time groupId group
                            )
            in
            Element.column
                Ui.pageContentAttributes
                [ Ui.title texts.myGroups
                , if List.isEmpty myGroupsList && Set.isEmpty loggedIn.subscribedGroups then
                    Element.paragraph
                        []
                        [ Element.text texts.noGroupsYet
                        , Ui.routeLink userConfig.theme CreateGroupRoute texts.creatingOne
                        , Element.text texts.or
                        , Ui.routeLink userConfig.theme (SearchGroupsRoute "") texts.subscribingToOne
                        ]

                  else
                    Element.column
                        [ Element.width Element.fill, Element.spacing 32 ]
                        [ if List.isEmpty myGroupsList then
                            Element.paragraph []
                                [ Element.text texts.youHavenTCreatedAnyGroupsYet
                                , Ui.routeLink userConfig.theme CreateGroupRoute texts.youCanDoThatHere
                                ]

                          else
                            Element.column [ Element.spacing 8, Element.width Element.fill ] myGroupsList
                        , Element.column
                            [ Element.width Element.fill, Element.spacing 20 ]
                            [ Ui.title texts.subscribedGroups
                            , if Set.isEmpty loggedIn.subscribedGroups then
                                Element.paragraph []
                                    [ texts.group1
                                        ++ texts.notifyMeOfNewEvents
                                        ++ texts.buttonOnAGroupPage
                                        |> Element.text
                                    ]

                              else
                                SearchPage.getGroupsFromIds (Set.toList loggedIn.subscribedGroups) model
                                    |> List.map
                                        (\( groupId, group ) ->
                                            SearchPage.groupPreview userConfig (isMobile model) model.time groupId group
                                        )
                                    |> Element.column [ Element.spacing 8, Element.width Element.fill ]
                            ]
                        ]
                ]

        Nothing ->
            Ui.loadingView texts


searchInput : UserConfig -> String -> Element FrontendMsg
searchInput { theme, texts } searchText =
    Element.Input.text
        [ Element.width (Element.maximum 400 (Element.minimum 100 Element.fill))
        , Element.Border.rounded 5
        , Element.Border.color theme.darkGrey
        , Element.paddingEach { left = 24, right = 8, top = 4, bottom = 4 }
        , Element.Background.color theme.background
        , Ui.onEnter SubmittedSearchBox
        , Dom.idToAttribute groupSearchId |> Element.htmlAttribute
        , Element.el
            [ Element.Font.size 12
            , Element.moveDown 6
            , Element.moveRight 4
            , Element.alpha 0.8
            , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
            ]
            (Element.text "🔍")
            |> Element.inFront
        ]
        { text = searchText
        , onChange = TypedSearchText
        , placeholder = Nothing
        , label = Element.Input.labelHidden texts.searchForGroups
        }


searchInputLarge : UserConfig -> String -> Element FrontendMsg
searchInputLarge { theme, texts } searchText =
    Element.row
        [ Element.width (Element.maximum 400 Element.fill)
        , Element.centerX
        ]
        [ Element.Input.text
            [ Element.Border.roundEach { topLeft = 5, bottomLeft = 5, bottomRight = 0, topRight = 0 }
            , Element.Border.color theme.darkGrey
            , Element.Border.widthEach { bottom = 1, left = 1, right = 0, top = 1 }
            , Element.paddingEach { left = 30, right = 8, top = 8, bottom = 8 }
            , Ui.onEnter SubmittedSearchBox
            , Element.Background.color theme.background
            , Dom.idToAttribute groupSearchLargeId |> Element.htmlAttribute
            , Element.el
                [ Element.Font.size 14
                , Element.moveDown 9
                , Element.moveRight 6
                , Element.alpha 0.8
                , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                ]
                (Element.text "🔍")
                |> Element.inFront
            ]
            { text = searchText
            , onChange = TypedSearchText
            , placeholder = Nothing
            , label = Element.Input.labelHidden texts.searchForGroups
            }
        , Element.Input.button
            [ Element.Background.color theme.submit
            , Element.Border.roundEach { topLeft = 0, bottomLeft = 0, bottomRight = 5, topRight = 5 }
            , Element.height Element.fill
            , Element.Font.color theme.invertedText
            , Element.paddingXY 16 0
            ]
            { onPress = Just SubmittedSearchBox
            , label = Element.text texts.search
            }
        ]


adminStatusColor : Theme -> Maybe LoggedIn_ -> Color
adminStatusColor theme maybeLoggedIn =
    case Maybe.map .adminStatus maybeLoggedIn of
        Just IsNotAdmin ->
            if Env.isProduction then
                theme.grey

            else
                theme.submit

        Just IsAdminButDisabled ->
            if Env.isProduction then
                theme.grey

            else
                theme.submit

        Just IsAdminAndEnabled ->
            if Env.isProduction then
                theme.error

            else
                theme.submit

        Nothing ->
            if Env.isProduction then
                theme.grey

            else
                theme.submit


header : UserConfig -> Maybe LoggedIn_ -> LoadedFrontend -> Element FrontendMsg
header ({ theme, texts } as userConfig) maybeLoggedIn model =
    let
        isMobile_ =
            isMobile model
    in
    Element.column
        [ Element.width Element.fill, Element.spacing 10, Element.padding 10 ]
        [ Element.wrappedRow
            [ Element.width Element.fill
            , Element.paddingEach { left = 4, right = 0, top = 0, bottom = 0 }
            , Element.Region.navigation
            , Element.spacing 8
            ]
            ([ if isMobile_ then
                Element.none

               else
                Element.link [ Element.paddingEach { left = 0, right = 10, top = 0, bottom = 0 } ]
                    { url = "/"
                    , label =
                        Element.row [ Element.spacing 10 ]
                            [ Element.image
                                [ Element.width (Element.px 30) ]
                                { src = "/meetdown-logo.png", description = "Meetdown logo" }
                            , Element.text "Meetdown"
                            ]
                    }
             , searchInput userConfig model.searchText
             ]
                ++ (case maybeLoggedIn of
                        Just loggedIn ->
                            headerButtons userConfig isMobile_ (loggedIn.adminStatus /= IsNotAdmin) model.route
                                ++ [ Ui.headerButton
                                        isMobile_
                                        logOutButtonId
                                        { onPress = PressedLogout, label = texts.logout }
                                   , languageButton
                                        theme
                                        isMobile_
                                        model.miniLanguageSelectorOpened
                                        model.loadedUserConfig.language
                                   , themeToggleButton isMobile_ model.loadedUserConfig.theme
                                   ]

                        Nothing ->
                            [ Ui.headerButton
                                isMobile_
                                signUpOrLoginButtonId
                                { onPress = PressedLogin, label = texts.login }
                            , languageButton
                                theme
                                isMobile_
                                model.miniLanguageSelectorOpened
                                model.loadedUserConfig.language
                            , themeToggleButton isMobile_ model.loadedUserConfig.theme
                            ]
                   )
            )
        , largeLine userConfig maybeLoggedIn
        ]


themeToggleButtonId : Dom.HtmlId
themeToggleButtonId =
    Dom.id "header_themeToggleButton"


themeToggleButton : Bool -> ColorTheme -> Element FrontendMsg
themeToggleButton isMobile_ theme =
    Ui.headerButton
        isMobile_
        themeToggleButtonId
        { onPress = PressedThemeToggle
        , label =
            case theme of
                LightTheme ->
                    "🌙"

                DarkTheme ->
                    "☀️"
        }


languageToFlag : Language -> String
languageToFlag language =
    case language of
        English ->
            "🇬🇧"

        French ->
            "🇫🇷"

        Spanish ->
            "🇪🇸"


languageToString : Language -> String
languageToString language =
    case language of
        English ->
            "en"

        French ->
            "fr"

        Spanish ->
            "es"


languageFromString : String -> Maybe Language
languageFromString string =
    case string of
        "en" ->
            Just English

        "fr" ->
            Just French

        "es" ->
            Just Spanish

        _ ->
            Nothing


languageButton : Theme -> Bool -> Bool -> Language -> Element FrontendMsg
languageButton theme isMobile_ miniLanguageSelectorOpened language =
    Element.row
        [ Element.alignRight
        , if miniLanguageSelectorOpened then
            Element.below (miniLanguageSelect theme isMobile_ language)

          else
            Ui.attributeNone
        , if miniLanguageSelectorOpened then
            Element.Background.color theme.lightGrey

          else
            Element.Background.color theme.background
        , Ui.greedyOnClick NoOpFrontendMsg
        ]
        [ Ui.headerButton
            isMobile_
            (Dom.id "header_languageButton")
            { onPress = ToggleLanguageSelect
            , label = languageToFlag language
            }
        ]


miniLanguageSelect : Theme -> Bool -> Language -> Element FrontendMsg
miniLanguageSelect theme isMobile_ language =
    List.filter ((/=) language) [ English, French, Spanish ]
        |> List.map (languageOption isMobile_)
        |> Element.column
            [ Element.Background.color theme.lightGrey
            , Element.alignTop
            , Element.alignRight
            , Element.Border.shadow { offset = ( 0, 1 ), size = 0, blur = 1, color = Element.rgba 0 0 0 0.1 }
            ]


selectLanguageButtonId : Language -> HtmlId
selectLanguageButtonId language =
    "frontend_selectLanguageButton_" ++ languageToString language |> Dom.id


languageOption : Bool -> Language -> Element FrontendMsg
languageOption isMobile_ language =
    Element.Input.button
        [ Element.mouseOver [ Element.Background.color (Element.rgba 1 1 1 0.5) ]
        , if isMobile_ then
            Element.padding 6

          else
            Element.padding 8
        , Element.width Element.fill
        , Ui.inputFocusClass
        , Dom.idToAttribute (selectLanguageButtonId language) |> Element.htmlAttribute
        , if isMobile_ then
            Element.Font.size 13

          else
            Element.Font.size 16
        ]
        { onPress = Just (LanguageSelected language)
        , label =
            (case language of
                English ->
                    "English 🇬🇧"

                French ->
                    "Français 🇫🇷"

                Spanish ->
                    "Español 🇪🇸"
            )
                |> Element.text
                |> Element.el [ Element.alignRight ]
        }


largeLine : UserConfig -> Maybe LoggedIn_ -> Element msg
largeLine userConfig maybeLoggedIn =
    Element.row
        [ Element.Background.color (adminStatusColor userConfig.theme maybeLoggedIn)
        , Element.width Element.fill
        , Element.height (Element.px 2)
        ]
        []


footer : UserConfig -> Bool -> Route -> Maybe LoggedIn_ -> Element msg
footer ({ theme, texts } as userConfig) isMobile_ route maybeLoggedIn =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 8
        , Element.padding 8
        ]
        [ largeLine userConfig maybeLoggedIn
        , Element.wrappedRow
            [ Element.width Element.fill, Element.alignBottom, Element.spacing 8 ]
            [ Ui.headerLink theme isMobile_ (route == PrivacyRoute) { route = PrivacyRoute, label = texts.privacy }
            , Ui.headerLink theme isMobile_ (route == TermsOfServiceRoute) { route = TermsOfServiceRoute, label = texts.tos }
            , Ui.headerLink theme isMobile_ (route == CodeOfConductRoute) { route = CodeOfConductRoute, label = texts.codeOfConduct }
            , Ui.headerLink theme isMobile_ (route == FrequentQuestionsRoute) { route = FrequentQuestionsRoute, label = texts.faq }
            ]
        ]


headerButtons : UserConfig -> Bool -> Bool -> Route -> List (Element msg)
headerButtons { theme, texts } isMobile_ isAdmin route =
    [ if isAdmin then
        Ui.headerLink theme isMobile_ (route == AdminRoute) { route = AdminRoute, label = "Admin" }

      else
        Element.none
    , Ui.headerLink theme isMobile_ (route == CreateGroupRoute) { route = CreateGroupRoute, label = texts.newGroup }
    , Ui.headerLink theme isMobile_ (route == MyGroupsRoute) { route = MyGroupsRoute, label = texts.myGroups }
    , Ui.headerLink theme isMobile_ (route == MyProfileRoute) { route = MyProfileRoute, label = texts.profile }
    ]


groupSearchId : HtmlId
groupSearchId =
    HtmlId.textInputId "headerGroupSearch"


groupSearchLargeId : HtmlId
groupSearchLargeId =
    HtmlId.textInputId "headerGroupSearchLarge"


logOutButtonId : HtmlId
logOutButtonId =
    HtmlId.buttonId "headerLogOut"


signUpOrLoginButtonId : HtmlId
signUpOrLoginButtonId =
    HtmlId.buttonId "headerSignUpOrLogin"
