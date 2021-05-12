module RemoteData exposing (RemoteData(..))


type RemoteData e a
    = Loading
    | Success a
    | Failure e
