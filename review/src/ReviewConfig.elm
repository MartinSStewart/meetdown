module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule exposing (Rule)
import ReviewPipelineStyles
import ReviewPipelineStyles.Fixes


config : List Rule
config =
    [ NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Variables.rule
    , NoUnused.Patterns.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoUnused.Modules.rule
    , NoUnused.Parameters.rule
    , ReviewPipelineStyles.rule
        [ ReviewPipelineStyles.forbid ReviewPipelineStyles.leftPizzaPipelines
            |> ReviewPipelineStyles.andTryToFixThemBy ReviewPipelineStyles.Fixes.convertingToParentheticalApplication
            |> ReviewPipelineStyles.andCallThem "forbidden <| pipeline"
        , ReviewPipelineStyles.forbid ReviewPipelineStyles.leftCompositionPipelines
            |> ReviewPipelineStyles.andTryToFixThemBy ReviewPipelineStyles.Fixes.convertingToRightComposition
            |> ReviewPipelineStyles.andCallThem "forbidden << composition"
        ]
        |> Review.Rule.ignoreErrorsForDirectories [ "tests" ]
    ]
        |> List.map (Review.Rule.ignoreErrorsForDirectories [ "src/Evergreen", "justinmimbs", "send-grid" ])
        |> List.map (Review.Rule.ignoreErrorsForFiles [ "src/Postmark.elm", "src/Unsafe.elm" ])
