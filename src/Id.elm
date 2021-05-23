module Id exposing
    ( ClientId
    , DeleteUserToken
    , GroupId
    , Id
    , LoginToken
    , SessionId
    , UserId
    , adminUserId
    , clientIdFromString
    , clientIdToString
    , cryptoHashFromString
    , cryptoHashToString
    , getUniqueId
    , groupIdFromInt
    , groupIdToInt
    , sessionIdFromString
    )

import Env
import Lamdera
import Sha256
import Time


type UserId
    = UserId Never


type GroupId
    = GroupId Int


type SessionId
    = SessionId Lamdera.SessionId


type ClientId
    = ClientId Lamdera.ClientId


type Id a
    = Id String


type LoginToken
    = LoginToken Never


type DeleteUserToken
    = DeleteUserToken Never


sessionIdFromString : Lamdera.SessionId -> SessionId
sessionIdFromString =
    SessionId


clientIdFromString : Lamdera.ClientId -> ClientId
clientIdFromString =
    ClientId


clientIdToString : ClientId -> Lamdera.ClientId
clientIdToString (ClientId clientId) =
    clientId


adminUserId : Id UserId
adminUserId =
    cryptoHashFromString Env.adminUserId_


getUniqueId : { a | secretCounter : Int, time : Time.Posix } -> ( { a | secretCounter : Int, time : Time.Posix }, Id b )
getUniqueId model =
    ( { model | secretCounter = model.secretCounter + 1 }
    , Env.secretKey
        ++ ":"
        ++ String.fromInt model.secretCounter
        ++ ":"
        ++ String.fromInt (Time.posixToMillis model.time)
        |> Sha256.sha256
        |> Id
    )


cryptoHashToString : Id a -> String
cryptoHashToString (Id hash) =
    hash


cryptoHashFromString : String -> Id a
cryptoHashFromString =
    Id


groupIdFromInt : Int -> GroupId
groupIdFromInt =
    GroupId


groupIdToInt : GroupId -> Int
groupIdToInt (GroupId groupId) =
    groupId
