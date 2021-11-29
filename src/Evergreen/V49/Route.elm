module Evergreen.V49.Route exposing (..)

import Evergreen.V49.Group
import Evergreen.V49.GroupName
import Evergreen.V49.Id
import Evergreen.V49.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V49.Id.Id Evergreen.V49.Id.LoginToken) (Maybe ( Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId, Evergreen.V49.Group.EventId ))
    | DeleteUserToken (Evergreen.V49.Id.Id Evergreen.V49.Id.DeleteUserToken)
