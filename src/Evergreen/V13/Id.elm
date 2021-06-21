module Evergreen.V13.Id exposing (..)


type GroupId
    = GroupId Int


type LoginToken
    = LoginToken Never


type Id a
    = Id String


type DeleteUserToken
    = DeleteUserToken Never


type UserId
    = UserId Never


type SessionIdLast4Chars
    = SessionIdLast4Chars String


type SessionId
    = SessionId String


type ClientId
    = ClientId String
