module ProfilePage exposing
    ( CurrentValues
    , Form
    , Model
    , Msg
    , ToBackend(..)
    , deleteAccountButtonId
    , descriptionTextInputId
    , imageEditorIsActive
    , init
    , nameTextInputId
    , subscriptions
    , update
    , view
    )

import Description exposing (Description, Error(..))
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.File.Select as FileSelect
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Subscription exposing (Subscription)
import Effect.Task as Task
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
import HtmlId
import Json.Decode
import List.Extra as List
import MyUi
import Name exposing (Error(..), Name)
import Pixels exposing (Pixels)
import Ports exposing (CropImageDataResponse)
import ProfileImage exposing (ProfileImage)
import Quantity exposing (Quantity)
import Untrusted exposing (Untrusted)
import UserConfig exposing (Texts, UserConfig)


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
    | GotImageSize (Result Dom.Error Dom.Element)
    | CroppedImage (Result String CropImageDataResponse)


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
    | Editing a


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


type ToBackend
    = ChangeNameRequest (Untrusted Name)
    | ChangeDescriptionRequest (Untrusted Description)
    | ChangeEmailAddressRequest (Untrusted EmailAddress)
    | SendDeleteUserEmailRequest
    | ChangeProfileImageRequest (Untrusted ProfileImage)


update :
    { c | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels }
    -> Msg
    -> Model
    -> ( Model, Command FrontendOnly ToBackend Msg )
