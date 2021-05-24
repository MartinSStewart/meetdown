module GroupPage exposing (Model, Msg, init, update, view)

import Description
import Editable exposing (Editable(..))
import Element exposing (Element)
import Element.Border
import Element.Font
import Element.Input
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import GroupName
import Name
import ProfileImage
import Time
import Ui


type alias Model =
    { name : Editable String
    , description : Editable String
    }


type Msg
    = PressedEditDescription
    | PressedSubmitDescription
    | PressedCancelDescription


type alias Effects cmd =
    { none : cmd }


init : Model
init =
    { name = Unchanged
    , description = Unchanged
    }


update : Effects cmd -> Msg -> Model -> ( Model, cmd )
update effects msg model =
    ( model, effects.none )


view : Time.Posix -> FrontendUser -> Group -> Maybe Model -> Element Msg
view currentTime owner group maybeModel =
    let
        { pastEvents, futureEvents } =
            Group.events currentTime group
    in
    Element.column
        [ Element.spacing 8, Element.padding 8, Element.width Element.fill ]
        [ Element.row
            [ Element.width Element.fill ]
            [ group
                |> Group.name
                |> GroupName.toString
                |> Ui.title
                |> Element.el [ Element.alignTop, Element.width Element.fill ]
            , Ui.section "Organizer"
                (Element.row
                    [ Element.spacing 16 ]
                    [ ProfileImage.smallImage owner.profileImage
                    , Element.text (Name.toString owner.name)
                    ]
                )
            ]
        , case Maybe.map .description maybeModel of
            Just (Editting description) ->
                Element.none

            _ ->
                Element.column
                    [ Element.spacing 8
                    , Element.padding 8
                    , Element.Border.rounded 4
                    , Ui.inputBackground False
                    ]
                    [ Element.row
                        [ Element.spacing 16 ]
                        [ Element.paragraph [ Element.Font.bold ] [ Element.text "Description" ]
                        , Element.Input.button
                            []
                            { onPress = Just PressedEditDescription, label = Element.text "Edit" }
                        ]
                    , Element.paragraph
                        []
                        [ group
                            |> Group.description
                            |> Description.toString
                            |> Element.text
                        ]
                    ]

        --, Ui.section "Description"
        --    (if Description.toString (Group.description group) == "" then
        --        Element.paragraph
        --            [ Element.Font.color <| Element.rgb 0.45 0.45 0.45
        --            , Element.Font.italic
        --            ]
        --            [ Element.text "No description provided" ]
        --
        --     else
        --        Element.paragraph
        --            []
        --            [ group
        --                |> Group.description
        --                |> Description.toString
        --                |> Element.text
        --            ]
        --    )
        , case futureEvents of
            nextEvent :: _ ->
                Ui.section "Next event"
                    (Element.paragraph
                        []
                        [ Element.text "No more events have been planned yet." ]
                    )

            [] ->
                Ui.section "Next event"
                    (Element.paragraph
                        []
                        [ Element.text "No more events have been planned yet." ]
                    )
        ]
