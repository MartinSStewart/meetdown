module Evergreen.V9.Route exposing (..)

import Evergreen.V9.Group
import Evergreen.V9.GroupName
import Evergreen.V9.Id


type Route
    = HomepageRoute
    | GroupRoute Evergreen.V9.Id.GroupId Evergreen.V9.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V9.Id.Id Evergreen.V9.Id.LoginToken) (Maybe ( Evergreen.V9.Id.GroupId, Evergreen.V9.Group.EventId ))
    | DeleteUserToken (Evergreen.V9.Id.Id Evergreen.V9.Id.DeleteUserToken)
