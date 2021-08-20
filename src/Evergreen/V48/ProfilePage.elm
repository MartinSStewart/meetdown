module Evergreen.V48.ProfilePage exposing (..)

import Evergreen.V48.Description
import Evergreen.V48.Effect.Browser.Dom
import Evergreen.V48.Effect.File
import Evergreen.V48.EmailAddress
import Evergreen.V48.Name
import Evergreen.V48.Ports
import Evergreen.V48.ProfileImage
import Evergreen.V48.Untrusted


type Editable a
    = Unchanged
    | Editting a


type alias Form =
    { name : Editable String
    , description : Editable String
    , emailAddress : Editable String
    }


type DragPart
    = TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
    | Center


type alias DragState =
    { startX : Float
    , startY : Float
    , dragPart : DragPart
    , currentX : Float
    , currentY : Float
    }


type alias ImageEdit =
    { x : Float
    , y : Float
    , size : Float
    , imageUrl : String
    , dragState : Maybe DragState
    , imageSize : Maybe ( Int, Int )
    }


type alias Model =
    { form : Form
    , changeCounter : Int
    , profileImage : Editable (Maybe ImageEdit)
    , profileImageSize : Maybe ( Int, Int )
    , pressedDeleteAccount : Bool
    }


type ToBackend
    = ChangeNameRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | ChangeProfileImageRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.ProfileImage.ProfileImage)


type Msg
    = FormChanged Form
    | SleepFinished Int
    | PressedProfileImage
    | SelectedImage Evergreen.V48.Effect.File.File
    | GotImageUrl String
    | PressedDeleteAccount
    | MouseDownImageEditor Float Float
    | MouseUpImageEditor Float Float
    | MovedImageEditor Float Float
    | TouchEndImageEditor
    | PressedConfirmImage
    | PressedCancelImage
    | GotImageSize (Result Evergreen.V48.Effect.Browser.Dom.Error Evergreen.V48.Effect.Browser.Dom.Element)
    | CroppedImage (Result String Evergreen.V48.Ports.CropImageDataResponse)
