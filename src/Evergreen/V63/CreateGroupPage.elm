module Evergreen.V63.CreateGroupPage exposing (..)

import Evergreen.V63.Description
import Evergreen.V63.Group
import Evergreen.V63.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V63.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V63.GroupName.GroupName
    , description : Evergreen.V63.Description.Description
    , visibility : Evergreen.V63.Group.GroupVisibility
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
