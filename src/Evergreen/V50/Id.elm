module Evergreen.V50.Id exposing (..)


type GroupId
    = GroupId Never


type Id a
    = Id String


type UserId
    = UserId Never


type LoginToken
    = LoginToken Never


type DeleteUserToken
    = DeleteUserToken Never


type SessionIdFirst4Chars
    = SessionIdFirst4Chars String
