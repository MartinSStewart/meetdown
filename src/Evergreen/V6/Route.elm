module Evergreen.V6.Route exposing (..)

import Evergreen.V6.GroupName
import Evergreen.V6.Id


type Route
    = HomepageRoute
    | GroupRoute Evergreen.V6.Id.GroupId Evergreen.V6.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V6.Id.Id Evergreen.V6.Id.LoginToken)
    | DeleteUserToken (Evergreen.V6.Id.Id Evergreen.V6.Id.DeleteUserToken)
