module ProfilePage exposing (CurrentValues, Effects, Form, Model, Msg, cancelImageButtonId, cropImageResponse, deleteAccountButtonId, imageEditorIsActive, init, update, uploadImageButtonId, view)

import Browser.Dom
import Colors exposing (..)
import Description exposing (Description, Error(..))
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import EmailAddress exposing (EmailAddress)
import Html
import Html.Attributes
import Html.Events
import Html.Events.Extra.Touch
import Id exposing (ButtonId(..))
import Json.Decode
import List.Extra as List
import MockFile exposing (File)
import Name exposing (Error(..), Name)
import Pixels exposing (Pixels)
import ProfileImage exposing (ProfileImage)
import Quantity exposing (Quantity)
import Ui
import Untrusted exposing (Untrusted)


type Msg
    = FormChanged Form
    | SleepFinished Int
    | PressedProfileImage
    | SelectedImage File
    | GotImageUrl String
    | PressedDeleteAccount
    | MouseDownImageEditor Float Float
    | MouseUpImageEditor Float Float
    | MovedImageEditor Float Float
    | TouchEndImageEditor
    | PressedConfirmImage
    | PressedCancelImage
    | GotImageSize (Result Browser.Dom.Error Browser.Dom.Element)


type alias ImageEdit =
    { x : Float
    , y : Float
    , size : Float
    , imageUrl : String
    , dragState : Maybe DragState
    , imageSize : Maybe ( Int, Int )
    }


type alias DragState =
    { startX : Float
    , startY : Float
    , dragPart : DragPart
    , currentX : Float
    , currentY : Float
    }


type DragPart
    = TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
    | Center


type Editable a
    = Unchanged
    | Editting a


type alias Model =
    { form : Form
    , changeCounter : Int
    , profileImage : Editable (Maybe ImageEdit)
    , profileImageSize : Maybe ( Int, Int )
    , pressedDeleteAccount : Bool
    }


type alias Form =
    { name : Editable String
    , description : Editable String
    , emailAddress : Editable String
    }


type alias CurrentValues =
    { name : Name
    , description : Description
    , emailAddress : EmailAddress
    , profileImage : ProfileImage
    }


init : Model
init =
    { form =
        { name = Unchanged
        , description = Unchanged
        , emailAddress = Unchanged
        }
    , changeCounter = 0
    , profileImage = Unchanged
    , profileImageSize = Nothing
    , pressedDeleteAccount = False
    }


type alias Effects cmd =
    { wait : Duration -> Msg -> cmd
    , none : cmd
    , changeName : Untrusted Name -> cmd
    , changeDescription : Untrusted Description -> cmd
    , changeEmailAddress : Untrusted EmailAddress -> cmd
    , selectFile : List String -> (File -> Msg) -> cmd
    , getFileContents : (String -> Msg) -> File -> cmd
    , setCanvasImage :
        { requestId : Int
        , imageUrl : String
        , cropX : Quantity Int Pixels
        , cropY : Quantity Int Pixels
        , cropWidth : Quantity Int Pixels
        , cropHeight : Quantity Int Pixels
        , width : Quantity Int Pixels
        , height : Quantity Int Pixels
        }
        -> cmd
    , sendDeleteAccountEmail : cmd
    , getElement : (Result Browser.Dom.Error Browser.Dom.Element -> Msg) -> String -> cmd
    , batch : List cmd -> cmd
    }


update :
    { c | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels }
    -> Effects cmd
    -> Msg
    -> Model
    -> ( Model, cmd )
