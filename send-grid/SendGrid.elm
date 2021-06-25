module SendGrid exposing (ApiKey, apiKey, textEmail, htmlEmail, addCc, addBcc, addAttachments, sendEmail, sendEmailTask, Email, Error(..), ErrorMessage, ErrorMessage403)

{-|

@docs ApiKey, apiKey, textEmail, htmlEmail, addCc, addBcc, addAttachments, sendEmail, sendEmailTask, Email, Error, ErrorMessage, ErrorMessage403

-}

import Base64
import Bytes exposing (Bytes)
import Dict exposing (Dict)
import Email.Html
import EmailAddress exposing (EmailAddress)
import Http
import Internal
import Json.Decode as JD
import Json.Encode as JE
import List.Nonempty exposing (Nonempty)
import String.Nonempty exposing (NonemptyString)
import Task exposing (Task)


type Content
    = TextContent NonemptyString
    | HtmlContent String


type Disposition
    = AttachmentDisposition
    | Inline


encodeContent : Content -> JE.Value
encodeContent content =
    case content of
        TextContent text ->
            JE.object [ ( "type", JE.string "text/plain" ), ( "value", encodeNonemptyString text ) ]

        HtmlContent html ->
            JE.object [ ( "type", JE.string "text/html" ), ( "value", html |> JE.string ) ]


encodeEmailAddress : EmailAddress -> JE.Value
encodeEmailAddress =
    EmailAddress.toString >> JE.string


encodeEmailAndName : { name : String, email : EmailAddress } -> JE.Value
encodeEmailAndName emailAndName =
    JE.object [ ( "email", encodeEmailAddress emailAndName.email ), ( "name", JE.string emailAndName.name ) ]


encodePersonalization : ( Nonempty EmailAddress, List EmailAddress, List EmailAddress ) -> JE.Value
encodePersonalization ( to, cc, bcc ) =
    let
        addName =
            List.map (\address -> { email = address, name = "" })

        ccJson =
            if List.isEmpty cc then
                []

            else
                [ ( "cc", addName cc |> JE.list encodeEmailAndName ) ]

        bccJson =
            if List.isEmpty bcc then
                []

            else
                [ ( "bcc", addName bcc |> JE.list encodeEmailAndName ) ]

        toJson =
            ( "to"
            , to
                |> List.Nonempty.map (\address -> { email = address, name = "" })
                |> encodeNonemptyList encodeEmailAndName
            )
    in
    JE.object (toJson :: ccJson ++ bccJson)


encodeNonemptyList : (a -> JE.Value) -> Nonempty a -> JE.Value
encodeNonemptyList encoder list =
    List.Nonempty.toList list |> JE.list encoder


{-| Create an email that contains html.

    import Email
    import Email.Html
    import List.Nonempty
    import String.Nonempty exposing (NonemptyString)

    {-| An email to be sent to a recipient's email address.
    -}
    email : Email.Email -> SendGrid.Email
    email recipient =
        SendGrid.htmlEmail
            { subject = NonemptyString 'S' "ubject"
            , to = List.Nonempty.fromElement recipient
            , content =
                Email.Html.div
                    []
                    [ Email.Html.text "Hi!" ]
            , nameOfSender = "test name"
            , emailAddressOfSender =
                -- this-can-be-anything@test.com
                { localPart = "this-can-be-anything"
                , tags = []
                , domain = "test"
                , tld = [ "com" ]
                }
            }

Note that email clients are quite limited in what html features are supported!
To avoid accidentally using html that's unsupported by some email clients, the `Email.Html` and `Email.Html.Attributes` modules only define tags and attributes with universal support.
You can still use `Email.Html.node` and `Email.Html.Attributes.attribute` if you want something that might not be universally supported though.

-}
htmlEmail :
    { subject : NonemptyString
    , content : Email.Html.Html
    , to : Nonempty EmailAddress
    , nameOfSender : String
    , emailAddressOfSender : EmailAddress
    }
    -> Email
htmlEmail config =
    let
        ( html, inlineImages ) =
            Internal.toString config.content
    in
    Email
        { subject = config.subject
        , content = HtmlContent html
        , to = config.to
        , cc = []
        , bcc = []
        , nameOfSender = config.nameOfSender
        , emailAddressOfSender = config.emailAddressOfSender
        , attachments =
            inlineImages
                |> List.map
                    (Tuple.mapSecond
                        (\{ imageType, content } ->
                            { mimeType = Internal.mimeType imageType, content = content, disposition = Inline }
                        )
                    )
                |> Dict.fromList
        }


