module Evergreen.V6.Group exposing (..)

import AssocList
import Evergreen.V6.Description
import Evergreen.V6.Event
import Evergreen.V6.GroupName
import Evergreen.V6.Id


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type EventId
    = EventId Int


type Group
    = Group
        { ownerId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
        , name : Evergreen.V6.GroupName.GroupName
        , description : Evergreen.V6.Description.Description
        , events : AssocList.Dict EventId Evergreen.V6.Event.Event
        , visibility : GroupVisibility
        , eventCounter : Int
        }
