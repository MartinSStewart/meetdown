module Evergreen.V61.Route exposing (..)

import Evergreen.V61.Group
import Evergreen.V61.GroupName
import Evergreen.V61.Id
import Evergreen.V61.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V61.Id.Id Evergreen.V61.Id.LoginToken) (Maybe ( Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId, Evergreen.V61.Group.EventId ))
    | DeleteUserToken (Evergreen.V61.Id.Id Evergreen.V61.Id.DeleteUserToken)
