module Evergreen.V69.Route exposing (..)

import Evergreen.V69.Group
import Evergreen.V69.GroupName
import Evergreen.V69.Id
import Evergreen.V69.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) Evergreen.V69.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V69.Id.Id Evergreen.V69.Id.LoginToken) (Maybe ( Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId, Evergreen.V69.Group.EventId ))
    | DeleteUserToken (Evergreen.V69.Id.Id Evergreen.V69.Id.DeleteUserToken)
