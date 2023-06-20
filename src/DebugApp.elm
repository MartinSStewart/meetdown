module DebugApp exposing (backend)

import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http
import Effect.Lamdera
import Json.Encode


backend backendNoOp sessionName broadcast sendToFrontend { init, update, updateFromFrontend, subscriptions } =
    Effect.Lamdera.backend
        broadcast
        sendToFrontend
        { init =
            let
                ( model, cmd ) =
                    init
            in
            ( model
            , Command.batch
                [ cmd
                , sendToViewer
                    backendNoOp
                    (Init { sessionName = sessionName, model = Debug.toString model })
                ]
            )
        , update =
            \msg model ->
                let
                    ( newModel, cmd ) =
                        update msg model
                in
                ( newModel
                , Command.batch
                    [ cmd
                    , if backendNoOp == msg then
                        Command.none

                      else
                        sendToViewer
                            backendNoOp
                            (Update
                                { sessionName = sessionName
                                , msg = Debug.toString msg
                                , newModel = Debug.toString model
                                }
                            )
                    ]
                )
        , updateFromFrontend =
            \sessionId clientId msg model ->
                let
                    ( newModel, cmd ) =
                        updateFromFrontend sessionId clientId msg model
                in
                ( newModel
                , Command.batch
                    [ cmd
                    , sendToViewer
                        backendNoOp
                        (UpdateFromFrontend
                            { sessionName = sessionName
                            , msg = Debug.toString msg
                            , newModel = Debug.toString model
                            , sessionId = Effect.Lamdera.sessionIdToString sessionId
                            , clientId = Effect.Lamdera.clientIdToString clientId
                            }
                        )
                    ]
                )
        , subscriptions = subscriptions
        }


type DataType
    = Init { sessionName : String, model : String }
    | Update { sessionName : String, msg : String, newModel : String }
    | UpdateFromFrontend { sessionName : String, msg : String, newModel : String, sessionId : String, clientId : String }


sendToViewer : msg -> DataType -> Command BackendOnly toFrontend msg
sendToViewer backendNoOp data =
    Effect.Http.post
        { url = "https://backend-debugger.lamdera.app/_r/data"
        , body = Effect.Http.jsonBody (encodeDataType data)
        , expect = Effect.Http.expectWhatever (\_ -> backendNoOp)
        }


encodeDataType : DataType -> Json.Encode.Value
encodeDataType data =
    Json.Encode.list
        identity
        (case data of
            Init { sessionName, model } ->
                [ Json.Encode.int 0
                , Json.Encode.string sessionName
                , Json.Encode.string model
                ]

            Update { sessionName, msg, newModel } ->
                [ Json.Encode.int 1
                , Json.Encode.string sessionName
                , Json.Encode.string msg
                , Json.Encode.string newModel
                ]

            UpdateFromFrontend { sessionName, msg, newModel, sessionId, clientId } ->
                [ Json.Encode.int 2
                , Json.Encode.string sessionName
                , Json.Encode.string msg
                , Json.Encode.string newModel
                , Json.Encode.string sessionId
                , Json.Encode.string clientId
                ]
        )
