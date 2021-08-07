module Evergreen.V46.Route exposing (..)

import Evergreen.V46.Group
import Evergreen.V46.GroupName
import Evergreen.V46.Id
import Evergreen.V46.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V46.Id.Id Evergreen.V46.Id.LoginToken) (Maybe ( Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId, Evergreen.V46.Group.EventId ))
    | DeleteUserToken (Evergreen.V46.Id.Id Evergreen.V46.Id.DeleteUserToken)
