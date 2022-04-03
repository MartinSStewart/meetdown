module Evergreen.V56.CreateGroupPage exposing (..)

import Evergreen.V56.Description
import Evergreen.V56.Group
import Evergreen.V56.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V56.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V56.GroupName.GroupName
    , description : Evergreen.V56.Description.Description
    , visibility : Evergreen.V56.Group.GroupVisibility
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
