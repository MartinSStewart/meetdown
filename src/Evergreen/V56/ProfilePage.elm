module Evergreen.V56.ProfilePage exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V56.Description
import Evergreen.V56.EmailAddress
import Evergreen.V56.Name
import Evergreen.V56.Ports
import Evergreen.V56.ProfileImage
import Evergreen.V56.Untrusted


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
    = ChangeNameRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | ChangeProfileImageRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.ProfileImage.ProfileImage)


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
    | CroppedImage (Result String Evergreen.V56.Ports.CropImageDataResponse)
