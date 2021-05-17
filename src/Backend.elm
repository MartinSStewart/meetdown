module Backend exposing (app, init, update, updateFromFrontend)

import Array
import AssocList as Dict exposing (Dict)
import Avataaars.Clothes
import Avataaars.Eyebrow
import Avataaars.Eyes
import Avataaars.FacialHair
import Avataaars.Mouth
import Avataaars.SkinTone
import Avataaars.Top exposing (TopFacialHair(..))
import BackendEffect exposing (BackendEffect)
import BackendSub exposing (BackendSub)
import Duration
import GroupName exposing (GroupName)
import Id exposing (ClientId, CryptoHash, GroupId, LoginToken, SessionId, UserId)
import Lamdera
import List.Extra as List
import List.Nonempty
import Quantity
import String.Nonempty exposing (NonemptyString(..))
import Time
import Types exposing (..)
import Untrusted


app =
    Lamdera.backend
        { init = init
        , update = \msg model -> update msg model |> Tuple.mapSecond BackendEffect.toCmd
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                updateFromFrontend
                    (Id.sessionIdFromString sessionId)
                    (Id.clientIdFromString clientId)
                    toBackend
                    model
                    |> Tuple.mapSecond BackendEffect.toCmd
        , subscriptions = subscriptions >> BackendSub.toSub
        }


init : ( BackendModel, Cmd BackendMsg )
init =
    ( { users = Dict.empty
      , groups = Dict.empty
      , sessions = Dict.empty
      , connections = Dict.empty
      , logs = Array.empty
      , time = Time.millisToPosix 0
      , secretCounter = 0
      , pendingLoginTokens = Dict.empty
      }
    , Cmd.none
    )


subscriptions : BackendModel -> BackendSub
subscriptions _ =
    BackendSub.batch
        [ BackendSub.timeEvery (Duration.seconds 15) BackendGotTime
        , BackendSub.onConnect Connected
        , BackendSub.onDisconnect Disconnected
        ]


update : BackendMsg -> BackendModel -> ( BackendModel, BackendEffect )
update msg model =
    case msg of
        SentLoginEmail email result ->
            ( addLog (SendGridSendEmail model.time result email) model, BackendEffect.none )

        BackendGotTime time ->
            ( { model | time = time }, BackendEffect.none )

        Connected sessionId clientId ->
            let
                _ =
                    Debug.log "connected" clientId
            in
            ( { model
                | connections =
                    Dict.update sessionId
                        (Maybe.map (List.Nonempty.cons clientId)
                            >> Maybe.withDefault (List.Nonempty.fromElement clientId)
                            >> Just
                        )
                        model.connections
              }
            , BackendEffect.none
            )

        Disconnected sessionId clientId ->
            ( { model
                | connections =
                    Dict.update sessionId
                        (Maybe.andThen (List.Nonempty.toList >> List.remove clientId >> List.Nonempty.fromList))
                        model.connections
              }
            , BackendEffect.none
            )


addLog : Log -> BackendModel -> BackendModel
addLog log model =
    { model | logs = Array.push log model.logs }


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, BackendEffect )
updateFromFrontend sessionId clientId (ToBackend msgs) model =
    List.Nonempty.foldl
        (\msg ( newModel, effects ) ->
            updateFromRequest sessionId clientId msg newModel
                |> Tuple.mapSecond (\a -> BackendEffect.batch [ a, effects ])
        )
        ( model, BackendEffect.none )
        msgs


updateFromRequest : SessionId -> ClientId -> ToBackendRequest -> BackendModel -> ( BackendModel, BackendEffect )
updateFromRequest sessionId clientId msg model =
    case msg of
        GetGroupRequest groupId ->
            ( model
            , getGroup groupId model
                |> Maybe.andThen (groupToFrontend model)
                |> GetGroupResponse groupId
                |> BackendEffect.sendToFrontend clientId
            )

        CheckLoginRequest ->
            ( model, checkLogin sessionId model |> CheckLoginResponse |> BackendEffect.sendToFrontend clientId )

        GetLoginTokenRequest route untrustedEmail ->
            case Untrusted.validateEmail untrustedEmail of
                Ok email ->
                    let
                        ( model2, loginToken ) =
                            Id.getCryptoHash model
                    in
                    ( { model2
                        | pendingLoginTokens =
                            Dict.insert
                                loginToken
                                { creationTime = model2.time, emailAddress = email }
                                model2.pendingLoginTokens
                      }
                    , BackendEffect.sendLoginEmail (SentLoginEmail email) email route loginToken
                    )

                Err _ ->
                    ( addLog (UntrustedCheckFailed model.time msg) model
                    , BackendEffect.none
                    )

        GetAdminDataRequest ->
            adminAuthorization
                sessionId
                model
                (\_ ->
                    ( model, BackendEffect.sendToFrontend clientId (GetAdminDataResponse model.logs) )
                )

        LoginWithTokenRequest loginToken ->
            getAndRemoveLoginToken (loginWithToken sessionId clientId) loginToken model

        LogoutRequest ->
            ( { model | sessions = Dict.remove sessionId model.sessions }
            , case Dict.get sessionId model.connections of
                Just clientIds ->
                    BackendEffect.sendToFrontends clientIds LogoutResponse

                Nothing ->
                    BackendEffect.none
            )

        CreateGroupRequest groupVisibility untrustedGroupName ->
            userAuthorization
                sessionId
                model
                (\( userId, _ ) ->
                    case Untrusted.validateGroupName untrustedGroupName of
                        Ok groupName ->
                            addGroup userId groupVisibility groupName model

                        Err _ ->
                            ( addLog (UntrustedCheckFailed model.time msg) model
                            , BackendEffect.none
                            )
                )


