module Evergreen.V73.FrontendUser exposing (..)

import Evergreen.V73.Description
import Evergreen.V73.Name
import Evergreen.V73.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V73.Name.Name
    , description : Evergreen.V73.Description.Description
    , profileImage : Evergreen.V73.ProfileImage.ProfileImage
    }