update windowSize msg model =
    case msg of
        FormChanged newForm ->
            ( { model | form = newForm, changeCounter = model.changeCounter + 1 }
            , Process.sleep (Duration.seconds 2)
                |> Task.perform (\() -> SleepFinished (model.changeCounter + 1))
            )

        SleepFinished changeCount ->
            let
                validate : (a -> Maybe b) -> Editable a -> Maybe b
                validate validator editable =
                    case editable of
                        Editing value ->
                            validator value

                        Unchanged ->
                            Nothing
            in
            ( model
            , if changeCount == model.changeCounter then
                [ validate
                    (Name.fromString
                        >> Result.toMaybe
                        >> Maybe.map (Untrusted.untrust >> ChangeNameRequest >> Lamdera.sendToBackend)
                    )
                    model.form.name
                , validate
                    (Description.fromString
                        >> Result.toMaybe
                        >> Maybe.map (Untrusted.untrust >> ChangeDescriptionRequest >> Lamdera.sendToBackend)
                    )
                    model.form.description
                , validate
                    (EmailAddress.fromString
                        >> Maybe.map (Untrusted.untrust >> ChangeEmailAddressRequest >> Lamdera.sendToBackend)
                    )
                    model.form.emailAddress
                ]
                    |> List.filterMap identity
                    |> Command.batch

              else
                Command.none
            )

        PressedProfileImage ->
            ( model, FileSelect.file [ "image/png", "image/jpg", "image/jpeg" ] SelectedImage )

        SelectedImage file ->
            ( model, File.toUrl file |> Task.perform GotImageUrl )

        PressedDeleteAccount ->
            ( { model | pressedDeleteAccount = True }, Lamdera.sendToBackend SendDeleteUserEmailRequest )

        GotImageUrl imageUrl ->
            ( { model
                | profileImage =
                    Editing (Just { x = 0.1, y = 0.1, size = 0.8, imageUrl = imageUrl, dragState = Nothing, imageSize = Nothing })
              }
            , Dom.getElement profileImagePlaceholderId |> Task.attempt GotImageSize
            )

        MouseDownImageEditor x y ->
            case model.profileImage of
                Editing (Just imageData) ->
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
                        | profileImage = Editing (Just { imageData | dragState = Just newDragState })
                      }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        MovedImageEditor x y ->
            case model.profileImage of
                Editing (Just imageData) ->
                    ( { model
                        | profileImage =
                            Editing (Just (updateDragState (pixelToT windowSize x) (pixelToT windowSize y) imageData))
                      }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        MouseUpImageEditor x y ->
            case model.profileImage of
                Editing (Just imageData) ->
                    let
                        newImageData =
                            updateDragState (pixelToT windowSize x) (pixelToT windowSize y) imageData
                                |> getActualImageState
                                |> (\a -> { a | dragState = Nothing })
                    in
                    ( { model | profileImage = Editing (Just newImageData) }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        TouchEndImageEditor ->
            case model.profileImage of
                Editing (Just imageData) ->
                    let
                        newImageData =
                            getActualImageState imageData
                                |> (\a -> { a | dragState = Nothing })
                    in
                    ( { model | profileImage = Editing (Just newImageData) }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        PressedConfirmImage ->
            case model.profileImage of
                Editing (Just imageData) ->
                    case imageData.imageSize of
                        Just ( w, _ ) ->
                            ( model
                            , Ports.cropImageToJs
                                { requestId = 0
                                , imageUrl = imageData.imageUrl
                                , cropX = imageData.x * toFloat w |> round |> Pixels.pixels
                                , cropY = imageData.y * toFloat w |> round |> Pixels.pixels
                                , cropWidth = ProfileImage.defaultSize
                                , cropHeight = ProfileImage.defaultSize
                                , width = toFloat w * imageData.size |> round |> Pixels.pixels
                                , height = toFloat w * imageData.size |> round |> Pixels.pixels
                                }
                            )

                        Nothing ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        PressedCancelImage ->
            ( { model | profileImage = Unchanged }, Command.none )

        GotImageSize result ->
            case ( result, model.profileImage ) of
                ( Ok { element }, Editing (Just imageData) ) ->
                    if element.height <= 0 then
                        ( model
                        , Dom.getElement profileImagePlaceholderId |> Task.attempt GotImageSize
                        )

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
                                    |> Editing
                          }
                        , Command.none
                        )

                _ ->
                    ( model, Command.none )

        CroppedImage result ->
            case result of
                Ok imageData ->
                    case ProfileImage.customImage imageData.croppedImageUrl of
                        Ok profileImage ->
                            let
                                newModel =
                                    { model | profileImage = Unchanged }
                            in
                            ( newModel
                            , Untrusted.untrust profileImage
                                |> ChangeProfileImageRequest
                                |> Lamdera.sendToBackend
                            )

                        Err _ ->
                            ( model, Command.none )

                Err _ ->
                    ( model, Command.none )


subscriptions : (Msg -> msg) -> Subscription FrontendOnly msg
subscriptions msgMap =
    Ports.cropImageFromJs (CroppedImage >> msgMap)


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


pixelToT : { a | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels } -> Float -> Float
pixelToT windowSize value =
    value / toFloat (imageEditorWidth windowSize)


tToPixel : { a | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels } -> Float -> Float
tToPixel windowSize value =
    value * toFloat (imageEditorWidth windowSize)


imageEditorWidth : { a | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels } -> Int
imageEditorWidth windowSize =
    min 400 (Pixels.inPixels windowSize.windowWidth)


profileImagePlaceholderId : HtmlId
profileImagePlaceholderId =
    Dom.id "profile-image-placeholder-id"


imageEditorIsActive : Model -> Bool
imageEditorIsActive model =
    case model.profileImage of
        Editing (Just _) ->
            True

        _ ->
            False


imageEditorView :
    UserConfig
    -> { a | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels }
    -> ImageEdit
    -> Element Msg
imageEditorView { theme, texts } windowSize imageEdit =
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
                    , Element.Background.color (Element.rgb 1 1 1)
                    , Element.Border.width 2
                    , Element.Border.color (Element.rgb 0 0 0)
                    , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                    ]
                    Element.none
                )

        drawHorizontalLine x_ y_ width =
            Element.inFront
                (Element.el
                    [ Element.width (Element.px (round (tToPixel windowSize width)))
                    , Element.height (Element.px 6)
                    , Element.moveRight (tToPixel windowSize x_)
                    , Element.moveDown (tToPixel windowSize y_ - 3)
                    , Element.Background.color (Element.rgb 1 1 1)
                    , Element.Border.width 2
                    , Element.Border.color (Element.rgb 0 0 0)
                    , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                    ]
                    Element.none
                )

        drawVerticalLine x_ y_ height =
            Element.inFront
                (Element.el
                    [ Element.height (Element.px (round (tToPixel windowSize height)))
                    , Element.width (Element.px 6)
                    , Element.moveRight (tToPixel windowSize x_ - 3)
                    , Element.moveDown (tToPixel windowSize y_)
                    , Element.Background.color (Element.rgb 1 1 1)
                    , Element.Border.width 2
                    , Element.Border.color (Element.rgb 0 0 0)
                    , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                    ]
                    Element.none
                )

        imageEditorWidth_ =
            imageEditorWidth windowSize
    in
    Element.column
        [ Element.spacing 8
        , Element.inFront
            (case imageEdit.imageSize of
                Just _ ->
                    Element.none

                Nothing ->
                    Element.el
                        [ Element.transparent True
                        , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                        ]
                        (Element.html
                            (Html.img
                                [ Dom.idToAttribute profileImagePlaceholderId
                                , Html.Attributes.src imageUrl
                                ]
                                []
                            )
                        )
            )
        , Element.centerX
        ]
        [ Element.image
            [ Element.width (Element.px imageEditorWidth_)
            , case imageEdit.imageSize of
                Just ( w, h ) ->
                    Element.height (Element.px (round (toFloat (imageEditorWidth_ * h) / toFloat w)))

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
                    [ Element.height (Element.px (round (size * toFloat imageEditorWidth_)))
                    , Element.width (Element.px (round (size * toFloat imageEditorWidth_)))
                    , Element.moveRight (x * toFloat imageEditorWidth_)
                    , Element.moveDown (y * toFloat imageEditorWidth_)
                    , Element.Border.width 2
                    , Element.Border.color (Element.rgb 0 0 0)
                    , Element.Border.rounded 99999
                    , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
                    ]
                    Element.none
                )
            , Element.inFront
                (Element.el
                    [ Element.height (Element.px (round (size * toFloat imageEditorWidth_ - 4)))
                    , Element.width (Element.px (round (size * toFloat imageEditorWidth_ - 4)))
                    , Element.moveRight (x * toFloat imageEditorWidth_ + 2)
                    , Element.moveDown (y * toFloat imageEditorWidth_ + 2)
                    , Element.Border.width 2
                    , Element.Border.color (Element.rgb 1 1 1)
                    , Element.Border.rounded 99999
                    , Element.htmlAttribute (Html.Attributes.style "pointer-events" "none")
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
            , description = texts.imageEditor
            }
        , Element.wrappedRow
            [ Element.width Element.fill, Element.spacingXY 16 8, Element.paddingXY 8 0 ]
            [ MyUi.submitButton theme uploadImageButtonId False { onPress = PressedConfirmImage, label = texts.uploadImage }
            , MyUi.button theme cancelImageButtonId { onPress = PressedCancelImage, label = texts.cancel }
            ]
        ]


uploadImageButtonId : HtmlId
uploadImageButtonId =
    HtmlId.buttonId "profileUploadImage"


cancelImageButtonId : HtmlId
cancelImageButtonId =
    HtmlId.buttonId "profileCancelImage"


view :
    UserConfig
    -> { b | windowWidth : Quantity Int Pixels, windowHeight : Quantity Int Pixels }
    -> CurrentValues
    -> Model
    -> Element Msg
view ({ theme, texts } as userConfig) windowSize currentValues ({ form } as model) =
    case model.profileImage of
        Editing (Just imageEdit) ->
            imageEditorView userConfig windowSize imageEdit

        _ ->
            Element.column
                MyUi.pageContentAttributes
                [ Element.wrappedRow [ Element.width Element.fill ]
                    [ Element.el [ Element.alignTop ] (MyUi.title texts.profile)
                    , Element.Input.button
                        [ Element.alignRight
                        , Element.Border.rounded 9999
                        , Element.clip
                        , Element.Background.color theme.grey
                        ]
                        { onPress = Just PressedProfileImage
                        , label = ProfileImage.image userConfig ProfileImage.defaultSize currentValues.profileImage
                        }
                    ]
                , MyUi.columnCard
                    theme
                    [ editableTextInput
                        nameTextInputId
                        userConfig
                        (\a -> FormChanged { form | name = a })
                        Name.toString
                        (\a ->
                            case Name.fromString a of
                                Ok name ->
                                    Ok name

                                Err Name.NameTooShort ->
                                    Err texts.yourNameCantBeEmpty

                                Err Name.NameTooLong ->
                                    Err (texts.keepItBelowNCharacters (Name.maxLength + 1))
                        )
                        currentValues.name
                        form.name
                        texts.yourName
                    , editableMultiline
                        descriptionTextInputId
                        userConfig
                        (\a -> FormChanged { form | description = a })
                        Description.toString
                        (\a ->
                            case Description.fromString a of
                                Ok name ->
                                    Ok name

                                Err DescriptionTooLong ->
                                    Err (texts.belowNCharactersPlease Description.maxLength)
                        )
                        currentValues.description
                        form.description
                        texts.whatDoYouWantPeopleToKnowAboutYou
                    , editableEmailInput
                        userConfig
                        (always (FormChanged form))
                        -- For now, changing email address is not supported
                        --(\a -> FormChanged { form | emailAddress = a })
                        EmailAddress.toString
                        (EmailAddress.fromString >> Result.fromMaybe texts.invalidEmailAddress)
                        currentValues.emailAddress
                        form.emailAddress
                        texts.yourEmailAddress
                    ]
                , MyUi.dangerButton theme deleteAccountButtonId False { onPress = PressedDeleteAccount, label = texts.deleteAccount }
                , if model.pressedDeleteAccount then
                    Element.column
                        [ Element.spacing 20 ]
                        [ Element.paragraph []
                            [ Element.text texts.anAccountDeletionEmailHasBeenSentTo
                            , MyUi.emailAddressText currentValues.emailAddress
                            , Element.text texts.pressTheLinkInItToConfirmDeletingYourAccount
                            ]
                        , Element.paragraph [] [ Element.text texts.ifYouDontSeeTheEmailCheckYourSpamFolder ]
                        ]

                  else
                    Element.none
                ]


nameTextInputId : HtmlId
nameTextInputId =
    HtmlId.textInputId "profilePage_name"


descriptionTextInputId : HtmlId
descriptionTextInputId =
    HtmlId.textInputId "profilePage_description"


deleteAccountButtonId : HtmlId
deleteAccountButtonId =
    HtmlId.buttonId "profileDeleteAccount"


editableTextInput :
    HtmlId
    -> UserConfig
    -> (Editable String -> msg)
    -> (a -> String)
    -> (String -> Result String a)
    -> a
    -> Editable String
    -> String
    -> Element msg
editableTextInput htmlId { theme, texts } onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editing edit ->
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
            [ Dom.idToAttribute htmlId |> Element.htmlAttribute
            , Element.width Element.fill
            , Element.Border.rounded 4
            , MyUi.inputBorder theme (maybeError /= Nothing)
            , MyUi.inputBorderWidth (maybeError /= Nothing)
            , Element.Background.color theme.background
            ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editing value ->
                        value
            , onChange = Editing >> onChange
            , placeholder = Nothing
            , label = MyUi.formLabelAbove theme labelText
            }
        , case maybeError of
            Just error ->
                MyUi.error theme error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    savingText texts
        ]


