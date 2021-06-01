module Evergreen.V1.Group exposing (..)

import Evergreen.V1.Description
import Evergreen.V1.Event
import Evergreen.V1.GroupName
import Evergreen.V1.Id


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
        , name : Evergreen.V1.GroupName.GroupName
        , description : Evergreen.V1.Description.Description
        , events : List Evergreen.V1.Event.Event
        , visibility : GroupVisibility
        }
