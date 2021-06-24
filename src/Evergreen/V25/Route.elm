module Evergreen.V25.Route exposing (..)

import Evergreen.V25.Group
import Evergreen.V25.GroupName
import Evergreen.V25.Id


type Route
    = HomepageRoute
    | GroupRoute Evergreen.V25.Id.GroupId Evergreen.V25.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)


type Token
    = NoToken
    | LoginToken (Evergreen.V25.Id.Id Evergreen.V25.Id.LoginToken) (Maybe ( Evergreen.V25.Id.GroupId, Evergreen.V25.Group.EventId ))
    | DeleteUserToken (Evergreen.V25.Id.Id Evergreen.V25.Id.DeleteUserToken)
