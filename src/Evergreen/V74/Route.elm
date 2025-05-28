module Evergreen.V74.Route exposing (..)

import Evergreen.V74.Group
import Evergreen.V74.GroupName
import Evergreen.V74.Id
import Evergreen.V74.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) Evergreen.V74.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V74.Id.Id Evergreen.V74.Id.LoginToken) (Maybe ( Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId, Evergreen.V74.Group.EventId ))
    | DeleteUserToken (Evergreen.V74.Id.Id Evergreen.V74.Id.DeleteUserToken)