update windowSize effects msg model =
    case msg of
        FormChanged newForm ->
            ( { model | form = newForm, changeCounter = model.changeCounter + 1 }
            , effects.wait (Duration.seconds 2) (SleepFinished (model.changeCounter + 1))
            )

        SleepFinished changeCount ->
            let
                validate : (a -> Maybe b) -> Editable a -> Maybe b
                validate validator editable =
                    case editable of
                        Editting value ->
                            validator value

                        Unchanged ->
                            Nothing
            in
            ( model
            , if changeCount == model.changeCounter then
                [ validate
                    (Name.fromString >> Result.toMaybe >> Maybe.map (Untrusted.untrust >> effects.changeName))
                    model.form.name
                , validate
                    (Description.fromString >> Result.toMaybe >> Maybe.map (Untrusted.untrust >> effects.changeDescription))
                    model.form.description
                , validate
                    (EmailAddress.fromString >> Maybe.map (Untrusted.untrust >> effects.changeEmailAddress))
                    model.form.emailAddress
                ]
                    |> List.filterMap identity
                    |> effects.batch

              else
                effects.none
            )

        PressedProfileImage ->
            ( model, effects.selectFile [ "image/png", "image/jpg", "image/jpeg" ] SelectedImage )

        SelectedImage file ->
            ( model, effects.getFileContents GotImageUrl file )

        PressedDeleteAccount ->
            ( { model | pressedDeleteAccount = True }, effects.sendDeleteAccountEmail )

        GotImageUrl imageUrl ->
            ( { model
                | profileImage =
                    Editting (Just { x = 0.1, y = 0.1, size = 0.8, imageUrl = imageUrl, dragState = Nothing, imageSize = Nothing })
              }
            , effects.getElement GotImageSize profileImagePlaceholderId
            )

        MouseDownImageEditor x y ->
            case model.profileImage of
                Editting (Just ({ dragState } as imageData)) ->
                    let
                        ( tx, ty ) =
                            ( pixelToT windowSize x, pixelToT windowSize y )

                        dragPart : Maybe ( DragPart, Float )
                        dragPart =
                            [ ( TopLeft, imageData.x, imageData.y )
                            , ( TopRight, imageData.x + imageData.size, imageData.y )
                            , ( BottomLeft, imageData.x, imageData.y + imageData.size )
                            , ( BottomRight, imageData.x + imageData.size, imageData.y + imageData.size )
                            ]
                                |> List.map
                                    (\( part, partX, partY ) ->
                                        ( part, (partX - tx) ^ 2 + (partY - ty) ^ 2 |> sqrt )
                                    )
                                |> List.minimumBy Tuple.second

                        newDragState =
                            { startX = tx
                            , startY = ty
                            , dragPart =
                                case dragPart of
                                    Just ( part, distance ) ->
                                        if distance > 0.07 then
                                            Center

                                        else
                                            part

                                    Nothing ->
                                        Center
                            , currentX = tx
                            , currentY = ty
                            }
                    in
                    ( { model
                        | profileImage = Editting (Just { imageData | dragState = Just newDragState })
                      }
                    , effects.none
                    )

                _ ->
                    ( model, effects.none )

        MovedImageEditor x y ->
            case model.profileImage of
                Editting (Just imageData) ->
                    ( { model
                        | profileImage =
                            Editting (Just (updateDragState (pixelToT windowSize x) (pixelToT windowSize y) imageData))
                      }
                    , effects.none
                    )

                _ ->
                    ( model, effects.none )

        MouseUpImageEditor x y ->
            case model.profileImage of
                Editting (Just imageData) ->
                    let
                        newImageData =
                            updateDragState (pixelToT windowSize x) (pixelToT windowSize y) imageData
                                |> getActualImageState
                                |> (\a -> { a | dragState = Nothing })
                    in
                    ( { model | profileImage = Editting (Just newImageData) }
                    , effects.none
                    )

                _ ->
                    ( model, effects.none )

        TouchEndImageEditor ->
            case model.profileImage of
                Editting (Just imageData) ->
                    let
                        newImageData =
                            getActualImageState imageData
                                |> (\a -> { a | dragState = Nothing })
                    in
                    ( { model | profileImage = Editting (Just newImageData) }
                    , effects.none
                    )

                _ ->
                    ( model, effects.none )

        PressedConfirmImage ->
            case model.profileImage of
                Editting (Just imageData) ->
                    case imageData.imageSize of
                        Just ( w, _ ) ->
                            ( model
                            , effects.setCanvasImage
                                { requestId = 0
                                , imageUrl = imageData.imageUrl
                                , cropX = imageData.x * toFloat w |> round |> Pixels.pixels
                                , cropY = imageData.y * toFloat w |> round |> Pixels.pixels
                                , cropWidth = ProfileImage.size
                                , cropHeight = ProfileImage.size
                                , width = toFloat w * imageData.size |> round |> Pixels.pixels
                                , height = toFloat w * imageData.size |> round |> Pixels.pixels
                                }
                            )

                        Nothing ->
                            ( model, effects.none )

                _ ->
                    ( model, effects.none )

        PressedCancelImage ->
            ( { model | profileImage = Unchanged }, effects.none )

        GotImageSize result ->
            case ( result, model.profileImage ) of
                ( Ok { element }, Editting (Just imageData) ) ->
                    if element.height <= 0 then
                        ( model, effects.getElement GotImageSize profileImagePlaceholderId )

                    else
                        ( { model
                            | profileImage =
                                { imageData
                                    | imageSize = Just ( round element.width, round element.height )
                                    , x = 0.05
                                    , y = 0.05
                                    , size = min 0.9 (element.height / element.width - 0.1)
                                }
                                    |> Just
                                    |> Editting
                          }
                        , effects.none
                        )

                _ ->
                    ( model, effects.none )


