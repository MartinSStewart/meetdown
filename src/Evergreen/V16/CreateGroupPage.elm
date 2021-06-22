module Evergreen.V16.CreateGroupPage exposing (..)

import Evergreen.V16.Description
import Evergreen.V16.Group
import Evergreen.V16.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V16.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V16.GroupName.GroupName
    , description : Evergreen.V16.Description.Description
    , visibility : Evergreen.V16.Group.GroupVisibility
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
