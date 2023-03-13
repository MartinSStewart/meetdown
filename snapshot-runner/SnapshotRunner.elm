port module SnapshotRunner exposing (main)

import AssocList as Dict exposing (Dict)
import Bytes exposing (Bytes)
import Effect.Snapshot exposing (PercyApiKey(..), Snapshot)
import Effect.Test
import Html
import Json.Decode exposing (Decoder)
import List.Nonempty exposing (Nonempty(..))
import Task
import Tests


type alias Flags =
    { currentBranch : String
    , filepaths : List String
    , percyApiKey : String
    }


type alias Model =
    Result () OkModel


type alias OkModel =
    { files : Dict String Bytes
    , currentBranch : String
    , remainingFilepaths : Nonempty String
    , percyApiKey : PercyApiKey
    }


type Msg
    = FileResponse Bytes
    | UploadFinished (Result Effect.Snapshot.Error { success : Bool })


port requestFile : String -> Cmd msg


port fileResponse : (Bytes -> msg) -> Sub msg


port writeLine : String -> Cmd msg


snapshots : List (Snapshot ())
snapshots =
    List.concatMap Effect.Test.toSnapshots Tests.tests
        |> List.map
            (\snapshot ->
                { name = snapshot.name
                , body = List.map (Html.map (\_ -> ())) snapshot.body
                , widths = snapshot.widths
                , minimumHeight = snapshot.minimumHeight
                }
            )


decodeFlags : Decoder Flags
decodeFlags =
    Json.Decode.map3 Flags
        (Json.Decode.field "currentBranch" Json.Decode.string)
        (Json.Decode.field "filepaths" (Json.Decode.list Json.Decode.string))
        (Json.Decode.field "percyApiKey" Json.Decode.string)


main : Program Json.Decode.Value Model Msg
main =
    Platform.worker
        { init =
            \flagsJson ->
                case Json.Decode.decodeValue decodeFlags flagsJson of
                    Ok flags ->
                        case List.Nonempty.fromList flags.filepaths of
                            Just nonempty ->
                                ( { files = Dict.empty
                                  , currentBranch = flags.currentBranch
                                  , remainingFilepaths = nonempty
                                  , percyApiKey = PercyApiKey flags.percyApiKey
                                  }
                                    |> Ok
                                , requestFile (List.Nonempty.head nonempty)
                                )

                            Nothing ->
                                let
                                    model =
                                        { files = Dict.empty
                                        , currentBranch = flags.currentBranch
                                        , remainingFilepaths = Nonempty "" []
                                        , percyApiKey = PercyApiKey flags.percyApiKey
                                        }
                                in
                                ( Ok model, upload model )

                    Err error ->
                        ( Err (), Json.Decode.errorToString error |> writeLine )
        , update = update
        , subscriptions = \_ -> fileResponse FileResponse
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FileResponse content ->
            case model of
                Ok okModel ->
                    let
                        newModel =
                            { okModel
                                | files = Dict.insert (List.Nonempty.head okModel.remainingFilepaths) content okModel.files
                            }
                    in
                    case List.Nonempty.tail okModel.remainingFilepaths |> List.Nonempty.fromList of
                        Just nonempty ->
                            ( Ok { newModel | remainingFilepaths = nonempty }
                            , requestFile (List.Nonempty.head nonempty)
                            )

                        Nothing ->
                            ( Ok newModel, upload newModel )

                Err _ ->
                    ( model, Cmd.none )

        UploadFinished result ->
            case result of
                Ok { success } ->
                    ( model
                    , if success then
                        writeLine "Snapshots uploaded!"

                      else
                        writeLine "Failed to complete upload."
                    )

                Err error ->
                    ( model, writeLine (Effect.Snapshot.errorToString error) )


upload : OkModel -> Cmd Msg
upload model =
    case List.Nonempty.fromList snapshots of
        Just nonempty ->
            Effect.Snapshot.uploadSnapshots
                { apiKey = model.percyApiKey
                , gitBranch = model.currentBranch
                , gitTargetBranch = "master"
                , snapshots = nonempty
                , publicFiles =
                    Dict.toList model.files
                        |> List.map (\( key, value ) -> { filepath = key, content = value })
                }
                |> Task.attempt UploadFinished

        Nothing ->
            writeLine "There weren't any snapshots to upload"