updateDragState : Float -> Float -> ImageEdit -> ImageEdit
updateDragState tx ty imageData =
    { imageData
        | dragState =
            case imageData.dragState of
                Just dragState_ ->
                    { dragState_ | currentX = tx, currentY = ty } |> Just

                Nothing ->
                    imageData.dragState
    }


getActualImageState : ImageEdit -> ImageEdit
getActualImageState imageData =
    let
        aspectRatio : Float
        aspectRatio =
            case imageData.imageSize of
                Just ( w, h ) ->
                    toFloat h / toFloat w

                Nothing ->
                    1

        minX =
            0

        maxX =
            1

        minY =
            0

        maxY =
            aspectRatio
    in
    case imageData.dragState of
        Just dragState ->
            case dragState.dragPart of
                Center ->
                    { imageData
                        | x = clamp minX (maxX - imageData.size) (imageData.x + dragState.currentX - dragState.startX)
                        , y = clamp minY (maxY - imageData.size) (imageData.y + dragState.currentY - dragState.startY)
                    }

                TopLeft ->
                    let
                        xDelta =
                            dragState.currentX - dragState.startX

                        yDelta =
                            dragState.currentY - dragState.startY

                        maxDelta =
                            min xDelta yDelta
                                |> min (imageData.size - 0.05)
                                |> max -(min imageData.x imageData.y)
                    in
                    { imageData
                        | x = imageData.x + maxDelta
                        , y = imageData.y + maxDelta
                        , size = imageData.size - maxDelta
                    }

                TopRight ->
                    let
                        xDelta =
                            dragState.currentX - dragState.startX

                        yDelta =
                            dragState.currentY - dragState.startY

                        maxDelta =
                            min -xDelta yDelta
                                |> min (imageData.size - 0.05)
                                |> max -(min (maxX - imageData.x - imageData.size) imageData.y)
                    in
                    { imageData
                        | y = imageData.y + maxDelta
                        , size = imageData.size - maxDelta
                    }

                BottomLeft ->
                    let
                        xDelta =
                            dragState.currentX - dragState.startX

                        yDelta =
                            dragState.currentY - dragState.startY

                        maxDelta =
                            min xDelta -yDelta
                                |> min (imageData.size - 0.05)
                                |> max -(min imageData.x (maxY - imageData.y - imageData.size))
                    in
                    { imageData
                        | x = imageData.x + maxDelta
                        , size = imageData.size - maxDelta
                    }

                BottomRight ->
                    let
                        xDelta =
                            dragState.currentX - dragState.startX

                        yDelta =
                            dragState.currentY - dragState.startY

                        maxDelta =
                            min -xDelta -yDelta
                                |> min (imageData.size - 0.05)
                                |> max
                                    -(min
                                        (maxX - imageData.x - imageData.size)
                                        (maxY - imageData.y - imageData.size)
                                     )
                    in
                    { imageData | size = imageData.size - maxDelta }

        Nothing ->
            imageData


cropImageResponse : { requestId : Int, croppedImageUrl : String } -> Model -> Model
cropImageResponse imageData model =
    { model | profileImage = Unchanged }


pixelToT : { a | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels } -> Float -> Float
pixelToT windowSize value =
    value / toFloat (imageEditorWidth windowSize)


tToPixel : { a | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels } -> Float -> Float
tToPixel windowSize value =
    value * toFloat (imageEditorWidth windowSize)


imageEditorWidth : { a | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels } -> Int
imageEditorWidth windowSize =
    min 400 (Pixels.inPixels windowSize.windowWidth)


profileImagePlaceholderId : String
profileImagePlaceholderId =
    "profile-image-placeholder-id"


