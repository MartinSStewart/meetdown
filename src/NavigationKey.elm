module NavigationKey exposing (..)

import Browser.Navigation


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey
