module Evergreen.V12.CreateGroupForm exposing (..)

import Evergreen.V12.Description
import Evergreen.V12.Group
import Evergreen.V12.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V12.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V12.GroupName.GroupName
    , description : Evergreen.V12.Description.Description
    , visibility : Evergreen.V12.Group.GroupVisibility
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
