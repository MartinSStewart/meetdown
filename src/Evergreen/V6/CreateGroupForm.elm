module Evergreen.V6.CreateGroupForm exposing (..)

import Evergreen.V6.Description
import Evergreen.V6.Group
import Evergreen.V6.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V6.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V6.GroupName.GroupName
    , description : Evergreen.V6.Description.Description
    , visibility : Evergreen.V6.Group.GroupVisibility
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
