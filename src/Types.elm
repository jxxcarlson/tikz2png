module Types exposing (..)

import File exposing (File)
import Http
import Json.Encode as Encode

import Time exposing (Posix)

type TikzResponse
    = TikzSuccess String String
    | TikzError String String

type Msg
    = TextChanged String
    | NameChanged String
    | SendRequest
    | GotResponse (Result Http.Error TikzResponse)
    | Tick Posix
    | SelectFile String
    | DeleteFile String
    | ImportFile
    | FileSelected File
    | FileLoaded String String
    | SaveFile
    | NewFile
    | FilesFromStorage Encode.Value
