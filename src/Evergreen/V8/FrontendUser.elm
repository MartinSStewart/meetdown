module Evergreen.V8.FrontendUser exposing (..)

import Evergreen.V8.Description
import Evergreen.V8.Name
import Evergreen.V8.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V8.Name.Name
    , description : Evergreen.V8.Description.Description
    , profileImage : Evergreen.V8.ProfileImage.ProfileImage
    }
