module Evergreen.V49.CreateGroupPage exposing (..)

import Evergreen.V49.Description
import Evergreen.V49.Group
import Evergreen.V49.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V49.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V49.GroupName.GroupName
    , description : Evergreen.V49.Description.Description
    , visibility : Evergreen.V49.Group.GroupVisibility
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
