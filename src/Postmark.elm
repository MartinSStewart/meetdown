module Postmark exposing (..)

import Base64
import Bytes exposing (Bytes)
import Dict exposing (Dict)
import Effect.Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Task as Task exposing (Task)
import Email.Html
import EmailAddress exposing (EmailAddress)
import Json.Decode as D
import Json.Decode.Pipeline exposing (..)
import Json.Encode as E
import List.Nonempty
import String.Nonempty exposing (NonemptyString)


endpoint =
    "https://api.postmarkapp.com"


type alias PostmarkServerToken =
    String


type PostmarkEmailBody
    = BodyHtml Email.Html.Html
    | BodyText String
    | BodyBoth Email.Html.Html String



-- Plain send


type alias PostmarkSend =
    { from : { name : String, email : EmailAddress }
    , to : List.Nonempty.Nonempty { name : String, email : EmailAddress }
    , subject : NonemptyString
    , body : PostmarkEmailBody
    , messageStream : String
    , attachments : Dict String { content : String, mimeType : String }
    }


attachmentEncoder : ( String, { content : String, mimeType : String } ) -> E.Value
attachmentEncoder ( name, data ) =
    E.object
        [ ( "Name", E.string name )
        , ( "Content", E.string data.content )
        , ( "ContentType", E.string data.mimeType )
        ]


sendEmailTask : PostmarkServerToken -> PostmarkSend -> Task restriction Http.Error PostmarkSendResponse
sendEmailTask token d =
    let
        httpBody : Http.Body
        httpBody =
            [ ( "From", E.string (emailToString d.from) )
            , ( "To", E.string (emailsToString d.to) )
            , ( "Subject", E.string (String.Nonempty.toString d.subject) )
            , ( "MessageStream", E.string d.messageStream )
            , ( "Attachments", E.list attachmentEncoder (Dict.toList d.attachments) )
            ]
                ++ bodyToJsonValues d.body
                |> E.object
                |> Http.jsonBody
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "X-Postmark-Server-Token" token ]
        , url = endpoint ++ "/email"
        , body = httpBody
        , resolver = jsonResolver decodePostmarkSendResponse
        , timeout = Nothing
        }


sendEmail :
    (Result Http.Error PostmarkSendResponse -> msg)
    -> PostmarkServerToken
    -> PostmarkSend
    -> Command restriction toMsg msg
sendEmail msg token d =
    sendEmailTask token d |> Task.attempt msg


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
addAttachments : Dict String { content : Bytes, mimeType : String } -> PostmarkSend -> PostmarkSend
addAttachments attachments email =
    { email
        | attachments =
            Dict.union
                (Dict.map
                    (\_ attachment ->
                        { content = Base64.fromBytes attachment.content |> Maybe.withDefault ""
                        , mimeType = attachment.mimeType
                        }
                    )
                    attachments
                )
                email.attachments
    }


emailsToString : List.Nonempty.Nonempty { name : String, email : EmailAddress } -> String
emailsToString nonEmptyEmails =
    nonEmptyEmails
        |> List.Nonempty.toList
        |> List.map emailToString
        |> String.join ", "


emailToString : { name : String, email : EmailAddress } -> String
emailToString address =
    if address.name == "" then
        EmailAddress.toString address.email

    else
        address.name ++ " <" ++ EmailAddress.toString address.email ++ ">"


type alias PostmarkSendResponse =
    { to : String
    , submittedAt : String
    , messageID : String
    , errorCode : Int
    , message : String
    }


decodePostmarkSendResponse =
    D.succeed PostmarkSendResponse
        |> required "To" D.string
        |> required "SubmittedAt" D.string
        |> required "MessageID" D.string
        |> required "ErrorCode" D.int
        |> required "Message" D.string



-- Template send


type alias PostmarkTemplateSend =
    { token : String
    , templateAlias : String
    , templateModel : E.Value
    , from : String
    , to : String
    , messageStream : String
    }


sendTemplateEmail : PostmarkTemplateSend -> Task BackendOnly Http.Error PostmarkTemplateSendResponse
sendTemplateEmail d =
    let
        httpBody =
            Http.jsonBody <|
                E.object <|
                    [ ( "From", E.string d.from )
                    , ( "To", E.string d.to )
                    , ( "MessageStream", E.string d.messageStream )
                    , ( "TemplateAlias", E.string d.templateAlias )
                    , ( "TemplateModel", d.templateModel )
                    ]
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "X-Postmark-Server-Token" d.token ]
        , url = endpoint ++ "/email/withTemplate"
        , body = httpBody
        , resolver = jsonResolver decodePostmarkTemplateSendResponse
        , timeout = Nothing
        }


type alias PostmarkTemplateSendResponse =
    { to : String
    , submittedAt : String
    , messageID : String
    , errorCode : String
    , message : String
    }


decodePostmarkTemplateSendResponse =
    D.succeed PostmarkTemplateSendResponse
        |> required "To" D.string
        |> required "SubmittedAt" D.string
        |> required "MessageID" D.string
        |> required "ErrorCode" D.string
        |> required "Message" D.string



-- Helpers


bodyToJsonValues : PostmarkEmailBody -> List ( String, E.Value )
bodyToJsonValues body =
    case body of
        BodyHtml html ->
            [ ( "HtmlBody", E.string <| Tuple.first <| Email.Html.toString html ) ]

        BodyText text ->
            [ ( "TextBody", E.string text ) ]

        BodyBoth html text ->
            [ ( "HtmlBody", E.string <| Tuple.first <| Email.Html.toString html )
            , ( "TextBody", E.string text )
            ]


jsonResolver : D.Decoder a -> Http.Resolver restriction Http.Error a
jsonResolver decoder =
    Http.stringResolver <|
        \response ->
            case response of
                Http.GoodStatus_ _ body ->
                    D.decodeString decoder body
                        |> Result.mapError D.errorToString
                        |> Result.mapError Http.BadBody

                Http.BadUrl_ message ->
                    Err (Http.BadUrl message)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err (Http.BadStatus metadata.statusCode)
