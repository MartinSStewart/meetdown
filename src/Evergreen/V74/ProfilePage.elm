module Evergreen.V74.ProfilePage exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V74.Description
import Evergreen.V74.EmailAddress
import Evergreen.V74.Name
import Evergreen.V74.Ports
import Evergreen.V74.ProfileImage
import Evergreen.V74.Untrusted


type Editable a
    = Unchanged
    | Editing a


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
    = ChangeNameRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | ChangeProfileImageRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.ProfileImage.ProfileImage)


type Msg
    = FormChanged Form
    | SleepFinished Int
    | PressedProfileImage
    | SelectedImage Effect.File.File
    | GotImageUrl String
    | PressedDeleteAccount
    | MouseDownImageEditor Float Float
    | MouseUpImageEditor Float Float
    | MovedImageEditor Float Float
    | TouchEndImageEditor
    | PressedConfirmImage
    | PressedCancelImage
    | GotImageSize (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | CroppedImage (Result String Evergreen.V74.Ports.CropImageDataResponse)
