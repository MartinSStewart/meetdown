module Evergreen.V13.FrontendUser exposing (..)

import Evergreen.V13.Description
import Evergreen.V13.Name
import Evergreen.V13.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V13.Name.Name
    , description : Evergreen.V13.Description.Description
    , profileImage : Evergreen.V13.ProfileImage.ProfileImage
    }
