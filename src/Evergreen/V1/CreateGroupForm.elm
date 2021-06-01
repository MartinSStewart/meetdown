module Evergreen.V1.CreateGroupForm exposing (..)

import Evergreen.V1.Description
import Evergreen.V1.Group
import Evergreen.V1.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V1.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V1.GroupName.GroupName
    , description : Evergreen.V1.Description.Description
    , visibility : Evergreen.V1.Group.GroupVisibility
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
