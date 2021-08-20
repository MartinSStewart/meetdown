module Evergreen.V48.Route exposing (..)

import Evergreen.V48.Group
import Evergreen.V48.GroupName
import Evergreen.V48.Id
import Evergreen.V48.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) Evergreen.V48.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V48.Id.Id Evergreen.V48.Id.LoginToken) (Maybe ( Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId, Evergreen.V48.Group.EventId ))
    | DeleteUserToken (Evergreen.V48.Id.Id Evergreen.V48.Id.DeleteUserToken)
