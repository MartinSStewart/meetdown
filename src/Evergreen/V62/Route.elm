module Evergreen.V62.Route exposing (..)

import Evergreen.V62.Group
import Evergreen.V62.GroupName
import Evergreen.V62.Id
import Evergreen.V62.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) Evergreen.V62.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V62.Id.Id Evergreen.V62.Id.LoginToken) (Maybe ( Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId, Evergreen.V62.Group.EventId ))
    | DeleteUserToken (Evergreen.V62.Id.Id Evergreen.V62.Id.DeleteUserToken)
