module SearchPage exposing (getGroupsFromIds, groupPreview, view)

import AssocList as Dict
import Cache exposing (Cache(..))
import Description
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Event
import Group exposing (Group)
import GroupName
import Id exposing (GroupId, Id)
import Route exposing (Route(..))
import Time
import Types exposing (FrontendMsg, LoadedFrontend)
import Ui
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
    column
        [ padding 8
        , Ui.contentWidth
        , centerX
        , spacing 8
        ]
        [ if searchText == "" then
            paragraph [] [ text <| texts.searchResultsFor ++ "\" \"" ]

          else
            paragraph [] [ text <| texts.searchResultsFor ++ "\"" ++ searchText ++ "\"" ]
        , column
            [ width fill, spacing 16 ]
            (getGroupsFromIds model.searchList model
                |> List.map (\( groupId, group ) -> groupPreview userConfig isMobile model.time groupId group)
            )
        ]


groupPreview : UserConfig -> Bool -> Time.Posix -> Id GroupId -> Group -> Element msg
groupPreview ({ theme, texts } as userConfig) isMobile currentTime groupId group =
    link
        (width fill
            :: Ui.inputFocusClass
            :: Ui.cardAttributes theme
            ++ [ paddingEach { top = 15, left = 15, right = 15, bottom = 0 }
               , Border.color theme.darkGrey
               ]
        )
        { url = Route.encode (GroupRoute groupId (Group.name group))
        , label =
            column
                [ width fill
                , spacing 8
                , inFront
                    (el
                        [ Background.gradient
                            { angle = pi
                            , steps =
                                [ rgba 1 1 1 0
                                , rgba 1 1 1 0
                                , rgba 1 1 1 0
                                , rgba 1 1 1 0
                                , rgba 1 1 1 0
                                , rgba 1 1 1 0
                                , theme.background
                                ]
                            }
                        , width fill
                        , height fill
                        ]
                        none
                    )
                , height (maximum 140 shrink)
                , clip
                ]
                [ row
                    [ width fill ]
                    [ Group.name group
                        |> GroupName.toString
                        |> text
                        |> List.singleton
                        |> paragraph
                            [ Font.bold
                            , alignTop
                            , width (fillPortion 2)
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
                                |> text
                                |> List.singleton
                                |> paragraph
                                    [ Font.alignRight
                                    , alignTop
                                    , width (fillPortion 1)
                                    , if isMobile then
                                        Font.size 14

                                      else
                                        Ui.defaultFontSize
                                    ]

                        Nothing ->
                            none
                    ]
                , Group.description group
                    |> Description.toParagraph userConfig True
                ]
        }
