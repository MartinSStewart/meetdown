module AdminPage exposing (..)

import AdminStatus exposing (AdminStatus(..))
import Array
import Element exposing (Element)
import HtmlId
import Time
import Types exposing (AdminCache(..), AdminModel, FrontendMsg(..), Log)
import Ui


view : Time.Zone -> { a | adminState : AdminCache, adminStatus : AdminStatus } -> Element FrontendMsg
view timezone loggedIn =
    case loggedIn.adminStatus of
        IsNotAdmin ->
            Ui.loadingError "Sorry, you aren't allowed to view this page"

        IsAdminAndEnabled ->
            adminView True timezone loggedIn

        IsAdminButDisabled ->
            adminView False timezone loggedIn


adminView : Bool -> Time.Zone -> { a | adminState : AdminCache } -> Element FrontendMsg
adminView adminEnabled timezone loggedIn =
    case loggedIn.adminState of
        AdminCached model ->
            Element.column
                Ui.pageContentAttributes
                [ Ui.title "Admin panel"
                , if adminEnabled then
                    Ui.submitButton enableAdminId False { onPress = PressedDisableAdmin, label = "Disable admin" }

                  else
                    Ui.dangerButton enableAdminId False { onPress = PressedEnableAdmin, label = "Enable admin" }
                , Element.paragraph
                    []
                    [ Element.text "Logs last updated at: "
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


enableAdminId =
    HtmlId.buttonId "adminPageEnableAdmin"


logView : Time.Zone -> AdminModel -> Log -> Element msg
logView timezone model log =
    let
        { message, time, isError } =
            Types.logData model log
    in
    Element.column
        []
        [ Ui.datetimeToString timezone time |> Ui.formLabelAboveEl
        , Element.paragraph []
            [ if isError then
                Element.text "🔥 "

              else
                Element.none
            , Element.text message
            ]
        ]
