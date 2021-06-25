module Evergreen.V27.Route exposing (..)

import Evergreen.V27.Group
import Evergreen.V27.GroupName
import Evergreen.V27.Id
import Evergreen.V27.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.Name.Name


type Token
    = NoToken
    | LoginToken (Evergreen.V27.Id.Id Evergreen.V27.Id.LoginToken) (Maybe ( Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId, Evergreen.V27.Group.EventId ))
    | DeleteUserToken (Evergreen.V27.Id.Id Evergreen.V27.Id.DeleteUserToken)
