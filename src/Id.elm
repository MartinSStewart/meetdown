module Id exposing (ClientId, GroupId, SessionId, UserId, clientIdFromString, clientIdToString, sessionIdFromString)

import Lamdera


type UserId
    = UserId Int


type GroupId
    = GroupId String


type SessionId
    = SessionId Lamdera.SessionId


type ClientId
    = ClientId Lamdera.ClientId


sessionIdFromString : Lamdera.SessionId -> SessionId
sessionIdFromString =
    SessionId


clientIdFromString : Lamdera.ClientId -> ClientId
clientIdFromString =
    ClientId


clientIdToString : ClientId -> Lamdera.ClientId
clientIdToString (ClientId clientId) =
    clientId
