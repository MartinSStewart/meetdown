module Evergreen.V33.FrontendUser exposing (..)

import Evergreen.V33.Description
import Evergreen.V33.Name
import Evergreen.V33.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V33.Name.Name
    , description : Evergreen.V33.Description.Description
    , profileImage : Evergreen.V33.ProfileImage.ProfileImage
    }
