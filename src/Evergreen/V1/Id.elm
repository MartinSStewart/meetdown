module Evergreen.V1.Id exposing (..)

import Lamdera


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


type SessionId
    = SessionId Lamdera.SessionId


type ClientId
    = ClientId Lamdera.ClientId
