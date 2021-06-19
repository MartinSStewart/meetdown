module Evergreen.V12.FrontendUser exposing (..)

import Evergreen.V12.Description
import Evergreen.V12.Name
import Evergreen.V12.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V12.Name.Name
    , description : Evergreen.V12.Description.Description
    , profileImage : Evergreen.V12.ProfileImage.ProfileImage
    }