imageEditorIsActive : Model -> Bool
imageEditorIsActive model =
    case model.profileImage of
        Editting (Just _) ->
            True

        _ ->
            False


imageEditorView :
    { a | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels }
    -> ImageEdit
    -> Element Msg
imageEditorView windowSize imageEdit =
    let
        { x, y, size, imageUrl, dragState } =
            getActualImageState imageEdit

        drawNode x_ y_ =
            Element.inFront
                (Element.el
                    [ Element.width (Element.px 8)
                    , Element.height (Element.px 8)
                    , Element.moveRight (tToPixel windowSize x_ - 4)
                    , Element.moveDown (tToPixel windowSize y_ - 4)
                    , Element.Background.color <| Element.rgb 1 1 1
                    , Element.Border.width 2
                    , Element.Border.color <| Element.rgb 0 0 0
                    , Element.htmlAttribute <| Html.Attributes.style "pointer-events" "none"
                    ]
                    Element.none
                )

        drawHorizontalLine x_ y_ width =
            Element.inFront
                (Element.el
                    [ Element.width (Element.px <| round (tToPixel windowSize width))
                    , Element.height (Element.px 6)
                    , Element.moveRight (tToPixel windowSize x_)
                    , Element.moveDown (tToPixel windowSize y_ - 3)
                    , Element.Background.color <| Element.rgb 1 1 1
                    , Element.Border.width 2
                    , Element.Border.color <| Element.rgb 0 0 0
                    , Element.htmlAttribute <| Html.Attributes.style "pointer-events" "none"
                    ]
                    Element.none
                )

        drawVerticalLine x_ y_ height =
            Element.inFront
                (Element.el
                    [ Element.height (Element.px <| round (tToPixel windowSize height))
                    , Element.width (Element.px 6)
                    , Element.moveRight (tToPixel windowSize x_ - 3)
                    , Element.moveDown (tToPixel windowSize y_)
                    , Element.Background.color <| Element.rgb 1 1 1
                    , Element.Border.width 2
                    , Element.Border.color <| Element.rgb 0 0 0
                    , Element.htmlAttribute <| Html.Attributes.style "pointer-events" "none"
                    ]
                    Element.none
                )

        imageEditorWidth_ =
            imageEditorWidth windowSize
    in
    Element.column
        [ Element.spacing 8
        , Element.inFront <|
            case imageEdit.imageSize of
                Just _ ->
                    Element.none

                Nothing ->
                    Element.el
                        [ Element.transparent True
                        , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                        ]
                        (Element.html <|
                            Html.img
                                [ Html.Attributes.id profileImagePlaceholderId
                                , Html.Attributes.src imageUrl
                                ]
                                []
                        )
        , Element.centerX
        ]
        [ Element.image
            [ Element.width <| Element.px imageEditorWidth_
            , case imageEdit.imageSize of
                Just ( w, h ) ->
                    Element.height <| Element.px <| round <| toFloat (imageEditorWidth_ * h) / toFloat w

                Nothing ->
                    Element.inFront Element.none
            , Json.Decode.map2 (\x_ y_ -> ( MouseDownImageEditor x_ y_, True ))
                (Json.Decode.field "offsetX" Json.Decode.float)
                (Json.Decode.field "offsetY" Json.Decode.float)
                |> Html.Events.preventDefaultOn "mousedown"
                |> Element.htmlAttribute
            , Json.Decode.map2 (\x_ y_ -> ( MouseUpImageEditor x_ y_, True ))
                (Json.Decode.field "offsetX" Json.Decode.float)
                (Json.Decode.field "offsetY" Json.Decode.float)
                |> Html.Events.preventDefaultOn "mouseup"
                |> Element.htmlAttribute
            , if dragState == Nothing then
                Html.Events.on "" (Json.Decode.succeed (MovedImageEditor 0 0))
                    |> Element.htmlAttribute

              else
                Json.Decode.map2 (\x_ y_ -> ( MovedImageEditor x_ y_, True ))
                    (Json.Decode.field "offsetX" Json.Decode.float)
                    (Json.Decode.field "offsetY" Json.Decode.float)
                    |> Html.Events.preventDefaultOn "mousemove"
                    |> Element.htmlAttribute
            , Html.Events.Extra.Touch.onStart
                (\event ->
                    case List.reverse event.touches |> List.head of
                        Just last ->
                            MouseDownImageEditor (Tuple.first last.clientPos) (Tuple.second last.clientPos)

                        Nothing ->
                            MouseDownImageEditor 0 0
                )
                |> Element.htmlAttribute
            , Html.Events.Extra.Touch.onEnd (\_ -> TouchEndImageEditor) |> Element.htmlAttribute
            , if dragState == Nothing then
                Html.Events.on "" (Json.Decode.succeed (MovedImageEditor 0 0))
                    |> Element.htmlAttribute

              else
                Html.Events.Extra.Touch.onMove
                    (\event ->
                        case List.reverse event.touches |> List.head of
                            Just last ->
                                MovedImageEditor (Tuple.first last.clientPos) (Tuple.second last.clientPos)

                            Nothing ->
                                MovedImageEditor 0 0
                    )
                    |> Element.htmlAttribute
            , Element.inFront
                (Element.el
                    [ Element.height (Element.px <| round (size * toFloat imageEditorWidth_))
                    , Element.width (Element.px <| round (size * toFloat imageEditorWidth_))
                    , Element.moveRight (x * toFloat imageEditorWidth_)
                    , Element.moveDown (y * toFloat imageEditorWidth_)
                    , Element.Border.width 2
                    , Element.Border.color <| Element.rgb 0 0 0
                    , Element.Border.rounded 99999
                    , Element.htmlAttribute <| Html.Attributes.style "pointer-events" "none"
                    ]
                    Element.none
                )
            , Element.inFront
                (Element.el
                    [ Element.height (Element.px <| round (size * toFloat imageEditorWidth_ - 4))
                    , Element.width (Element.px <| round (size * toFloat imageEditorWidth_ - 4))
                    , Element.moveRight (x * toFloat imageEditorWidth_ + 2)
                    , Element.moveDown (y * toFloat imageEditorWidth_ + 2)
                    , Element.Border.width 2
                    , Element.Border.color <| Element.rgb 1 1 1
                    , Element.Border.rounded 99999
                    , Element.htmlAttribute <| Html.Attributes.style "pointer-events" "none"
                    ]
                    Element.none
                )
            , drawHorizontalLine x y size
            , drawHorizontalLine x (y + size) size
            , drawVerticalLine x y size
            , drawVerticalLine (x + size) y size
            , drawNode x y
            , drawNode (x + size) y
            , drawNode x (y + size)
            , drawNode (x + size) (y + size)
            ]
            { src = imageUrl
            , description = "Image editor"
            }
        , Element.row
            [ Element.width Element.fill ]
            [ Ui.submitButton uploadImageButtonId False { onPress = PressedConfirmImage, label = "Upload image" }
            , Element.el
                [ Element.alignRight ]
                (Ui.button cancelImageButtonId { onPress = PressedCancelImage, label = "Cancel" })
            ]
        ]


uploadImageButtonId =
    Id.buttonId "profileUploadImage"


cancelImageButtonId =
    Id.buttonId "profileCancelImage"


view :
    { b | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels }
    -> CurrentValues
    -> Model
    -> Element Msg
view windowSize currentValues ({ form } as model) =
    case model.profileImage of
        Editting (Just imageEdit) ->
            imageEditorView windowSize imageEdit

        _ ->
            Element.column
                [ Element.spacing 20
                , Element.padding 8
                , Ui.contentWidth
                , Element.centerX
                ]
                [ Element.wrappedRow [ Element.width Element.fill ]
                    [ Element.el [ Element.alignTop ] (Ui.title "Profile")
                    , Element.Input.button
                        [ Element.alignRight
                        , Element.Border.rounded 9999
                        , Element.clip
                        , Element.Background.color grey
                        ]
                        { onPress = Just PressedProfileImage
                        , label = ProfileImage.image currentValues.profileImage
                        }
                    ]
                , Ui.columnCard
                    [ editableTextInput
                        (\a -> FormChanged { form | name = a })
                        Name.toString
                        (\a ->
                            case Name.fromString a of
                                Ok name ->
                                    Ok name

                                Err Name.NameTooShort ->
                                    Err "Your name can't be empty"

                                Err Name.NameTooLong ->
                                    "Keep it below " ++ String.fromInt (Name.maxLength + 1) ++ " characters" |> Err
                        )
                        currentValues.name
                        form.name
                        "Your name"
                    , editableMultiline
                        (\a -> FormChanged { form | description = a })
                        Description.toString
                        (\a ->
                            case Description.fromString a of
                                Ok name ->
                                    Ok name

                                Err DescriptionTooLong ->
                                    "Less than "
                                        ++ String.fromInt Description.maxLength
                                        ++ " characters please"
                                        |> Err
                        )
                        currentValues.description
                        form.description
                        "What do you want people to know about you?"
                    , editableEmailInput
                        (\_ -> FormChanged form)
                        --(\a -> FormChanged { form | emailAddress = a })
                        EmailAddress.toString
                        (EmailAddress.fromString >> Result.fromMaybe "Invalid email")
                        currentValues.emailAddress
                        form.emailAddress
                        "Your email address"
                    ]
                , Ui.dangerButton deleteAccountButtonId { onPress = PressedDeleteAccount, label = "Delete account" }
                , if model.pressedDeleteAccount then
                    Element.column
                        [ Element.spacing 20 ]
                        [ Element.paragraph []
                            [ Element.text "An account deletion email has been sent to "
                            , Ui.emailAddressText currentValues.emailAddress
                            , Element.text ". Press the link in it to confirm deleting your account."
                            ]
                        , Element.paragraph [] [ Element.text "If you don't see the email, check your spam folder." ]
                        ]

                  else
                    Element.none
                ]


