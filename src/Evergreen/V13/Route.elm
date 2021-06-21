module Evergreen.V13.Route exposing (..)

import Evergreen.V13.Group
import Evergreen.V13.GroupName
import Evergreen.V13.Id


type Route
    = HomepageRoute
    | GroupRoute Evergreen.V13.Id.GroupId Evergreen.V13.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V13.Id.Id Evergreen.V13.Id.LoginToken) (Maybe ( Evergreen.V13.Id.GroupId, Evergreen.V13.Group.EventId ))
    | DeleteUserToken (Evergreen.V13.Id.Id Evergreen.V13.Id.DeleteUserToken)
