module Internal exposing (Attribute(..), Html(..), ImageType(..), cid, imageExtension, inlineImageName, mimeType, toHtml, toString)

import Base64
import Bytes exposing (Bytes)
import Html
import Html.Attributes


type Html
    = Node String (List Attribute) (List Html)
    | InlineImage { content : Bytes, imageType : ImageType } (List Attribute) (List Html)
    | TextNode String


type Attribute
    = StyleAttribute String String
    | Attribute String String


toHtml : Html -> Html.Html msg
toHtml html =
    case html of
        Node tagName attributes children ->
            Html.node tagName (List.map toHtmlAttribute attributes) (List.map toHtml children)

        InlineImage { content, imageType } attributes children ->
            Html.img
                (Html.Attributes.src
                    ("data:" ++ mimeType imageType ++ ";base64," ++ Maybe.withDefault "" (Base64.fromBytes content))
                    :: List.map toHtmlAttribute attributes
                )
                (List.map toHtml children)

        TextNode text ->
            Html.text text


toHtmlAttribute : Attribute -> Html.Attribute msg
toHtmlAttribute attribute =
    case attribute of
        StyleAttribute property value ->
            Html.Attributes.style property value

        Attribute property value ->
            Html.Attributes.attribute property value


type alias Acc =
    { depth : Int
    , stack : List ( String, List Html )
    , result : List String
    , inlineImages : List ( String, { content : Bytes, imageType : ImageType } )
    }


toString : Html -> ( String, List ( String, { content : Bytes, imageType : ImageType } ) )
toString html =
    let
        initialAcc : Acc
        initialAcc =
            { depth = 0
            , stack = []
            , result = []
            , inlineImages = []
            }

        { result, inlineImages } =
            toStringHelper [ html ] initialAcc
    in
    ( result |> List.reverse |> String.concat, inlineImages )


toStringHelper : List Html -> Acc -> Acc
toStringHelper tags acc =
    case tags of
        [] ->
            case acc.stack of
                [] ->
                    acc

                ( tagName, cont ) :: rest ->
                    toStringHelper
                        cont
                        { acc
                            | result = closingTag tagName :: acc.result
                            , depth = acc.depth - 1
                            , stack = rest
                        }

        (Node tagName attributes children) :: rest ->
            case children of
                [] ->
                    toStringHelper
                        rest
                        { acc | result = tag tagName attributes :: acc.result }

                childNodes ->
                    toStringHelper
                        childNodes
                        { acc
                            | result = tag tagName attributes :: acc.result
                            , depth = acc.depth + 1
                            , stack = ( tagName, rest ) :: acc.stack
                        }

        (InlineImage { imageType, content } attributes children) :: rest ->
            let
                src =
                    inlineImageName (List.length acc.inlineImages) imageType

                inlineImages =
                    ( src, { content = content, imageType = imageType } ) :: acc.inlineImages
            in
            case children of
                [] ->
                    toStringHelper
                        rest
                        { acc
                            | result = tag "img" (Attribute "src" (cid src) :: attributes) :: acc.result
                            , inlineImages = inlineImages
                        }

                childNodes ->
                    toStringHelper
                        childNodes
                        { acc
                            | result = tag "img" (Attribute "src" (cid src) :: attributes) :: acc.result
                            , depth = acc.depth + 1
                            , stack = ( "img", rest ) :: acc.stack
                            , inlineImages = inlineImages
                        }

        (TextNode string) :: rest ->
            toStringHelper
                rest
                { acc | result = escapeHtmlText string :: acc.result }


type ImageType
    = Jpeg
    | Png
    | Gif


imageExtension : ImageType -> String
imageExtension imageType =
    case imageType of
        Jpeg ->
            "jpeg"

        Png ->
            "png"

        Gif ->
            "gif"


mimeType : ImageType -> String
mimeType imageType =
    "image/" ++ imageExtension imageType


inlineImageName : Int -> ImageType -> String
inlineImageName count imageType =
    "inline-image" ++ String.fromInt count ++ "." ++ imageExtension imageType


cid : String -> String
cid filename =
    "cid:" ++ filename


tag : String -> List Attribute -> String
tag tagName attributes =
    "<" ++ String.join " " (tagName :: attributesToString attributes) ++ ">"


escapeHtmlText : String -> String
escapeHtmlText =
    String.replace "&" "&amp;"
        >> String.replace "<" "&lt;"
        >> String.replace ">" "&gt;"


attributesToString : List Attribute -> List String
attributesToString attrs =
    let
        ( classes, styles, regular ) =
            List.foldl addAttribute ( [], [], [] ) attrs
    in
    regular
        |> withClasses classes
        |> withStyles styles


withClasses : List String -> List String -> List String
withClasses classes attrs =
    case classes of
        [] ->
            attrs

        _ ->
            buildProp "class" (String.join " " classes) :: attrs


withStyles : List String -> List String -> List String
withStyles styles attrs =
    case styles of
        [] ->
            attrs

        _ ->
            buildProp "style" (String.join "; " styles) :: attrs


type alias AttrAcc =
    ( List String, List String, List String )


buildProp : String -> String -> String
buildProp key value =
    hyphenate key ++ "=\"" ++ escape value ++ "\""


addAttribute : Attribute -> AttrAcc -> AttrAcc
addAttribute attribute ( classes, styles, attrs ) =
    case attribute of
        Attribute key value ->
            ( classes, styles, buildProp key value :: attrs )

        StyleAttribute key value ->
            ( classes
            , (escape key ++ ": " ++ escape value) :: styles
            , attrs
            )


escape : String -> String
escape =
    String.foldl
        (\char acc ->
            if char == '"' then
                acc ++ "\\\""

            else
                acc ++ String.fromChar char
        )
        ""


hyphenate : String -> String
hyphenate =
    String.foldl
        (\char acc ->
            if Char.isUpper char then
                acc ++ "-" ++ String.fromChar (Char.toLower char)

            else
                acc ++ String.fromChar char
        )
        ""


closingTag : String -> String
closingTag tagName =
    "</" ++ tagName ++ ">"


indent : Int -> Int -> String -> String
indent perLevel level x =
    String.repeat (perLevel * level) " " ++ x
