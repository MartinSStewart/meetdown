module Evergreen.V33.Route exposing (..)

import Evergreen.V33.Group
import Evergreen.V33.GroupName
import Evergreen.V33.Id
import Evergreen.V33.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V33.Id.Id Evergreen.V33.Id.LoginToken) (Maybe ( Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId, Evergreen.V33.Group.EventId ))
    | DeleteUserToken (Evergreen.V33.Id.Id Evergreen.V33.Id.DeleteUserToken)
