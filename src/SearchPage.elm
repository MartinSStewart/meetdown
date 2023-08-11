module SearchPage exposing (getGroupsFromIds, groupPreview, view)

import AssocList as Dict
import Cache exposing (Cache(..))
import Description
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font as Font
import Event
import Group exposing (Group)
import GroupName
import Id exposing (GroupId, Id)
import MyUi
import Route exposing (Route(..))
import Time
import Types exposing (FrontendMsg, LoadedFrontend)
import UserConfig exposing (UserConfig)


getGroupsFromIds : List (Id GroupId) -> LoadedFrontend -> List ( Id GroupId, Group )
getGroupsFromIds groups model =
    List.filterMap
        (\groupId ->
            Dict.get groupId model.cachedGroups
                |> Maybe.andThen
                    (\group ->
                        case group of
                            ItemCached groupFound ->
                                Just ( groupId, groupFound )

                            ItemDoesNotExist ->
                                Nothing

                            ItemRequestPending ->
                                Nothing
                    )
        )
        groups
        |> List.sortBy (Tuple.second >> Group.name >> GroupName.toString)


view : UserConfig -> Bool -> String -> LoadedFrontend -> Element FrontendMsg
view ({ texts } as userConfig) isMobile searchText model =
    Element.column
        [ Element.padding 8
        , MyUi.contentWidth
        , Element.centerX
        , Element.spacing 8
        ]
        [ if searchText == "" then
            Element.paragraph [] [ Element.text (texts.searchResultsFor ++ "\" \"") ]

          else
            Element.paragraph [] [ Element.text (texts.searchResultsFor ++ "\"" ++ searchText ++ "\"") ]
        , Element.column
            [ Element.width Element.fill, Element.spacing 16 ]
            (getGroupsFromIds model.searchList model
                |> List.map (\( groupId, group ) -> groupPreview userConfig isMobile model.time groupId group)
            )
        ]


groupPreview : UserConfig -> Bool -> Time.Posix -> Id GroupId -> Group -> Element msg
groupPreview ({ theme, texts } as userConfig) isMobile currentTime groupId group =
    Element.link
        (Element.width Element.fill
            :: MyUi.inputFocusClass
            :: MyUi.cardAttributes theme
            ++ [ Element.paddingEach { top = 15, left = 15, right = 15, bottom = 0 }
               , Element.Border.color theme.darkGrey
               ]
        )
        { url = Route.encode (GroupRoute groupId (Group.name group))
        , label =
            Element.column
                [ Element.width Element.fill
                , Element.spacing 8
                , Element.inFront
                    (Element.el
                        [ Element.Background.gradient
                            { angle = pi
                            , steps =
                                [ Element.rgba 1 1 1 0
                                , Element.rgba 1 1 1 0
                                , Element.rgba 1 1 1 0
                                , Element.rgba 1 1 1 0
                                , Element.rgba 1 1 1 0
                                , Element.rgba 1 1 1 0
                                , theme.background
                                ]
                            }
                        , Element.width Element.fill
                        , Element.height Element.fill
                        ]
                        Element.none
                    )
                , Element.height (Element.maximum 140 Element.shrink)
                , Element.clip
                ]
                [ Element.row
                    [ Element.width Element.fill ]
                    [ Group.name group
                        |> GroupName.toString
                        |> Element.text
                        |> List.singleton
                        |> Element.paragraph
                            [ Font.bold
                            , Element.alignTop
                            , Element.width (Element.fillPortion 2)
                            ]
                    , case
                        Group.events currentTime group
                            |> .futureEvents
                            |> List.filter (Tuple.second >> Event.isCancelled >> not)
                            |> List.head
                      of
                        Just ( _, nextEvent ) ->
                            texts.nextEventIsIn
                                ++ texts.timeDiffToString currentTime (Event.startTime nextEvent)
                                |> Element.text
                                |> List.singleton
                                |> Element.paragraph
                                    [ Font.alignRight
                                    , Element.alignTop
                                    , Element.width (Element.fillPortion 1)
                                    , if isMobile then
                                        Font.size 14

                                      else
                                        MyUi.defaultFontSize
                                    ]

                        Nothing ->
                            Element.none
                    ]
                , Group.description group
                    |> Description.toParagraph userConfig True
                ]
        }
