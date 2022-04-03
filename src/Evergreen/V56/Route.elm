module Evergreen.V56.Route exposing (..)

import Evergreen.V56.Group
import Evergreen.V56.GroupName
import Evergreen.V56.Id
import Evergreen.V56.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V56.Id.Id Evergreen.V56.Id.LoginToken) (Maybe ( Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId, Evergreen.V56.Group.EventId ))
    | DeleteUserToken (Evergreen.V56.Id.Id Evergreen.V56.Id.DeleteUserToken)
