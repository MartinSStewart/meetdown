module Evergreen.V26.Route exposing (..)

import Evergreen.V26.Group
import Evergreen.V26.GroupName
import Evergreen.V26.Id
import Evergreen.V26.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.Name.Name


type Token
    = NoToken
    | LoginToken (Evergreen.V26.Id.Id Evergreen.V26.Id.LoginToken) (Maybe ( Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId, Evergreen.V26.Group.EventId ))
    | DeleteUserToken (Evergreen.V26.Id.Id Evergreen.V26.Id.DeleteUserToken)
