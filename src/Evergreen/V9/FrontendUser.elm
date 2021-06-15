module Evergreen.V9.FrontendUser exposing (..)

import Evergreen.V9.Description
import Evergreen.V9.Name
import Evergreen.V9.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V9.Name.Name
    , description : Evergreen.V9.Description.Description
    , profileImage : Evergreen.V9.ProfileImage.ProfileImage
    }
