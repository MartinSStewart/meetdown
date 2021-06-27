module AdminPage exposing (..)

import Array
import Date
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
                    Ui.pageContentAttributes
                    [ Ui.title "Admin panel"
                    , Element.paragraph
                        []
                        [ Element.text "Last checked at: "
                        , Element.text (Ui.timeToString timezone model.lastLogCheck)
                        ]
                    , Array.toList model.logs
                        |> List.map (logView timezone model)
                        |> Element.column [ Element.spacing 16 ]
                    ]

            AdminCachePending ->
                Ui.loadingView

            AdminCacheNotRequested ->
                Ui.loadingView

    else
        Ui.loadingError "Sorry, you aren't allowed to view this page"


logView : Time.Zone -> AdminModel -> Log -> Element msg
logView timezone model log =
    let
        { message, time, isError } =
            Types.logData model log
    in
    Element.column
        []
        [ Ui.datestamp (Date.fromPosix timezone time)
            ++ ", "
            ++ Ui.timeToString timezone time
            |> Ui.formLabelAboveEl
        , Element.paragraph []
            [ if isError then
                Element.text "🔥 "

              else
                Element.none
            , Element.text message
            ]
        ]
