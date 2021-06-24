module Evergreen.V25.Id exposing (..)


type GroupId
    = GroupId Int


type UserId
    = UserId Never


type Id a
    = Id String


type LoginToken
    = LoginToken Never


type DeleteUserToken
    = DeleteUserToken Never


type SessionIdFirst4Chars
    = SessionIdFirst4Chars String


type SessionId
    = SessionId String


type ClientId
    = ClientId String
