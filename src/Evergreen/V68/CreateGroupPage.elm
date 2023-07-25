module Evergreen.V68.CreateGroupPage exposing (..)

import Evergreen.V68.Description
import Evergreen.V68.Group
import Evergreen.V68.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V68.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V68.GroupName.GroupName
    , description : Evergreen.V68.Description.Description
    , visibility : Evergreen.V68.Group.GroupVisibility
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
