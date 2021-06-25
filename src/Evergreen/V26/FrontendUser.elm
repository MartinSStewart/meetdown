module Evergreen.V26.FrontendUser exposing (..)

import Evergreen.V26.Description
import Evergreen.V26.Name
import Evergreen.V26.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V26.Name.Name
    , description : Evergreen.V26.Description.Description
    , profileImage : Evergreen.V26.ProfileImage.ProfileImage
    }
