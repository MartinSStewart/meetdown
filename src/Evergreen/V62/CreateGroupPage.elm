module Evergreen.V62.CreateGroupPage exposing (..)

import Evergreen.V62.Description
import Evergreen.V62.Group
import Evergreen.V62.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V62.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V62.GroupName.GroupName
    , description : Evergreen.V62.Description.Description
    , visibility : Evergreen.V62.Group.GroupVisibility
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
