module Evergreen.V37.Route exposing (..)

import Evergreen.V37.Group
import Evergreen.V37.GroupName
import Evergreen.V37.Id
import Evergreen.V37.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) Evergreen.V37.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V37.Id.Id Evergreen.V37.Id.LoginToken) (Maybe ( Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId, Evergreen.V37.Group.EventId ))
    | DeleteUserToken (Evergreen.V37.Id.Id Evergreen.V37.Id.DeleteUserToken)
