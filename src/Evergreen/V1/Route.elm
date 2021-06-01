module Evergreen.V1.Route exposing (..)

import Evergreen.V1.GroupName
import Evergreen.V1.Id


type Route
    = HomepageRoute
    | GroupRoute Evergreen.V1.Id.GroupId Evergreen.V1.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V1.Id.Id Evergreen.V1.Id.LoginToken)
    | DeleteUserToken (Evergreen.V1.Id.Id Evergreen.V1.Id.DeleteUserToken)
