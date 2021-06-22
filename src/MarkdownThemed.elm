module MarkdownThemed exposing (..)

import Colors exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Html exposing (Html)
import Html.Attributes
import Markdown.Block exposing (..)
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer


render : String -> Element msg
render markdownBody =
    Markdown.Parser.parse markdownBody
        -- @TODO show markdown parsing errors, i.e. malformed html?
        |> Result.withDefault []
        |> (\parsed ->
                parsed
                    |> Markdown.Renderer.render renderer
                    |> (\res ->
                            case res of
                                Ok elements ->
                                    elements

                                Err err ->
                                    [ text "Oops! Something went wrong rendering this page: ", text err ]
                       )
                    |> column
                        [ width fill
                        , spacing 20
                        ]
           )


renderer : Markdown.Renderer.Renderer (Element msg)
renderer =
    { heading = \data -> row [] [ heading data ]
    , paragraph = \children -> paragraph [ paddingXY 0 10 ] children
    , blockQuote =
        \children ->
            column
                [ Font.size 20
                , Font.italic
                , Border.widthEach { bottom = 0, left = 4, right = 0, top = 0 }
                , Border.color grey
                , Font.color readingMuted
                , padding 10
                ]
                children
    , html = Markdown.Html.oneOf []
    , text = \s -> el [] <| text s
    , codeSpan =
        \content -> fromHtml <| Html.code [] [ Html.text content ]
    , strong = \list -> paragraph [ Font.bold ] list
    , emphasis = \list -> paragraph [ Font.italic ] list
    , hardLineBreak = fromHtml <| Html.br [] []
    , link =
        \{ title, destination } list ->
            link [ Font.underline, Font.color readingMuted ]
                { url = destination
                , label =
                    case title of
                        Just title_ ->
                            text title_

                        Nothing ->
                            paragraph [] list
                }
    , image =
        \{ alt, src, title } ->
            let
                attrs =
                    [ title |> Maybe.map (\title_ -> htmlAttribute <| Html.Attributes.attribute "title" title_) ]
                        |> justs
            in
            image
                attrs
                { src = src
                , description = alt
                }
    , unorderedList =
        \items ->
            column [ spacing 15, width fill ]
                (items
                    |> List.map
                        (\listItem ->
                            case listItem of
                                ListItem task children ->
                                    wrappedRow
                                        [ spacing 5
                                        , paddingEach { top = 0, right = 0, bottom = 0, left = 20 }
                                        , width fill
                                        ]
                                        [ paragraph
                                            [ alignTop ]
                                            (text " • " :: children)
                                        ]
                        )
                )
    , orderedList =
        \startingIndex items ->
            column [ spacing 15, width fill ]
                (items
                    |> List.indexedMap
                        (\index itemBlocks ->
                            wrappedRow
                                [ spacing 5
                                , paddingEach { top = 0, right = 0, bottom = 0, left = 20 }
                                , width fill
                                ]
                                [ paragraph
                                    [ alignTop ]
                                    (text (String.fromInt (startingIndex + index) ++ ". ") :: itemBlocks)
                                ]
                        )
                )
    , codeBlock =
        \{ body, language } ->
            column
                [ Font.family [ Font.monospace ]
                , Background.color grey
                , Border.rounded 5
                , padding 10
                , width fill
                ]
                [ paragraph [] [ text body ] ]
    , thematicBreak = none
    , table = \children -> column [ width fill ] children
    , tableHeader = \children -> column [] children
    , tableBody = \children -> column [] children
    , tableRow = \children -> row [ width fill ] children
    , tableCell = \alignment children -> column [ width fill ] children
    , tableHeaderCell = \alignmentM children -> column [ width fill ] children
    , strikethrough = \children -> paragraph [ Font.strike ] children
    }


heading : { level : HeadingLevel, rawText : String, children : List (Element msg) } -> Element msg
heading { level, rawText, children } =
    paragraph
        ((case headingLevelToInt level of
            1 ->
                [ Font.size 48
                , Font.bold
                , Font.color readingBlack
                , paddingXY 0 20
                ]

            2 ->
                [ Font.color readingBlack
                , Font.size 24
                , Font.bold
                , paddingEach { top = 50, right = 0, bottom = 20, left = 0 }
                ]

            3 ->
                [ Font.color readingBlack
                , Font.size 20
                , Font.bold
                , paddingXY 0 20
                ]

            4 ->
                [ Font.color readingBlack
                , Font.size 18
                , Font.bold
                , paddingXY 0 20
                ]

            _ ->
                [ Font.size 36
                , Font.bold
                , Font.center
                , paddingXY 0 20
                ]
         )
            ++ [ Region.heading (headingLevelToInt level)
               , htmlAttribute
                    (Html.Attributes.attribute "name" (rawTextToId rawText))
               , htmlAttribute
                    (Html.Attributes.id (rawTextToId rawText))
               ]
        )
        children


rawTextToId rawText =
    rawText
        |> String.toLower
        |> String.replace " " "-"
        |> String.replace "." ""


fromHtml =
    html


asHtml children =
    children
        |> List.map toHtml


toHtml e =
    layout [] e


justs =
    List.foldl
        (\v acc ->
            case v of
                Just el ->
                    [ el ] ++ acc

                Nothing ->
                    acc
        )
        []
