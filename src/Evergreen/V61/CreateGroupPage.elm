module Evergreen.V61.CreateGroupPage exposing (..)

import Evergreen.V61.Description
import Evergreen.V61.Group
import Evergreen.V61.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V61.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V61.GroupName.GroupName
    , description : Evergreen.V61.Description.Description
    , visibility : Evergreen.V61.Group.GroupVisibility
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