{-| Create an email that only contains plain text.

    import Email
    import List.Nonempty
    import String.Nonempty exposing (NonemptyString)

    {-| An email to be sent to a recipient's email address.
    -}
    email : Email.Email -> SendGrid.Email
    email recipient =
        SendGrid.textEmail
            { subject = NonemptyString 'S' "ubject"
            , to = List.Nonempty.fromElement recipient
            , content = NonemptyString 'H' "i!"
            , nameOfSender = "test name"
            , emailAddressOfSender =
                -- this-can-be-anything@test.com
                { localPart = "this-can-be-anything"
                , tags = []
                , domain = "test"
                , tld = [ "com" ]
                }
            }

-}
textEmail :
    { subject : NonemptyString
    , content : NonemptyString
    , to : Nonempty EmailAddress
    , nameOfSender : String
    , emailAddressOfSender : EmailAddress
    }
    -> Email
textEmail config =
    Email
        { subject = config.subject
        , content = TextContent config.content
        , to = config.to
        , cc = []
        , bcc = []
        , nameOfSender = config.nameOfSender
        , emailAddressOfSender = config.emailAddressOfSender
        , attachments = Dict.empty
        }


{-| Add a list of [CC](https://en.wikipedia.org/wiki/Carbon_copy) recipients.
-}
addCc : List EmailAddress -> Email -> Email
addCc cc (Email email_) =
    Email { email_ | cc = email_.cc ++ cc }


{-| Add a list of [BCC](https://en.wikipedia.org/wiki/Blind_carbon_copy) recipients.
-}
addBcc : List EmailAddress -> Email -> Email
addBcc bcc (Email email_) =
    Email { email_ | bcc = email_.bcc ++ bcc }


{-| Attach files to the email. These will usually appear at the bottom of the email.

    import Bytes exposing (Bytes)
    import SendGrid

    attachPngImage : String -> Bytes -> Email -> Email
    attachPngImage name image email =
        SendGrid.addAttachments
            (Dict.fromList
                [ ( name ++ ".png"
                  , { content = image
                    , mimeType = "image/png"
                    }
                  )
                ]
            )
            email

If you want to include an image file within the body of your email, use `Email.Html.inlinePngImg`, `Email.Html.inlineJpegImg`, or `Email.Html.inlineGifImg` instead.

-}
addAttachments : Dict String { content : Bytes, mimeType : String } -> Email -> Email
addAttachments attachments (Email email_) =
    Email
        { email_
            | attachments =
                Dict.union
                    (Dict.map
                        (\_ value -> { content = value.content, mimeType = value.mimeType, disposition = AttachmentDisposition })
                        attachments
                    )
                    email_.attachments
        }


{-| -}
type Email
    = Email
        { subject : NonemptyString
        , content : Content
        , to : Nonempty EmailAddress
        , cc : List EmailAddress
        , bcc : List EmailAddress
        , nameOfSender : String
        , emailAddressOfSender : EmailAddress
        , attachments : Dict String Attachment
        }


type alias Attachment =
    { content : Bytes
    , mimeType : String
    , disposition : Disposition
    }


encodeDisposition : Disposition -> JE.Value
encodeDisposition disposition =
    case disposition of
        AttachmentDisposition ->
            JE.string "attachment"

        Inline ->
            JE.string "inline"


encodeAttachment : ( String, Attachment ) -> JE.Value
encodeAttachment ( filename, attachment ) =
    JE.object
        (( "content", Base64.fromBytes attachment.content |> Maybe.withDefault "" |> JE.string )
            :: ( "mimeType", JE.string attachment.mimeType )
            :: ( "filename", JE.string filename )
            :: ( "disposition", encodeDisposition attachment.disposition )
            :: (case attachment.disposition of
                    AttachmentDisposition ->
                        []

                    Inline ->
                        [ ( "content_id", JE.string filename ) ]
               )
        )


encodeNonemptyString : NonemptyString -> JE.Value
encodeNonemptyString nonemptyString =
    String.Nonempty.toString nonemptyString |> JE.string


encodeSendEmail : Email -> JE.Value
encodeSendEmail (Email { content, subject, nameOfSender, emailAddressOfSender, to, cc, bcc, attachments }) =
    let
        attachmentsList =
            Dict.toList attachments
    in
    JE.object
        (( "subject", encodeNonemptyString subject )
            :: ( "content", JE.list encodeContent [ content ] )
            :: ( "personalizations", JE.list encodePersonalization [ ( to, cc, bcc ) ] )
            :: ( "from", encodeEmailAndName { name = nameOfSender, email = emailAddressOfSender } )
            :: (case attachmentsList of
                    _ :: _ ->
                        [ ( "attachments", JE.list encodeAttachment attachmentsList ) ]

                    [] ->
                        []
               )
        )


{-| A SendGrid API key. In order to send an email you must have one of these (see the readme for how to get one).
-}
type ApiKey
    = ApiKey String


{-| Create an API key from a raw string (see the readme for how to get one).
-}
apiKey : String -> ApiKey
apiKey apiKey_ =
    ApiKey apiKey_


{-| Send an email using the SendGrid API.
-}
sendEmail : (Result Error () -> msg) -> ApiKey -> Email -> Cmd msg
sendEmail msg (ApiKey apiKey_) email_ =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ apiKey_) ]
        , url = sendGridApiUrl
        , body = encodeSendEmail email_ |> Http.jsonBody
        , expect =
            Http.expectStringResponse msg
                (\response ->
                    case response of
                        Http.BadUrl_ url ->
                            BadUrl url |> Err

                        Http.Timeout_ ->
                            Err Timeout

                        Http.NetworkError_ ->
                            Err NetworkError

                        Http.BadStatus_ metadata body ->
                            decodeBadStatus metadata body |> Err

                        Http.GoodStatus_ _ _ ->
                            Ok ()
                )
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Send an email using the SendGrid API. This is the task version of [sendEmail](#sendEmail).
-}
sendEmailTask : ApiKey -> Email -> Task Error ()
sendEmailTask (ApiKey apiKey_) email_ =
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ apiKey_) ]
        , url = sendGridApiUrl
        , body = encodeSendEmail email_ |> Http.jsonBody
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.BadUrl_ url ->
                            BadUrl url |> Err

                        Http.Timeout_ ->
                            Err Timeout

                        Http.NetworkError_ ->
                            Err NetworkError

                        Http.BadStatus_ metadata body ->
                            decodeBadStatus metadata body |> Err

                        Http.GoodStatus_ _ _ ->
                            Ok ()
                )
        , timeout = Nothing
        }


