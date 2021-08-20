module HtmlId exposing (..)


type HtmlId a
    = HtmlId String


toString : HtmlId a -> String
toString (HtmlId a) =
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
