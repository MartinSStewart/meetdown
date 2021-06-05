module Tests exposing (suite)

import Duration
import Env
import Frontend
import Html
import Html.Attributes
import Id
import LoginForm
import Route
import Test exposing (..)
import Test.Html.Event
import Test.Html.Query
import Test.Html.Selector
import TestFramework
import Ui


suite : Test
suite =
    describe "App tests"
        [ --test "a" <|
          --    \_ ->
          --        Html.a [ Html.Attributes.id "myId", Html.Attributes.href "/test" ] [ Html.text "test" ]
          --            |> List.singleton
          --            |> Html.div []
          --            |> Test.Html.Query.fromHtml
          --            |> Test.Html.Query.find [ Test.Html.Selector.id "myId" ]
          --            |> Test.Html.Event.simulate Test.Html.Event.click
          --            |> Test.Html.Event.expect 4
          test "Get login email" <|
            \_ ->
                TestFramework.init
                    |> TestFramework.connectFrontend (TestFramework.unsafeUrl ("https://" ++ Env.domain ++ "/"))
                    |> (\( state, clientId ) ->
                            state
                                |> TestFramework.simulateTime Duration.second
                                |> TestFramework.clickEvent clientId Frontend.signUpOrLoginButtonId
                                |> TestFramework.simulateTime Duration.second
                                |> TestFramework.inputEvent clientId LoginForm.emailAddressInputId "a@a.se"
                                |> TestFramework.simulateTime Duration.second
                                |> TestFramework.keyDownEvent clientId LoginForm.emailAddressInputId Ui.enterKeyCode
                                |> TestFramework.simulateTime Duration.second
                                |> TestFramework.checkState
                                    (\state2 ->
                                        let
                                            expected =
                                                [ ( TestFramework.unsafeEmailAddress "a@a.se"
                                                  , TestFramework.LoginEmail
                                                        Route.HomepageRoute
                                                        (Id.cryptoHashFromString Env.secretKey)
                                                  )
                                                ]
                                        in
                                        if state2.emailInboxes == expected then
                                            Nothing

                                        else
                                            Just (Debug.toString state2.emailInboxes)
                                    )
                       )
                    |> TestFramework.finishSimulation
        ]
