module Evergreen.V68.Route exposing (..)

import Evergreen.V68.Group
import Evergreen.V68.GroupName
import Evergreen.V68.Id
import Evergreen.V68.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) Evergreen.V68.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V68.Id.Id Evergreen.V68.Id.LoginToken) (Maybe ( Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId, Evergreen.V68.Group.EventId ))
    | DeleteUserToken (Evergreen.V68.Id.Id Evergreen.V68.Id.DeleteUserToken)