loginWithToken : SessionId -> ClientId -> Maybe LoginTokenData -> BackendModel -> ( BackendModel, BackendEffect )
loginWithToken sessionId clientId maybeLoginTokenData model =
    let
        loginResponse : ( CryptoHash UserId, BackendUser ) -> BackendEffect
        loginResponse userEntry =
            case Dict.get sessionId model.connections of
                Just clientIds ->
                    Ok userEntry |> LoginWithTokenResponse |> BackendEffect.sendToFrontends clientIds

                Nothing ->
                    BackendEffect.none

        addSession : CryptoHash UserId -> BackendModel -> BackendModel
        addSession userId model_ =
            { model_ | sessions = Dict.insert sessionId userId model_.sessions }
    in
    case maybeLoginTokenData of
        Just { creationTime, emailAddress } ->
            if Duration.from creationTime model.time |> Quantity.lessThan Duration.hour then
                case Dict.toList model.users |> List.find (Tuple.second >> .emailAddress >> (==) emailAddress) of
                    Just userEntry ->
                        ( addSession (Tuple.first userEntry) model
                        , loginResponse userEntry
                        )

                    Nothing ->
                        let
                            ( model2, userId ) =
                                Id.getCryptoHash model

                            newUser : BackendUser
                            newUser =
                                { name = NonemptyString 'A' ""
                                , emailAddress = emailAddress
                                , profileImage =
                                    { circleBg = False
                                    , skinTone = Avataaars.SkinTone.brown
                                    , clothes = Avataaars.Clothes.BlazerShirt
                                    , face =
                                        { mouth = Avataaars.Mouth.Concerned
                                        , eyes = Avataaars.Eyes.Cry
                                        , eyebrow = Avataaars.Eyebrow.AngryNatural
                                        }
                                    , top = Avataaars.Top.TopFacialHair Eyepatch (Avataaars.FacialHair.BeardLight "#FFFFFF")
                                    }
                                }
                        in
                        ( { model2 | users = Dict.insert userId newUser model2.users }
                            |> addSession userId
                        , loginResponse ( userId, newUser )
                        )

            else
                ( model, Err () |> LoginWithTokenResponse |> BackendEffect.sendToFrontend clientId )

        Nothing ->
            ( model, Err () |> LoginWithTokenResponse |> BackendEffect.sendToFrontend clientId )


getAndRemoveLoginToken :
    (Maybe LoginTokenData -> BackendModel -> ( BackendModel, BackendEffect ))
    -> CryptoHash LoginToken
    -> BackendModel
    -> ( BackendModel, BackendEffect )
getAndRemoveLoginToken updateFunc loginToken model =
    updateFunc
        (Dict.get loginToken model.pendingLoginTokens)
        { model | pendingLoginTokens = Dict.remove loginToken model.pendingLoginTokens }


addGroup : CryptoHash UserId -> GroupVisibility -> GroupName -> BackendModel -> ( BackendModel, BackendEffect )
addGroup userId groupVisibility groupName model =
    let
        ( model2, groupId ) =
            Id.getCryptoHash model
    in
    ( { model2
        | groups =
            Dict.insert
                groupId
                { ownerId = userId
                , name = groupName
                , events = []
                , visibility = groupVisibility
                }
                model.groups
      }
    , BackendEffect.none
    )


userAuthorization :
    SessionId
    -> BackendModel
    -> (( CryptoHash UserId, BackendUser ) -> ( BackendModel, BackendEffect ))
    -> ( BackendModel, BackendEffect )
userAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        LoggedIn userId user ->
            updateFunc ( userId, user )

        NotLoggedIn ->
            ( model, BackendEffect.none )


adminAuthorization :
    SessionId
    -> BackendModel
    -> (( CryptoHash UserId, BackendUser ) -> ( BackendModel, BackendEffect ))
    -> ( BackendModel, BackendEffect )
adminAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        LoggedIn userId user ->
            if Id.adminUserId == userId then
                updateFunc ( userId, user )

            else
                ( model, BackendEffect.none )

        NotLoggedIn ->
            ( model, BackendEffect.none )


checkLogin : SessionId -> BackendModel -> LoginStatus
checkLogin sessionId model =
    case Dict.get sessionId model.sessions of
        Just userId ->
            case Dict.get userId model.users of
                Just user ->
                    LoggedIn userId user

                Nothing ->
                    NotLoggedIn

        Nothing ->
            NotLoggedIn


getGroup : CryptoHash GroupId -> BackendModel -> Maybe BackendGroup
getGroup groupId model =
    Dict.get groupId model.groups


getUser : CryptoHash UserId -> BackendModel -> Maybe BackendUser
getUser userId model =
    Dict.get userId model.users


groupToFrontend : BackendModel -> BackendGroup -> Maybe FrontendGroup
groupToFrontend model backendGroup =
    case getUser backendGroup.ownerId model of
        Just owner ->
            { ownerId = backendGroup.ownerId
            , owner = userToFrontend owner
            , name = backendGroup.name
            , events = backendGroup.events
            , visibility = backendGroup.visibility
            }
                |> Just

        Nothing ->
            Nothing


userToFrontend : BackendUser -> FrontendUser
userToFrontend backendUser =
    { name = backendUser.name
    , profileImage = backendUser.profileImage
    }
