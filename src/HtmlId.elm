module HtmlId exposing (..)

import Effect.Browser.Dom as Dom exposing (HtmlId)


buttonId : String -> HtmlId
buttonId =
    (++) "a_" >> Dom.id


textInputId : String -> HtmlId
textInputId =
    (++) "b_" >> Dom.id


radioButtonId : String -> (a -> String) -> a -> HtmlId
radioButtonId radioGroupName valueToString value =
    "c_" ++ radioGroupName ++ "_" ++ valueToString value |> Dom.id


numberInputId : String -> HtmlId
numberInputId =
    (++) "d_" >> Dom.id


dateInputId : String -> HtmlId
dateInputId =
    (++) "e_" >> Dom.id


timeInputId : String -> HtmlId
timeInputId =
    (++) "f_" >> Dom.id
