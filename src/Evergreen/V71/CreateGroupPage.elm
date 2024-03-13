module Evergreen.V71.CreateGroupPage exposing (..)

import Evergreen.V71.Description
import Evergreen.V71.Group
import Evergreen.V71.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V71.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V71.GroupName.GroupName
    , description : Evergreen.V71.Description.Description
    , visibility : Evergreen.V71.Group.GroupVisibility
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
