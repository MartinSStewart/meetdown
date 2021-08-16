module TestId exposing (..)


type SessionId
    = SessionId String


type ClientId
    = ClientId String


type HtmlId a
    = HtmlId String


htmlIdToString : HtmlId a -> String
htmlIdToString (HtmlId a) =
    a


type ButtonId
    = ButtonId Never


buttonId : String -> HtmlId ButtonId
buttonId =
    (++) "a_" >> HtmlId


type TextInputId
    = TextInputId Never


textInputId : String -> HtmlId TextInputId
textInputId =
    (++) "b_" >> HtmlId


type RadioButtonId
    = RadioButtonId Never


radioButtonId : String -> (a -> String) -> a -> HtmlId RadioButtonId
radioButtonId radioGroupName valueToString value =
    "c_" ++ radioGroupName ++ "_" ++ valueToString value |> HtmlId


type NumberInputId
    = NumberInputId Never


numberInputId : String -> HtmlId NumberInputId
numberInputId =
    (++) "d_" >> HtmlId


type DateInputId
    = DateInputId Never


dateInputId : String -> HtmlId DateInputId
dateInputId =
    (++) "e_" >> HtmlId


type TimeInputId
    = TimeInputId Never


timeInputId : String -> HtmlId TimeInputId
timeInputId =
    (++) "f_" >> HtmlId


sessionIdFromString : String -> SessionId
sessionIdFromString =
    SessionId


clientIdFromString : String -> ClientId
clientIdFromString =
    ClientId


clientIdToString : ClientId -> String
clientIdToString (ClientId clientId) =
    clientId
