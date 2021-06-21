module Evergreen.V13.CreateGroupPage exposing (..)

import Evergreen.V13.Description
import Evergreen.V13.Group
import Evergreen.V13.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V13.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V13.GroupName.GroupName
    , description : Evergreen.V13.Description.Description
    , visibility : Evergreen.V13.Group.GroupVisibility
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