editableEmailInput :
    UserConfig
    -> (Editable String -> msg)
    -> (a -> String)
    -> (String -> Result String a)
    -> a
    -> Editable String
    -> String
    -> Element msg
editableEmailInput { theme, texts } onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editing edit ->
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
        , MyUi.inputBackground theme (maybeError /= Nothing)
        , Element.Border.rounded 4
        ]
        [ Element.Input.email
            [ Element.width Element.fill
            , Element.Background.color theme.background
            , Element.Border.color theme.darkGrey
            ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editing value ->
                        value
            , onChange = Editing >> onChange
            , placeholder = Nothing
            , label = MyUi.formLabelAbove theme labelText
            }
        , case maybeError of
            Just error ->
                MyUi.error theme error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    savingText texts
        ]


editableMultiline : HtmlId -> UserConfig -> (Editable String -> msg) -> (a -> String) -> (String -> Result String a) -> a -> Editable String -> String -> Element msg
editableMultiline htmlId { theme, texts } onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editing edit ->
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
            [ Dom.idToAttribute htmlId |> Element.htmlAttribute
            , Element.width Element.fill
            , Element.height (Element.px 200)
            , MyUi.inputBorder theme (maybeError /= Nothing)
            , MyUi.inputBorderWidth (maybeError /= Nothing)
            , Element.Background.color theme.background
            ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editing value ->
                        value
            , onChange = Editing >> onChange
            , placeholder = Nothing
            , label = MyUi.formLabelAbove theme labelText
            , spellcheck = True
            }
        , case maybeError of
            Just error ->
                MyUi.error theme error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    savingText texts
        ]


savingText : Texts -> Element msg
savingText texts =
    Element.el
        [ Element.paddingEach { left = 0, right = 0, top = 10, bottom = 0 }
        , Element.Font.size 12
        ]
        (Element.text texts.saving)
