module Evergreen.V71.Route exposing (..)

import Evergreen.V71.Group
import Evergreen.V71.GroupName
import Evergreen.V71.Id
import Evergreen.V71.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) Evergreen.V71.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V71.Id.Id Evergreen.V71.Id.LoginToken) (Maybe ( Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId, Evergreen.V71.Group.EventId ))
    | DeleteUserToken (Evergreen.V71.Id.Id Evergreen.V71.Id.DeleteUserToken)
