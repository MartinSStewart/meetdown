module Evergreen.V46.CreateGroupPage exposing (..)

import Evergreen.V46.Description
import Evergreen.V46.Group
import Evergreen.V46.GroupName


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe Evergreen.V46.Group.GroupVisibility
    }


type alias GroupFormValidated =
    { name : Evergreen.V46.GroupName.GroupName
    , description : Evergreen.V46.Description.Description
    , visibility : Evergreen.V46.Group.GroupVisibility
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
