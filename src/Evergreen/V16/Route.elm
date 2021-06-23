module Evergreen.V16.Route exposing (..)

import Evergreen.V16.Group
import Evergreen.V16.GroupName
import Evergreen.V16.Id


type Route
    = HomepageRoute
    | GroupRoute Evergreen.V16.Id.GroupId Evergreen.V16.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V16.Id.Id Evergreen.V16.Id.LoginToken) (Maybe ( Evergreen.V16.Id.GroupId, Evergreen.V16.Group.EventId ))
    | DeleteUserToken (Evergreen.V16.Id.Id Evergreen.V16.Id.DeleteUserToken)
