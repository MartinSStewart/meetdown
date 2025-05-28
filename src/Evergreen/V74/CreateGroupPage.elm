module Evergreen.V74.CreateGroupPage exposing (..)

import Evergreen.V74.Description
import Evergreen.V74.Group
import Evergreen.V74.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V74.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V74.GroupName.GroupName
    , description : Evergreen.V74.Description.Description
    , visibility : Evergreen.V74.Group.GroupVisibility
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
