module Evergreen.V25.CreateGroupPage exposing (..)

import Evergreen.V25.Description
import Evergreen.V25.Group
import Evergreen.V25.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V25.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V25.GroupName.GroupName
    , description : Evergreen.V25.Description.Description
    , visibility : Evergreen.V25.Group.GroupVisibility
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
