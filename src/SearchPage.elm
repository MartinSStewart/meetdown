module SearchPage exposing (getGroupsFromIds, view)

import AssocList as Dict
import Colors
import Description
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Group exposing (Group)
import GroupName
import Id exposing (GroupId, Id)
import Route exposing (Route(..))
import Types exposing (Cache(..), FrontendMsg, LoadedFrontend)
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


view : String -> LoadedFrontend -> Element FrontendMsg
view searchText model =
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
                |> List.map (\( groupId, group ) -> groupView groupId group)
            )
        ]


groupView : Id GroupId -> Group -> Element msg
groupView groupId group =
    Element.link
        (Element.width Element.fill
            :: Ui.inputFocusClass
            :: Ui.cardAttributes
            ++ [ Element.paddingEach { top = 15, left = 15, right = 15, bottom = 0 }
               , Element.Border.color Colors.darkGrey
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
                                , Element.rgba 1 1 1 1
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
                [ Group.name group
                    |> GroupName.toString
                    |> Element.text
                    |> List.singleton
                    |> Element.paragraph [ Element.Font.bold ]
                , Group.description group
                    |> Description.toParagraph True
                ]
        }
