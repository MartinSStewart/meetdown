module AdminPage exposing (..)

import AdminStatus exposing (AdminStatus(..))
import Array
import Effect.Browser.Dom exposing (HtmlId)
import Element exposing (Element)
import HtmlId
import Time
import Types exposing (AdminCache(..), AdminModel, FrontendMsg(..), Log)
import Ui
import UserConfig exposing (UserConfig)


view : UserConfig -> Time.Zone -> { a | adminState : AdminCache, adminStatus : AdminStatus } -> Element FrontendMsg
view userConfig timezone loggedIn =
    case loggedIn.adminStatus of
        IsNotAdmin ->
            Ui.loadingError userConfig.theme "Sorry, you aren't allowed to view this page"

        IsAdminAndEnabled ->
            adminView userConfig True timezone loggedIn

        IsAdminButDisabled ->
            adminView userConfig False timezone loggedIn


adminView : UserConfig -> Bool -> Time.Zone -> { a | adminState : AdminCache } -> Element FrontendMsg
adminView ({ theme, texts } as userConfig) adminEnabled timezone loggedIn =
    case loggedIn.adminState of
        AdminCached model ->
            Element.column
                Ui.pageContentAttributes
                [ Ui.title "Admin panel"
                , if adminEnabled then
                    Ui.submitButton theme enableAdminId False { onPress = PressedDisableAdmin, label = "Disable admin" }

                  else
                    Ui.dangerButton theme enableAdminId False { onPress = PressedEnableAdmin, label = "Enable admin" }
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
            Ui.loadingView texts

        AdminCacheNotRequested ->
            Ui.loadingView texts


enableAdminId : HtmlId
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
        [ Ui.datetimeToString timezone time |> Ui.formLabelAboveEl userConfig.theme
        , Element.paragraph []
            [ if isError then
                Element.text "🔥 "

              else
                Element.none
            , Element.text message
            ]
        ]
