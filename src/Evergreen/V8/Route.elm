module Evergreen.V8.Route exposing (..)

import Evergreen.V8.GroupName
import Evergreen.V8.Id


type Route
    = HomepageRoute
    | GroupRoute Evergreen.V8.Id.GroupId Evergreen.V8.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V8.Id.Id Evergreen.V8.Id.LoginToken)
    | DeleteUserToken (Evergreen.V8.Id.Id Evergreen.V8.Id.DeleteUserToken)
