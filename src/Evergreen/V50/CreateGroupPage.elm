module Evergreen.V50.CreateGroupPage exposing (..)

import Evergreen.V50.Description
import Evergreen.V50.Group
import Evergreen.V50.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V50.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V50.GroupName.GroupName
    , description : Evergreen.V50.Description.Description
    , visibility : Evergreen.V50.Group.GroupVisibility
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
