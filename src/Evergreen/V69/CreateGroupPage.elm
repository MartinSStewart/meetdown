module Evergreen.V69.CreateGroupPage exposing (..)

import Evergreen.V69.Description
import Evergreen.V69.Group
import Evergreen.V69.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V69.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V69.GroupName.GroupName
    , description : Evergreen.V69.Description.Description
    , visibility : Evergreen.V69.Group.GroupVisibility
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
