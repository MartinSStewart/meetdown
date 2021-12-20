module Evergreen.V50.Route exposing (..)

import Evergreen.V50.Group
import Evergreen.V50.GroupName
import Evergreen.V50.Id
import Evergreen.V50.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) Evergreen.V50.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V50.Id.Id Evergreen.V50.Id.LoginToken) (Maybe ( Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId, Evergreen.V50.Group.EventId ))
    | DeleteUserToken (Evergreen.V50.Id.Id Evergreen.V50.Id.DeleteUserToken)
