module SearchPage exposing (getGroupsFromIds, groupPreview, view)

import AssocList as Dict
import Cache exposing (Cache(..))
import Colors exposing (UserConfig)
import Description
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Event
import Group exposing (Group)
import GroupName
import Id exposing (GroupId, Id)
import Route exposing (Route(..))
import Time
import TimeExtra as Time
import Types exposing (FrontendMsg, LoadedFrontend)
import Ui


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
view userConfig isMobile searchText model =
    Element.column
        [ Element.padding 8
        , Ui.contentWidth
        , Element.centerX
        , Element.spacing 8
        ]
        [ if searchText == "" then
            Element.paragraph [] [ Element.text <| "Search results for \" \"" ]

          else
            Element.paragraph [] [ Element.text <| "Search results for \"" ++ searchText ++ "\"" ]
        , Element.column
            [ Element.width Element.fill, Element.spacing 16 ]
            (getGroupsFromIds model.searchList model
                |> List.map (\( groupId, group ) -> groupPreview userConfig isMobile model.time groupId group)
            )
        ]


groupPreview : UserConfig -> Bool -> Time.Posix -> Id GroupId -> Group -> Element msg
groupPreview userConfig isMobile currentTime groupId group =
    Element.link
        (Element.width Element.fill
            :: Ui.inputFocusClass
            :: Ui.cardAttributes userConfig
            ++ [ Element.paddingEach { top = 15, left = 15, right = 15, bottom = 0 }
               , Element.Border.color userConfig.darkGrey
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
                                , userConfig.background
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
                            [ Element.Font.bold
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
                            "Next event is in "
                                ++ Time.diffToString currentTime (Event.startTime nextEvent)
                                |> Element.text
                                |> List.singleton
                                |> Element.paragraph
                                    [ Element.Font.alignRight
                                    , Element.alignTop
                                    , Element.width (Element.fillPortion 1)
                                    , if isMobile then
                                        Element.Font.size 14

                                      else
                                        Ui.defaultFontSize
                                    ]

                        Nothing ->
                            Element.none
                    ]
                , Group.description group
                    |> Description.toParagraph userConfig True
                ]
        }
