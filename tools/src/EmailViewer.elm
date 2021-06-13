module EmailViewer exposing (main)

import BackendLogic
import Email.Html
import Event
import Html exposing (Html)
import Id
import Route
import String.Nonempty exposing (NonemptyString)
import Time
import Unsafe


main : Html msg
main =
    [ loginEmail, deleteAccountEmail, eventReminderEmail ]
        |> List.intersperse line
        |> Html.div []


line : Html msg
line =
    Html.hr [] []


emailView : NonemptyString -> Email.Html.Html -> Html msg
emailView subject content =
    Html.div
        []
        [ String.Nonempty.toString subject |> Html.text
        , Email.Html.toHtml content
        ]


loginEmail : Html msg
loginEmail =
    emailView
        BackendLogic.loginEmailSubject
        (BackendLogic.loginEmailContent Route.HomepageRoute (Id.cryptoHashFromString "123") Nothing)


deleteAccountEmail : Html msg
deleteAccountEmail =
    emailView
        BackendLogic.deleteAccountEmailSubject
        (BackendLogic.deleteAccountEmailContent (Id.cryptoHashFromString "123"))


eventReminderEmail : Html msg
eventReminderEmail =
    let
        groupName =
            Unsafe.groupName "My group!"

        eventName =
            Unsafe.eventName "Our first event"

        description =
            Unsafe.description "We're gonna party like it's 1940-something"

        eventType =
            Unsafe.link "https://example-site.com" |> Just |> Event.MeetOnline

        event =
            Event.newEvent
                eventName
                description
                eventType
                (Time.millisToPosix 10000000)
                (Unsafe.eventDuration 60)
                (Time.millisToPosix 1000000)
    in
    emailView
        (BackendLogic.eventReminderEmailSubject groupName event Time.utc)
        (BackendLogic.eventReminderEmailContent (Id.groupIdFromInt 0) groupName event)
