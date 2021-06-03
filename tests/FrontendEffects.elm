module FrontendEffects exposing (FrontendEffect(..), effects)

import Browser.Dom
import Duration exposing (Duration)
import Frontend exposing (CropImageData)
import List.Nonempty
import MockFile
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Route
import Time
import TimeZone
import Types exposing (FrontendMsg, NavigationKey, ToBackend(..))


type FrontendEffect
    = Batch (List FrontendEffect)
    | None
    | SendToBackend ToBackend
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationLoad String
    | GetTime (Time.Posix -> FrontendMsg)
    | Wait Duration FrontendMsg
    | SelectFile (List String) (MockFile.File -> FrontendMsg)
    | CopyToClipboard String
    | CropImage CropImageData
    | FileToUrl (String -> FrontendMsg) MockFile.File
    | GetElement (Result Browser.Dom.Error Browser.Dom.Element -> FrontendMsg) String
    | GetWindowSize (Quantity Int Pixels -> Quantity Int Pixels -> FrontendMsg)
    | GetTimeZone (Result TimeZone.Error ( String, Time.Zone ) -> FrontendMsg)


effects : Frontend.Effects FrontendEffect
effects =
    { batch = Batch
    , none = None
    , sendToBackend = List.Nonempty.fromElement >> ToBackend >> SendToBackend
    , navigationPushUrl = NavigationPushUrl
    , navigationReplaceUrl = NavigationReplaceUrl
    , navigationPushRoute = \navigationKey route -> NavigationPushUrl navigationKey (Route.encode route)
    , navigationReplaceRoute = \navigationKey route -> NavigationReplaceUrl navigationKey (Route.encode route)
    , navigationLoad = NavigationLoad
    , getTime = GetTime
    , wait = Wait
    , selectFile = SelectFile
    , copyToClipboard = CopyToClipboard
    , cropImage = CropImage
    , fileToUrl = FileToUrl
    , getElement = GetElement
    , getWindowSize = GetWindowSize
    , getTimeZone = GetTimeZone
    }
