module Evergreen.V48.CreateGroupPage exposing (..)

import Evergreen.V48.Description
import Evergreen.V48.Group
import Evergreen.V48.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V48.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V48.GroupName.GroupName
    , description : Evergreen.V48.Description.Description
    , visibility : Evergreen.V48.Group.GroupVisibility
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
