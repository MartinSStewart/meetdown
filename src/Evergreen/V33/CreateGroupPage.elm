module Evergreen.V33.CreateGroupPage exposing (..)

import Evergreen.V33.Description
import Evergreen.V33.Group
import Evergreen.V33.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V33.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V33.GroupName.GroupName
    , description : Evergreen.V33.Description.Description
    , visibility : Evergreen.V33.Group.GroupVisibility
    }


type CreateGroupError
    = GroupNameAlreadyInUse


type Model
    = Editting Form
    | Submitting GroupFormValidated
    | SubmitFailed CreateGroupError Form


type Msg
    = FormChanged Form
    | PressedSubmit
    | PressedClear
