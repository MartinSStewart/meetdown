module Evergreen.V63.FrontendUser exposing (..)

import Evergreen.V63.Description
import Evergreen.V63.Name
import Evergreen.V63.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V63.Name.Name
    , description : Evergreen.V63.Description.Description
    , profileImage : Evergreen.V63.ProfileImage.ProfileImage
    }
