module Evergreen.V37.CreateGroupPage exposing (..)

import Evergreen.V37.Description
import Evergreen.V37.Group
import Evergreen.V37.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V37.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V37.GroupName.GroupName
    , description : Evergreen.V37.Description.Description
    , visibility : Evergreen.V37.Group.GroupVisibility
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
