module EmailViewer exposing (main)

import Backend
import Element exposing (Element)
import Email.Html
import Event
import Html exposing (Html)
import Id
import String.Nonempty exposing (NonemptyString)
import Tests
import Time


main : Html msg
main =
    Element.layout
        []
        (Element.column
            []
            [ eventReminderEmail ]
        )


emailView : NonemptyString -> Email.Html.Html -> Element msg
emailView subject content =
    Element.column
        [ Element.spacing 8 ]
        [ Element.text (String.Nonempty.toString subject)
        , Email.Html.toHtml content
            |> Element.html
            |> Element.el [ Element.width (Element.px 600), Element.height (Element.px 800) ]
        ]


eventReminderEmail : Element msg
eventReminderEmail =
    let
        groupName =
            Tests.unsafeGroupName "My group!"

        eventName =
            Tests.unsafeEventName "Our first event"

        description =
            Tests.unsafeDescription "We're gonna party like it's 1940-something"

        eventType =
            Tests.unsafeLink "https://example-site.com" |> Just |> Event.MeetOnline

        event =
            Event.newEvent
                eventName
                description
                eventType
                (Time.millisToPosix 10000000)
                (Tests.unsafeEventDuration 60)
    in
    emailView
        (Backend.eventReminderEmailSubject groupName event Time.utc)
        (Backend.eventReminderEmailContent (Id.groupIdFromInt 0) groupName event)
