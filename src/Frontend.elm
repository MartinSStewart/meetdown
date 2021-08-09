port module Frontend exposing (app)

import Browser.Dom
import Browser.Events
import Browser.Navigation
import Duration exposing (Duration)
import Element
import File
import File.Select
import FrontendEffect exposing (FrontendEffect)
import FrontendLogic exposing (Subscriptions)
import FrontendSub exposing (FrontendSub)
import Html
import Lamdera
import MockFile
import NavigationKey exposing (NavigationKey(..))
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


toCmd : FrontendEffect ToBackend FrontendMsg -> Cmd FrontendMsg
toCmd effect =
    case effect of
        FrontendEffect.Batch effects ->
            List.map toCmd effects |> Cmd.batch

        FrontendEffect.None ->
            Cmd.none

        FrontendEffect.SendToBackend toBackend ->
            Lamdera.sendToBackend toBackend

        FrontendEffect.NavigationPushUrl navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.pushUrl key string

                MockNavigationKey ->
                    Cmd.none

        FrontendEffect.NavigationReplaceUrl navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.replaceUrl key string

                MockNavigationKey ->
                    Cmd.none

        FrontendEffect.NavigationLoad url ->
            Browser.Navigation.load url

        FrontendEffect.GetTime msg ->
            Time.now |> Task.perform msg

        FrontendEffect.Wait duration msg ->
            Process.sleep (Duration.inMilliseconds duration) |> Task.perform (always msg)

        FrontendEffect.SelectFile mimeTypes msg ->
            File.Select.file mimeTypes (MockFile.RealFile >> msg)

        FrontendEffect.CopyToClipboard text ->
            supermario_copy_to_clipboard_to_js text

        FrontendEffect.CropImage data ->
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

        FrontendEffect.FileToUrl msg file ->
            case file of
                MockFile.RealFile realFile ->
                    File.toUrl realFile |> Task.perform msg

                MockFile.MockFile _ ->
                    Cmd.none

        FrontendEffect.GetElement msg elementId ->
            Browser.Dom.getElement elementId |> Task.attempt msg

        FrontendEffect.GetWindowSize msg ->
            Browser.Dom.getViewport
                |> Task.perform
                    (\{ scene } ->
                        msg (Pixels.pixels (round scene.width)) (Pixels.pixels (round scene.height))
                    )

        FrontendEffect.GetTimeZone msg ->
            TimeZone.getZone |> Task.attempt msg

        FrontendEffect.ScrollToTop msg ->
            Browser.Dom.setViewport 0 0 |> Task.perform (\() -> msg)


toSub : FrontendSub FrontendMsg -> Sub FrontendMsg
toSub sub =
    case sub of
        FrontendSub.Batch subs ->
            List.map toSub subs |> Sub.batch

        FrontendSub.TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        FrontendSub.OnResize msg ->
            Browser.Events.onResize (\w h -> msg (Pixels.pixels w) (Pixels.pixels h))

        FrontendSub.CropImageFromJs msg ->
            martinsstewart_crop_image_from_js msg


app =
    Lamdera.frontend
        { init = \url navKey -> FrontendLogic.init url (RealNavigationKey navKey) |> Tuple.mapSecond toCmd
        , onUrlRequest = FrontendLogic.onUrlRequest
        , onUrlChange = FrontendLogic.onUrlChange
        , update = \msg model -> FrontendLogic.update msg model |> Tuple.mapSecond toCmd
        , updateFromBackend = \msg model -> FrontendLogic.updateFromBackend msg model |> Tuple.mapSecond toCmd
        , subscriptions = FrontendLogic.subscriptions >> toSub
        , view =
            \model ->
                let
                    document =
                        FrontendLogic.view model
                in
                { document | body = Html.div [] [ Element.layout [] Element.none ] :: document.body }
        }