deleteAccountButtonId : Id.HtmlId ButtonId
deleteAccountButtonId =
    Id.buttonId "profileDeleteAccount"


editableTextInput :
    (Editable String -> msg)
    -> (a -> String)
    -> (String -> Result String a)
    -> a
    -> Editable String
    -> String
    -> Element msg
editableTextInput onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editting edit ->
                    validate edit

        maybeError =
            case result of
                Ok _ ->
                    Nothing

                Err error ->
                    Just error
    in
    Element.column
        [ Element.width Element.fill
        ]
        [ Element.Input.text
            [ Element.width Element.fill
            , Element.Border.rounded 4
            , Ui.inputBorder (maybeError /= Nothing)
            , Ui.inputBorderWidth (maybeError /= Nothing)
            ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editting value ->
                        value
            , onChange = Editting >> onChange
            , placeholder = Nothing
            , label = Ui.formLabelAbove labelText
            }
        , case maybeError of
            Just error ->
                Ui.error error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    savingText
        ]


editableEmailInput :
    (Editable String -> msg)
    -> (a -> String)
    -> (String -> Result String a)
    -> a
    -> Editable String
    -> String
    -> Element msg
editableEmailInput onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editting edit ->
                    validate edit

        maybeError =
            case result of
                Ok _ ->
                    Nothing

                Err error ->
                    Just error
    in
    Element.column
        [ Element.width Element.fill
        , Ui.inputBackground (maybeError /= Nothing)
        , Element.Border.rounded 4
        ]
        [ Element.Input.email
            [ Element.width Element.fill
            , Element.Border.color darkGrey
            ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editting value ->
                        value
            , onChange = Editting >> onChange
            , placeholder = Nothing
            , label = Ui.formLabelAbove labelText
            }
        , case maybeError of
            Just error ->
                Ui.error error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    savingText
        ]


editableMultiline : (Editable String -> msg) -> (a -> String) -> (String -> Result String a) -> a -> Editable String -> String -> Element msg
editableMultiline onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editting edit ->
                    validate edit

        maybeError =
            case result of
                Ok _ ->
                    Nothing

                Err error ->
                    Just error
    in
    Element.column
        [ Element.width Element.fill
        , Element.Border.rounded 4
        ]
        [ Element.Input.multiline
            [ Element.width Element.fill
            , Element.height (Element.px 200)
            , Ui.inputBorder (maybeError /= Nothing)
            , Ui.inputBorderWidth (maybeError /= Nothing)
            ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editting value ->
                        value
            , onChange = Editting >> onChange
            , placeholder = Nothing
            , label = Ui.formLabelAbove labelText
            , spellcheck = True
            }
        , case maybeError of
            Just error ->
                Ui.error error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    savingText
        ]


savingText =
    Element.el
        [ Element.paddingEach { left = 0, right = 0, top = 10, bottom = 0 }
        , Element.Font.size 12
        ]
        (Element.text "Saving...")
