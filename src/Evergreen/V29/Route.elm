module Evergreen.V29.Route exposing (..)

import Evergreen.V29.Group
import Evergreen.V29.GroupName
import Evergreen.V29.Id
import Evergreen.V29.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V29.Id.Id Evergreen.V29.Id.LoginToken) (Maybe ( Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId, Evergreen.V29.Group.EventId ))
    | DeleteUserToken (Evergreen.V29.Id.Id Evergreen.V29.Id.DeleteUserToken)
