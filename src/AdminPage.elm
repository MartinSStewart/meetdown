module AdminPage exposing (..)

import Array
import Element exposing (Element)
import Time
import Types exposing (AdminCache(..), AdminModel, Log)
import Ui


view : Time.Zone -> { a | adminState : AdminCache, isAdmin : Bool } -> Element msg
view timezone loggedIn =
    if loggedIn.isAdmin then
        case loggedIn.adminState of
            AdminCached model ->
                Element.column
                    (Element.spacing 16 :: Ui.pageContentAttributes)
                    [ Ui.title "Admin panel"
                    , Element.paragraph
                        []
                        [ Element.text "Last checked at: "
                        , Element.text (Ui.timeToString timezone model.lastLogCheck)
                        ]
                    , Array.toList model.logs
                        |> List.map (logView model)
                        |> Element.column [ Element.spacing 8 ]
                    ]

            AdminCachePending ->
                Ui.loadingView

            AdminCacheNotRequested ->
                Ui.loadingView

    else
        Ui.loadingError "You don't have access to view this page"


logView : AdminModel -> Log -> Element msg
logView model log =
    let
        { message } =
            Types.logData model log
    in
    Element.paragraph [] [ Element.text message ]
