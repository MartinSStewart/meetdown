module Tests exposing (suite)

import Env
import Test exposing (..)
import TestFramework


suite : Test
suite =
    describe "App tests"
        [ test "Get login email" <|
            \_ ->
                TestFramework.init
                    |> TestFramework.connectFrontend (TestFramework.unsafeUrl ("https://" ++ Env.domain ++ "/"))
                    |> (\( state, _ ) -> state)
                    |> TestFramework.finishSimulation
        ]
