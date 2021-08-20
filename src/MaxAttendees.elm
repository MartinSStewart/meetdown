module MaxAttendees exposing (Error(..), MaxAttendees, maxAttendees, noLimit, toMaybe, tooManyAttendees)


type MaxAttendees
    = NoLimit
    | MaxAttendees Int


type Error
    = MaxAttendeesMustBe2OrGreater


maxAttendees : Int -> Result Error MaxAttendees
maxAttendees count =
    if count < 2 then
        Err MaxAttendeesMustBe2OrGreater

    else
        Ok (MaxAttendees count)


noLimit : MaxAttendees
noLimit =
    NoLimit


toMaybe : MaxAttendees -> Maybe Int
toMaybe maxAttendees_ =
    case maxAttendees_ of
        NoLimit ->
            Nothing

        MaxAttendees value ->
            Just value


tooManyAttendees : Int -> MaxAttendees -> Bool
tooManyAttendees attendees maxAttendees_ =
    case maxAttendees_ of
        NoLimit ->
            False

        MaxAttendees max_ ->
            attendees > max_
