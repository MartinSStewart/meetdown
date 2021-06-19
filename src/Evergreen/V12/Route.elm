module Evergreen.V12.Route exposing (..)

import Evergreen.V12.Group
import Evergreen.V12.GroupName
import Evergreen.V12.Id


type Route
    = HomepageRoute
    | GroupRoute Evergreen.V12.Id.GroupId Evergreen.V12.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V12.Id.Id Evergreen.V12.Id.LoginToken) (Maybe ( Evergreen.V12.Id.GroupId, Evergreen.V12.Group.EventId ))
    | DeleteUserToken (Evergreen.V12.Id.Id Evergreen.V12.Id.DeleteUserToken)
