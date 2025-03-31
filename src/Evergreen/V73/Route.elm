module Evergreen.V73.Route exposing (..)

import Evergreen.V73.Group
import Evergreen.V73.GroupName
import Evergreen.V73.Id
import Evergreen.V73.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) Evergreen.V73.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V73.Id.Id Evergreen.V73.Id.LoginToken) (Maybe ( Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId, Evergreen.V73.Group.EventId ))
    | DeleteUserToken (Evergreen.V73.Id.Id Evergreen.V73.Id.DeleteUserToken)
