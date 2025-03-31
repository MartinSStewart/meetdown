module Evergreen.V73.CreateGroupPage exposing (..)

import Evergreen.V73.Description
import Evergreen.V73.Group
import Evergreen.V73.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V73.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V73.GroupName.GroupName
    , description : Evergreen.V73.Description.Description
    , visibility : Evergreen.V73.Group.GroupVisibility
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
