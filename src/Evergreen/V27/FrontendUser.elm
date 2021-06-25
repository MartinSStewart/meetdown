module Evergreen.V27.FrontendUser exposing (..)

import Evergreen.V27.Description
import Evergreen.V27.Name
import Evergreen.V27.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V27.Name.Name
    , description : Evergreen.V27.Description.Description
    , profileImage : Evergreen.V27.ProfileImage.ProfileImage
    }
