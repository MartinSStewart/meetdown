module Evergreen.V29.FrontendUser exposing (..)

import Evergreen.V29.Description
import Evergreen.V29.Name
import Evergreen.V29.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V29.Name.Name
    , description : Evergreen.V29.Description.Description
    , profileImage : Evergreen.V29.ProfileImage.ProfileImage
    }
