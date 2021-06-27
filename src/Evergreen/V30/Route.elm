module Evergreen.V30.Route exposing (..)

import Evergreen.V30.Group
import Evergreen.V30.GroupName
import Evergreen.V30.Id
import Evergreen.V30.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V30.Id.Id Evergreen.V30.Id.LoginToken) (Maybe ( Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId, Evergreen.V30.Group.EventId ))
    | DeleteUserToken (Evergreen.V30.Id.Id Evergreen.V30.Id.DeleteUserToken)
