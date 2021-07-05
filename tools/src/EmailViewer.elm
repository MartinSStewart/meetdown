module EmailViewer exposing (main)

import BackendLogic
import Email.Html
import Event
import Html exposing (Html)
import Id
import MaxAttendees
import Route
import String.Nonempty exposing (NonemptyString)
import Time
import Unsafe


main : Html msg
main =
    (loginEmail :: deleteAccountEmail :: eventReminderEmail)
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
        (BackendLogic.loginEmailContent Route.HomepageRoute (Unsafe.id "123") Nothing)


deleteAccountEmail : Html msg
deleteAccountEmail =
    emailView
        BackendLogic.deleteAccountEmailSubject
        (BackendLogic.deleteAccountEmailContent (Unsafe.id "123"))


eventReminderEmail : List (Html msg)
eventReminderEmail =
    let
        groupName =
            Unsafe.groupName "My group!"

        eventName =
            Unsafe.eventName "Our first event"

        description =
            Unsafe.description "We're gonna party like it's 1940-something"

        event eventType =
            Event.newEvent
                (Unsafe.id "123")
                eventName
                description
                eventType
                (Time.millisToPosix 10000000)
                (Unsafe.eventDuration 60)
                (Time.millisToPosix 1000000)
                MaxAttendees.noLimit

        onlineEventWithLink =
            event (Unsafe.link "https://example-site.com/event" |> Just |> Event.MeetOnline)

        onlineEventWithoutLink =
            event (Event.MeetOnline Nothing)

        inPersonEventWithAddress =
            event (Unsafe.address "123 Example Lane, Townsend" |> Just |> Event.MeetInPerson)

        inPersonEventWithoutAddress =
            event (Event.MeetInPerson Nothing)
    in
    [ emailView
        (BackendLogic.eventReminderEmailSubject groupName onlineEventWithLink Time.utc)
        (BackendLogic.eventReminderEmailContent (Unsafe.id "0") groupName onlineEventWithLink)
    , emailView
        (BackendLogic.eventReminderEmailSubject groupName onlineEventWithoutLink Time.utc)
        (BackendLogic.eventReminderEmailContent (Unsafe.id "0") groupName onlineEventWithoutLink)
    , emailView
        (BackendLogic.eventReminderEmailSubject groupName inPersonEventWithAddress Time.utc)
        (BackendLogic.eventReminderEmailContent (Unsafe.id "0") groupName inPersonEventWithAddress)
    , emailView
        (BackendLogic.eventReminderEmailSubject groupName inPersonEventWithoutAddress Time.utc)
        (BackendLogic.eventReminderEmailContent (Unsafe.id "0") groupName inPersonEventWithoutAddress)
    ]
