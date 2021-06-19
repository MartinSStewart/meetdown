module SearchPage exposing (getGroupsFromIds, view)

import AssocList as Dict
import Description
import Element exposing (Element)
import Element.Border
import Element.Font
import Group exposing (Group)
import GroupName
import Id exposing (GroupId)
import Route exposing (Route(..))
import Types exposing (FrontendMsg, GroupCache(..), LoadedFrontend)
import Ui


getGroupsFromIds : List GroupId -> LoadedFrontend -> List ( GroupId, Group )
getGroupsFromIds groups model =
    List.filterMap
        (\groupId ->
            Dict.get groupId model.cachedGroups
                |> Maybe.andThen
                    (\group ->
                        case group of
                            GroupFound groupFound ->
                                Just ( groupId, groupFound )

                            GroupNotFound ->
                                Nothing

                            GroupRequestPending ->
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
            Element.none

          else
            Element.paragraph [] [ Element.text <| "Search results for \"" ++ searchText ++ "\"" ]
        , Element.column
            [ Element.width Element.fill, Element.spacing 16 ]
            (getGroupsFromIds model.searchList model
                |> List.map (\( groupId, group ) -> groupView groupId group)
            )
        ]


groupView : GroupId -> Group -> Element msg
groupView groupId group =
    let
        description =
            Group.description group |> Description.toString
    in
    Element.link
        (Element.width Element.fill
            :: Ui.inputFocusClass
            :: Ui.cardAttributes
        )
        { url = Route.encode (GroupRoute groupId (Group.name group))
        , label =
            Element.column
                [ Element.width Element.fill, Element.spacing 8 ]
                [ Group.name group
                    |> GroupName.toString
                    |> Element.text
                    |> List.singleton
                    |> Element.paragraph [ Element.Font.bold ]
                , if description == "" then
                    Element.paragraph [ Element.Font.italic ] [ Element.text "No description" ]

                  else
                    Element.text description
                        |> List.singleton
                        |> Element.paragraph []
                ]
        }
