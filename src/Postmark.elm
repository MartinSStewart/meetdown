module Postmark exposing (..)

import Html.String
import Html.String.Attributes as Html
import Http
import Json.Decode as D
import Json.Decode.Pipeline exposing (..)
import Json.Encode as E
import Task exposing (Task)


endpoint =
    "https://api.postmarkapp.com"


type alias PostmarkServerToken =
    String


type PostmarkEmailBody a
    = EmailHtml (Html.String.Html a)
    | EmailText String
    | EmailBoth (Html.String.Html a) String



-- Plain send


type alias PostmarkSend a =
    { token : String
    , from : String
    , to : String
    , subject : String
    , body : PostmarkEmailBody a
    , messageStream : String
    }


sendEmail : PostmarkSend a -> Task Http.Error PostmarkSendResponse
sendEmail d =
    let
        httpBody =
            Http.jsonBody <|
                E.object <|
                    [ ( "From", E.string d.from )
                    , ( "To", E.string d.to )
                    , ( "Subject", E.string d.subject )
                    , ( "MessageStream", E.string d.messageStream )
                    ]
                        ++ bodyToJsonValues d.body
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "X-Postmark-Server-Token" d.token ]
        , url = endpoint ++ "/email"
        , body = httpBody
        , resolver = jsonResolver decodePostmarkSendResponse
        , timeout = Nothing
        }


type alias PostmarkSendResponse =
    { to : String
    , submittedAt : String
    , messageID : String
    , errorCode : String
    , message : String
    }


decodePostmarkSendResponse =
    D.succeed PostmarkSendResponse
        |> required "To" D.string
        |> required "SubmittedAt" D.string
        |> required "MessageID" D.string
        |> required "ErrorCode" D.string
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


sendTemplateEmail : PostmarkTemplateSend -> Task Http.Error PostmarkTemplateSendResponse
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


bodyToJsonValues : PostmarkEmailBody a -> List ( String, E.Value )
bodyToJsonValues body =
    case body of
        EmailHtml html ->
            [ ( "HtmlBody", E.string <| Html.String.toString 0 html ) ]

        EmailText text ->
            [ ( "TextBody", E.string text ) ]

        EmailBoth html text ->
            [ ( "HtmlBody", E.string <| Html.String.toString 0 html )
            , ( "TextBody", E.string text )
            ]


jsonResolver : D.Decoder a -> Http.Resolver Http.Error a
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
