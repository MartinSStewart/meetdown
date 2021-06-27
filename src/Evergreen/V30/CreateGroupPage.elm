module Evergreen.V30.CreateGroupPage exposing (..)

import Evergreen.V30.Description
import Evergreen.V30.Group
import Evergreen.V30.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V30.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V30.GroupName.GroupName
    , description : Evergreen.V30.Description.Description
    , visibility : Evergreen.V30.Group.GroupVisibility
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
