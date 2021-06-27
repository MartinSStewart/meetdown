module Evergreen.V29.CreateGroupPage exposing (..)

import Evergreen.V29.Description
import Evergreen.V29.Group
import Evergreen.V29.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V29.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V29.GroupName.GroupName
    , description : Evergreen.V29.Description.Description
    , visibility : Evergreen.V29.Group.GroupVisibility
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
