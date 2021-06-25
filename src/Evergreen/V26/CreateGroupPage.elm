module Evergreen.V26.CreateGroupPage exposing (..)

import Evergreen.V26.Description
import Evergreen.V26.Group
import Evergreen.V26.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V26.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V26.GroupName.GroupName
    , description : Evergreen.V26.Description.Description
    , visibility : Evergreen.V26.Group.GroupVisibility
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
