port module Frontend exposing (app)

import Browser.Dom
import Browser.Events
import Browser.Navigation
import Duration exposing (Duration)
import File
import File.Select
import FrontendLogic exposing (Effects, Subscriptions)
import Lamdera
import MockFile
import Pixels exposing (Pixels)
import Process
import Route exposing (Route(..))
import Task
import Time
import TimeZone
import Types exposing (..)


port supermario_copy_to_clipboard_to_js : String -> Cmd msg


port martinsstewart_crop_image_to_js :
    { requestId : Int
    , imageUrl : String
    , cropX : Int
    , cropY : Int
    , cropWidth : Int
    , cropHeight : Int
    , width : Int
    , height : Int
    }
    -> Cmd msg


port martinsstewart_crop_image_from_js : ({ requestId : Int, croppedImageUrl : String } -> msg) -> Sub msg


allEffects : Effects (Cmd FrontendMsg)
allEffects =
    { batch = Cmd.batch
    , none = Cmd.none
    , sendToBackend = Lamdera.sendToBackend
    , navigationPushUrl =
        \navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.pushUrl key string

                MockNavigationKey ->
                    Cmd.none
    , navigationReplaceUrl =
        \navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.replaceUrl key string

                MockNavigationKey ->
                    Cmd.none
    , navigationPushRoute =
        \navigationKey route ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.pushUrl key (Route.encode route)

                MockNavigationKey ->
                    Cmd.none
    , navigationReplaceRoute =
        \navigationKey route ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.replaceUrl key (Route.encode route)

                MockNavigationKey ->
                    Cmd.none
    , navigationLoad = Browser.Navigation.load
    , getTime = \msg -> Time.now |> Task.perform msg
    , wait = \duration msg -> Process.sleep (Duration.inMilliseconds duration) |> Task.perform (always msg)
    , selectFile = \mimeTypes msg -> File.Select.file mimeTypes (MockFile.RealFile >> msg)
    , copyToClipboard = supermario_copy_to_clipboard_to_js
    , cropImage =
        \data ->
            martinsstewart_crop_image_to_js
                { requestId = data.requestId
                , imageUrl = data.imageUrl
                , cropX = Pixels.inPixels data.cropX
                , cropY = Pixels.inPixels data.cropY
                , cropWidth = Pixels.inPixels data.cropWidth
                , cropHeight = Pixels.inPixels data.cropHeight
                , width = Pixels.inPixels data.width
                , height = Pixels.inPixels data.height
                }
    , fileToUrl =
        \msg file ->
            case file of
                MockFile.RealFile realFile ->
                    File.toUrl realFile |> Task.perform msg

                MockFile.MockFile _ ->
                    Cmd.none
    , getElement = \msg elementId -> Browser.Dom.getElement elementId |> Task.attempt msg
    , getWindowSize =
        \msg ->
            Browser.Dom.getViewport
                |> Task.perform
                    (\{ scene } ->
                        msg (Pixels.pixels (round scene.width)) (Pixels.pixels (round scene.height))
                    )
    , getTimeZone = \msg -> TimeZone.getZone |> Task.attempt msg
    }


allSubscriptions : Subscriptions (Sub FrontendMsg)
allSubscriptions =
    { batch = Sub.batch
    , timeEvery = \duration msg -> Time.every (Duration.inMilliseconds duration) msg
    , onResize = \msg -> Browser.Events.onResize (\w h -> msg (Pixels.pixels w) (Pixels.pixels h))
    , cropImageFromJs = martinsstewart_crop_image_from_js
    }


app =
    let
        app_ =
            FrontendLogic.createApp allEffects allSubscriptions
    in
    Lamdera.frontend
        { init = \url navKey -> app_.init url (RealNavigationKey navKey)
        , onUrlRequest = app_.onUrlRequest
        , onUrlChange = app_.onUrlChange
        , update = app_.update
        , updateFromBackend = app_.updateFromBackend
        , subscriptions = app_.subscriptions
        , view = app_.view
        }
