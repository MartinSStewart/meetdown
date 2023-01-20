module AdminPage exposing (..)

import AdminStatus exposing (AdminStatus(..))
import Array
import Colors exposing (UserConfig)
import Element exposing (Element)
import HtmlId
import Time
import Types exposing (AdminCache(..), AdminModel, FrontendMsg(..), Log)
import Ui


view : UserConfig -> Time.Zone -> { a | adminState : AdminCache, adminStatus : AdminStatus } -> Element FrontendMsg
view userConfig timezone loggedIn =
    case loggedIn.adminStatus of
        IsNotAdmin ->
            Ui.loadingError userConfig "Sorry, you aren't allowed to view this page"

        IsAdminAndEnabled ->
            adminView userConfig True timezone loggedIn

        IsAdminButDisabled ->
            adminView userConfig False timezone loggedIn


adminView : UserConfig -> Bool -> Time.Zone -> { a | adminState : AdminCache } -> Element FrontendMsg
adminView userConfig adminEnabled timezone loggedIn =
    case loggedIn.adminState of
        AdminCached model ->
            Element.column
                Ui.pageContentAttributes
                [ Ui.title "Admin panel"
                , if adminEnabled then
                    Ui.submitButton userConfig enableAdminId False { onPress = PressedDisableAdmin, label = "Disable admin" }

                  else
                    Ui.dangerButton userConfig enableAdminId False { onPress = PressedEnableAdmin, label = "Enable admin" }
                , Element.paragraph
                    []
                    [ Element.text "Logs last updated at: "
                    , Element.text (Ui.timeToString timezone model.lastLogCheck)
                    ]
                , Array.toList model.logs
                    |> List.map (logView userConfig timezone model)
                    |> Element.column [ Element.spacing 16 ]
                ]

        AdminCachePending ->
            Ui.loadingView

        AdminCacheNotRequested ->
            Ui.loadingView


enableAdminId =
    HtmlId.buttonId "adminPageEnableAdmin"


logView : UserConfig -> Time.Zone -> AdminModel -> Log -> Element msg
logView userConfig timezone model log =
    let
        { message, time, isError } =
            Types.logData model log
    in
    Element.column
        []
        [ Ui.datetimeToString timezone time |> Ui.formLabelAboveEl userConfig
        , Element.paragraph []
            [ if isError then
                Element.text "🔥 "

              else
                Element.none
            , Element.text message
            ]
        ]
