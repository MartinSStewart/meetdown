module Ics exposing (generateEventIcs)

{-| Generate a simple iCalendar (.ics) string for an event.
-}


generateEventIcs : { summary : String, description : String, location : String, startUtc : String, endUtc : String } -> String
generateEventIcs event =
    """BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//meetdown.app//EN
BEGIN:VEVENT
SUMMARY:""" ++ event.summary ++ """
DESCRIPTION:""" ++ event.description ++ """
LOCATION:""" ++ event.location ++ """
DTSTART:""" ++ event.startUtc ++ """
DTEND:""" ++ event.endUtc ++ """
END:VEVENT
END:VCALENDAR"""
