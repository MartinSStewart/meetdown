port module Ports exposing (CropImageData, CropImageDataResponse, cropImageDataCodec, cropImageDataResponseCodec, cropImageFromJs, cropImageFromJsName, cropImageToJs, cropImageToJsName, getPrefersDarkTheme, gotPrefersDarkTheme, setPrefersDarkTheme)

import Codec exposing (Codec)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Json.Decode
import Json.Encode
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)


port martinsstewart_crop_image_to_js : Json.Encode.Value -> Cmd msg


port martinsstewart_crop_image_from_js : (Json.Decode.Value -> msg) -> Sub msg


cropImageToJsName : String
cropImageToJsName =
    "martinsstewart_crop_image_to_js"


cropImageToJs : CropImageData -> Command FrontendOnly toBackend msg
cropImageToJs =
    Codec.encodeToValue cropImageDataCodec
        >> Command.sendToJs cropImageToJsName martinsstewart_crop_image_to_js


cropImageFromJsName : String
cropImageFromJsName =
    "martinsstewart_crop_image_from_js"


cropImageFromJs : (Result String CropImageDataResponse -> msg) -> Subscription FrontendOnly msg
cropImageFromJs msg =
    Subscription.fromJs
        cropImageFromJsName
        martinsstewart_crop_image_from_js
        (Codec.decodeValue cropImageDataResponseCodec
            >> Result.mapError Json.Decode.errorToString
            >> msg
        )


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


cropImageDataCodec : Codec CropImageData
cropImageDataCodec =
    Codec.object CropImageData
        |> Codec.field "requestId" .requestId Codec.int
        |> Codec.field "imageUrl" .imageUrl Codec.string
        |> Codec.field "cropX" .cropX quantityCodec
        |> Codec.field "cropY" .cropY quantityCodec
        |> Codec.field "cropWidth" .cropWidth quantityCodec
        |> Codec.field "cropHeight" .cropHeight quantityCodec
        |> Codec.field "width" .width quantityCodec
        |> Codec.field "height" .height quantityCodec
        |> Codec.buildObject


type alias CropImageDataResponse =
    { requestId : Int, croppedImageUrl : String }


cropImageDataResponseCodec : Codec CropImageDataResponse
cropImageDataResponseCodec =
    Codec.object CropImageDataResponse
        |> Codec.field "requestId" .requestId Codec.int
        |> Codec.field "croppedImageUrl" .croppedImageUrl Codec.string
        |> Codec.buildObject


quantityCodec : Codec (Quantity Int units)
quantityCodec =
    Codec.map Quantity.unsafe Quantity.unwrap Codec.int


port get_prefers_dark_theme_to_js : Json.Encode.Value -> Cmd msg


port set_prefers_dark_theme_to_js : Json.Encode.Value -> Cmd msg


port got_prefers_dark_theme_from_js : (Json.Decode.Value -> msg) -> Sub msg


getPrefersDarkTheme : Command FrontendOnly toMsg msg
getPrefersDarkTheme =
    Command.sendToJs
        "get_prefers_dark_theme_to_js"
        get_prefers_dark_theme_to_js
        Json.Encode.null


setPrefersDarkTheme : Bool -> Command FrontendOnly toMsg msg
setPrefersDarkTheme prefersDarkTheme =
    Command.sendToJs
        "set_prefers_dark_theme_to_js"
        set_prefers_dark_theme_to_js
        (Json.Encode.bool prefersDarkTheme)


gotPrefersDarkTheme : (Bool -> msg) -> Subscription FrontendOnly msg
gotPrefersDarkTheme msg =
    Subscription.fromJs
        "got_prefers_dark_theme_from_js"
        got_prefers_dark_theme_from_js
        (Json.Decode.decodeValue Json.Decode.bool >> Result.withDefault False >> msg)
