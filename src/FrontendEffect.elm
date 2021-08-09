module FrontendEffect exposing (FrontendEffect(..))

import Browser.Dom
import Duration exposing (Duration)
import MockFile
import NavigationKey exposing (NavigationKey)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Time
import TimeZone


type FrontendEffect toBackend frontendMsg
    = Batch (List (FrontendEffect toBackend frontendMsg))
    | None
    | SendToBackend toBackend
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationLoad String
    | GetTime (Time.Posix -> frontendMsg)
    | Wait Duration frontendMsg
    | SelectFile (List String) (MockFile.File -> frontendMsg)
    | CopyToClipboard String
    | CropImage CropImageData
    | FileToUrl (String -> frontendMsg) MockFile.File
    | GetElement (Result Browser.Dom.Error Browser.Dom.Element -> frontendMsg) String
    | GetWindowSize (Quantity Int Pixels -> Quantity Int Pixels -> frontendMsg)
    | GetTimeZone (Result TimeZone.Error ( String, Time.Zone ) -> frontendMsg)
    | ScrollToTop frontendMsg


type alias CropImageData =
    { requestId : Int
    , imageUrl : String
    , cropX : Quantity Int Pixels
    , cropY : Quantity Int Pixels
    , cropWidth : Quantity Int Pixels
    , cropHeight : Quantity Int Pixels
    , width : Quantity Int Pixels
    , height : Quantity Int Pixels
    }
