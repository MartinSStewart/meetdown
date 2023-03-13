module Evergreen.V63.Route exposing (..)

import Evergreen.V63.Group
import Evergreen.V63.GroupName
import Evergreen.V63.Id
import Evergreen.V63.Name


type Route
    = HomepageRoute
    | GroupRoute (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.GroupName.GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) Evergreen.V63.Name.Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


type Token
    = NoToken
    | LoginToken (Evergreen.V63.Id.Id Evergreen.V63.Id.LoginToken) (Maybe ( Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId, Evergreen.V63.Group.EventId ))
    | DeleteUserToken (Evergreen.V63.Id.Id Evergreen.V63.Id.DeleteUserToken)
