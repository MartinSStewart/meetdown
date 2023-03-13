module MarkdownThemed exposing (renderFull, renderMinimal)

import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Region
import Html
import Html.Attributes
import Markdown.Block exposing (HeadingLevel, ListItem(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import UserConfig exposing (Texts, Theme, UserConfig)


{-| Markdown with only the minimal parts, and a flag to restrict things even further e.g. for search result summaries
-}
renderMinimal : UserConfig -> Bool -> String -> Element msg
renderMinimal { theme, texts } isSearchPreview markdownBody =
    let
        rendererMinimal =
            renderer theme isSearchPreview
                |> (\r -> { r | heading = \data -> Element.row [] [ Element.paragraph [] data.children ] })
    in
    render texts rendererMinimal markdownBody


renderFull : UserConfig -> String -> Element msg
renderFull { theme, texts } markdownBody =
    render texts (renderer theme False) markdownBody


render : Texts -> Markdown.Renderer.Renderer (Element msg) -> String -> Element msg
render texts chosenRenderer markdownBody =
    Markdown.Parser.parse markdownBody
        -- @TODO show markdown parsing errors, i.e. malformed html?
        |> Result.withDefault []
        |> (\parsed ->
                parsed
                    |> Markdown.Renderer.render chosenRenderer
                    |> (\res ->
                            case res of
                                Ok elements ->
                                    elements

                                Err err ->
                                    [ Element.text texts.oopsSomethingWentWrongRenderingThisPage, Element.text err ]
                       )
                    |> Element.column
                        [ Element.width Element.fill
                        , Element.spacing 20
                        ]
           )


renderer : Theme -> Bool -> Markdown.Renderer.Renderer (Element msg)
renderer theme searchPreview =
    { heading = \data -> Element.row [] [ heading theme data ]
    , paragraph = \children -> Element.paragraph [ Element.paddingXY 0 10 ] children
    , blockQuote =
        \children ->
            Element.column
                [ Element.Font.size 20
                , Element.Font.italic
                , Element.Border.widthEach { bottom = 0, left = 4, right = 0, top = 0 }
                , Element.Border.color theme.grey
                , Element.Font.color theme.mutedText
                , Element.padding 10
                ]
                children
    , html = Markdown.Html.oneOf []
    , text = \s -> Element.el [] (Element.text s)
    , codeSpan =
        \content -> Element.html (Html.code [] [ Html.text content ])
    , strong = \list -> Element.paragraph [ Element.Font.bold ] list
    , emphasis = \list -> Element.paragraph [ Element.Font.italic ] list
    , hardLineBreak = Element.html (Html.br [] [])
    , link =
        \{ title, destination } list ->
            Element.link
                [ Element.Font.underline
                , Element.Font.color
                    (if searchPreview then
                        theme.mutedText

                     else
                        theme.link
                    )
                ]
                { url = destination
                , label =
                    case title of
                        Just title_ ->
                            Element.text title_

                        Nothing ->
                            Element.paragraph [] list
                }
    , image =
        if searchPreview then
            \_ -> Element.none

        else
            \{ alt, src, title } ->
                let
                    attrs =
                        [ title |> Maybe.map (\title_ -> Element.htmlAttribute (Html.Attributes.attribute "title" title_)) ]
                            |> justs
                in
                Element.image
                    attrs
                    { src = src
                    , description = alt
                    }
    , unorderedList =
        \items ->
            Element.column [ Element.spacing 15, Element.width Element.fill ]
                (items
                    |> List.map
                        (\listItem ->
                            case listItem of
                                ListItem _ children ->
                                    Element.wrappedRow
                                        [ Element.spacing 5
                                        , Element.paddingEach { top = 0, right = 0, bottom = 0, left = 20 }
                                        , Element.width Element.fill
                                        ]
                                        [ Element.paragraph
                                            [ Element.alignTop ]
                                            (Element.text " • " :: children)
                                        ]
                        )
                )
    , orderedList =
        \startingIndex items ->
            Element.column [ Element.spacing 15, Element.width Element.fill ]
                (items
                    |> List.indexedMap
                        (\index itemBlocks ->
                            Element.wrappedRow
                                [ Element.spacing 5
                                , Element.paddingEach { top = 0, right = 0, bottom = 0, left = 20 }
                                , Element.width Element.fill
                                ]
                                [ Element.paragraph
                                    [ Element.alignTop ]
                                    (Element.text (String.fromInt (startingIndex + index) ++ ". ") :: itemBlocks)
                                ]
                        )
                )
    , codeBlock =
        \{ body } ->
            Element.column
                [ Element.Font.family [ Element.Font.monospace ]
                , Element.Background.color theme.lightGrey
                , Element.Border.rounded 5
                , Element.padding 10
                , Element.width Element.fill
                , Element.htmlAttribute (Html.Attributes.class "preserve-white-space")
                , if searchPreview then
                    Element.clipX

                  else
                    Element.scrollbarX
                ]
                [ Element.html (Html.text body)
                ]
    , thematicBreak = Element.none
    , table = \children -> Element.column [ Element.width Element.fill ] children
    , tableHeader = \children -> Element.column [] children
    , tableBody = \children -> Element.column [] children
    , tableRow = \children -> Element.row [ Element.width Element.fill ] children
    , tableCell = \_ children -> Element.column [ Element.width Element.fill ] children
    , tableHeaderCell = \_ children -> Element.column [ Element.width Element.fill ] children
    , strikethrough = \children -> Element.paragraph [ Element.Font.strike ] children
    }


heading : Theme -> { level : HeadingLevel, rawText : String, children : List (Element msg) } -> Element msg
heading theme { level, rawText, children } =
    Element.paragraph
        ((case Markdown.Block.headingLevelToInt level of
            1 ->
                [ Element.Font.size 28
                , Element.Font.bold
                , Element.Font.color theme.defaultText
                , Element.paddingXY 0 20
                ]

            2 ->
                [ Element.Font.color theme.defaultText
                , Element.Font.size 20
                , Element.Font.bold
                , Element.paddingEach { top = 50, right = 0, bottom = 20, left = 0 }
                ]

            3 ->
                [ Element.Font.color theme.defaultText
                , Element.Font.size 18
                , Element.Font.bold
                , Element.paddingEach { top = 30, right = 0, bottom = 10, left = 0 }
                ]

            4 ->
                [ Element.Font.color theme.defaultText
                , Element.Font.size 16
                , Element.Font.bold
                , Element.paddingEach { top = 0, right = 0, bottom = 10, left = 0 }
                ]

            _ ->
                [ Element.Font.size 12
                , Element.Font.bold
                , Element.Font.center
                , Element.paddingXY 0 20
                ]
         )
            ++ [ Element.Region.heading (Markdown.Block.headingLevelToInt level)
               , Element.htmlAttribute
                    (Html.Attributes.attribute "name" (rawTextToId rawText))
               , Element.htmlAttribute
                    (Html.Attributes.id (rawTextToId rawText))
               ]
        )
        children


rawTextToId : String -> String
rawTextToId rawText =
    rawText
        |> String.toLower
        |> String.replace " " "-"
        |> String.replace "." ""


justs : List (Maybe a) -> List a
justs =
    List.foldl
        (\v acc ->
            case v of
                Just el ->
                    el :: acc

                Nothing ->
                    acc
        )
        []
