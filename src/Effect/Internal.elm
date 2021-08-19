module Effect.Internal exposing
    ( BackendOnly
    , BrowserDomError(..)
    , ClientId(..)
    , Command(..)
    , File(..)
    , FrontendOnly
    , HttpBody(..)
    , HttpRequest
    , NavigationKey(..)
    , SessionId(..)
    , Subscription(..)
    , Task(..)
    , Visibility(..)
    )

import Browser.Dom
import Browser.Navigation
import Bytes exposing (Bytes)
import Duration exposing (Duration)
import File
import Http
import Json.Decode
import Json.Encode
import Time


type SessionId
    = SessionId String


type ClientId
    = ClientId String


type FrontendOnly
    = FrontendOnly Never


type BackendOnly
    = BackendOnly Never


type Subscription restriction msg
    = SubBatch (List (Subscription restriction msg))
    | SubNone
    | TimeEvery Duration (Time.Posix -> msg)
    | OnAnimationFrame (Time.Posix -> msg)
    | OnAnimationFrameDelta (Duration -> msg)
    | OnKeyPress (Json.Decode.Decoder msg)
    | OnKeyDown (Json.Decode.Decoder msg)
    | OnKeyUp (Json.Decode.Decoder msg)
    | OnClick (Json.Decode.Decoder msg)
    | OnMouseMove (Json.Decode.Decoder msg)
    | OnMouseDown (Json.Decode.Decoder msg)
    | OnMouseUp (Json.Decode.Decoder msg)
    | OnResize (Int -> Int -> msg)
    | OnVisibilityChange (Visibility -> msg)
    | SubPort String (Sub msg) (Json.Decode.Value -> msg)
    | OnConnect (SessionId -> ClientId -> msg)
    | OnDisconnect (SessionId -> ClientId -> msg)


type Visibility
    = Visible
    | Hidden


type Command restriction toMsg msg
    = Batch (List (Command restriction toMsg msg))
    | None
    | SendToBackend toMsg
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationBack NavigationKey Int
    | NavigationForward NavigationKey Int
    | NavigationLoad String
    | NavigationReload
    | NavigationReloadAndSkipCache
    | Task (Task restriction msg msg)
    | Port String (Json.Encode.Value -> Cmd msg) Json.Encode.Value
    | SendToFrontend ClientId toMsg
    | Broadcast toMsg
    | FileDownloadUrl { href : String }
    | FileDownloadString { name : String, mimeType : String, content : String }
    | FileDownloadBytes { name : String, mimeType : String, content : Bytes }
    | FileSelectFile (List String) (File -> msg)
    | FileSelectFiles (List String) (File -> List File -> msg)


type Task restriction x a
    = Succeed a
    | Fail x
    | HttpTask (HttpRequest restriction x a)
    | SleepTask Duration (() -> Task restriction x a)
    | TimeNow (Time.Posix -> Task restriction x a)
    | TimeHere (Time.Zone -> Task restriction x a)
    | TimeGetZoneName (Time.ZoneName -> Task restriction x a)
    | Focus String (Result BrowserDomError () -> Task restriction x a)
    | Blur String (Result BrowserDomError () -> Task restriction x a)
    | GetViewport (Browser.Dom.Viewport -> Task restriction x a)
    | SetViewport Float Float (() -> Task restriction x a)
    | GetViewportOf String (Result BrowserDomError Browser.Dom.Viewport -> Task restriction x a)
    | SetViewportOf String Float Float (Result BrowserDomError () -> Task restriction x a)
    | GetElement String (Result BrowserDomError Browser.Dom.Element -> Task restriction x a)
    | FileToString File (String -> Task restriction x a)
    | FileToBytes File (Bytes -> Task restriction x a)
    | FileToUrl File (String -> Task restriction x a)


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type BrowserDomError
    = BrowserDomNotFound String


type File
    = RealFile File.File
    | MockFile { name : String, mimeType : String, content : String, lastModified : Time.Posix }


type alias HttpRequest restriction x a =
    { method : String
    , url : String
    , body : HttpBody
    , headers : List ( String, String )
    , onRequestComplete : Http.Response String -> Task restriction x a
    , timeout : Maybe Duration
    }


type HttpBody
    = EmptyBody
    | StringBody
        { contentType : String
        , content : String
        }
    | JsonBody Json.Encode.Value