sendGridApiUrl =
    "https://api.sendgrid.com/v3/mail/send"


decodeBadStatus : Http.Metadata -> String -> Error
decodeBadStatus metadata body =
    let
        toErrorCode : (a -> Error) -> Result e a -> Error
        toErrorCode errorCode result =
            case result of
                Ok value ->
                    errorCode value

                Err _ ->
                    UnknownError { statusCode = metadata.statusCode, body = body }
    in
    case metadata.statusCode of
        400 ->
            JD.decodeString codecErrorResponse body |> toErrorCode StatusCode400

        401 ->
            JD.decodeString codecErrorResponse body |> toErrorCode StatusCode401

        403 ->
            JD.decodeString codec403ErrorResponse body |> toErrorCode StatusCode403

        413 ->
            JD.decodeString codecErrorResponse body |> toErrorCode StatusCode413

        _ ->
            UnknownError { statusCode = metadata.statusCode, body = body }


{-| Possible error codes we might get back when trying to send an email.
Some are just normal HTTP errors and others are specific to the SendGrid API.
-}
type Error
    = StatusCode400 (List ErrorMessage)
    | StatusCode401 (List ErrorMessage)
    | StatusCode403 { errors : List ErrorMessage403, id : Maybe String }
    | StatusCode413 (List ErrorMessage)
    | UnknownError { statusCode : Int, body : String }
    | NetworkError
    | Timeout
    | BadUrl String


{-| The content of a generic SendGrid error.
-}
type alias ErrorMessage =
    { field : Maybe String
    , message : String
    , errorId : Maybe String
    }


codecErrorResponse : JD.Decoder (List ErrorMessage)
codecErrorResponse =
    JD.field "errors" (JD.list codecErrorMessage)


{-| The content of a 403 status code error.
-}
type alias ErrorMessage403 =
    { message : Maybe String
    , field : Maybe String
    , help : Maybe String
    }


codec403Error : JD.Decoder ErrorMessage403
codec403Error =
    JD.map3 ErrorMessage403
        (optionalField "message" JD.string)
        (optionalField "field" JD.string)
        (optionalField "help" (JD.value |> JD.map (JE.encode 0)))


codec403ErrorResponse : JD.Decoder { errors : List ErrorMessage403, id : Maybe String }
codec403ErrorResponse =
    JD.map2 (\errors id -> { errors = errors |> Maybe.withDefault [], id = id })
        (optionalField "errors" (JD.list codec403Error))
        (optionalField "id" JD.string)


codecErrorMessage : JD.Decoder ErrorMessage
codecErrorMessage =
    JD.map3 ErrorMessage
        (optionalField "field" JD.string)
        (JD.field "message" JD.string)
        (optionalField "error_id" JD.string)


{-| Borrowed from elm-community/json-extra
-}
optionalField : String -> JD.Decoder a -> JD.Decoder (Maybe a)
optionalField fieldName decoder =
    let
        finishDecoding json =
            case JD.decodeValue (JD.field fieldName JD.value) json of
                Ok val ->
                    -- The field is present, so run the decoder on it.
                    JD.map Just (JD.field fieldName decoder)

                Err _ ->
                    -- The field was missing, which is fine!
                    JD.succeed Nothing
    in
    JD.value
        |> JD.andThen finishDecoding
