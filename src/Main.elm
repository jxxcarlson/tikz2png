port module Main exposing (main)

import Browser
import Data
import Dict exposing (Dict)
import File exposing (File)
import File.Download as Download
import File.Select as Select
import Html exposing (Html, div, textarea, img, button, text, input, label, span)
import Html.Attributes exposing (style, placeholder, value, src, type_)
import Html.Events exposing (onInput, onClick, stopPropagationOn)
import Json.Decode as Decode
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Tikz
import Types exposing(Msg(..), TikzResponse(..))
import Task
import Time exposing (Posix)


-- MAIN

main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 100 Tick
        , loadFiles FilesFromStorage
        ]


-- MODEL

type alias Model =
    { textInput : String
    , name : String
    , imageUrl : String
    , errorMsg : String
    , serverUrl : String
    , requestStartTime : Maybe Posix
    , currentTime : Posix
    , requestElapsedTime : Maybe Float
    , files : Dict String String
    , selectedFilename : Maybe String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { textInput = ""
      , name = "tikz-request"
      , imageUrl = ""
      , errorMsg = ""
      , serverUrl = "http://localhost:3000/tikz2png"
      --, serverUrl = "https://pdfServ.app/tikz2png"
      , requestStartTime = Nothing
      , currentTime = Time.millisToPosix 0
      , requestElapsedTime = Nothing
      , files = Dict.fromList Data.tikz
      , selectedFilename = Nothing
      }
    , Cmd.none
    )


-- UPDATE



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TextChanged newText ->
            ( { model | textInput = newText }, Cmd.none )

        NameChanged newName ->
            ( { model | name = newName }, Cmd.none )

        SendRequest ->
            ( { model
                | requestStartTime = Just model.currentTime
                , requestElapsedTime = Nothing
              }
            , Tikz.sendTikzRequest model.serverUrl model.name model.textInput
            )

        GotResponse result ->
            let
                elapsedTime =
                    case model.requestStartTime of
                        Just startTime ->
                            Just (toFloat (Time.posixToMillis model.currentTime - Time.posixToMillis startTime) / 1000.0)

                        Nothing ->
                            Nothing
            in
            case result of
                Ok (TikzSuccess responseName url) ->
                    ( { model | imageUrl = url, errorMsg = "", requestElapsedTime = elapsedTime }, Cmd.none )

                Ok (TikzError responseName error) ->
                    ( { model | errorMsg = error, imageUrl = "", requestElapsedTime = elapsedTime }, Cmd.none )

                Err httpError ->
                    ( { model | errorMsg = httpErrorToString httpError, imageUrl = "", requestElapsedTime = elapsedTime }, Cmd.none )

        Tick newTime ->
            ( { model | currentTime = newTime }, Cmd.none )

        SelectFile filename ->
            case Dict.get filename model.files of
                Just content ->
                    let
                        updatedModel =
                            { model
                                | selectedFilename = Just filename
                                , textInput = content
                                , name = String.replace ".tikz" "" filename
                                , requestStartTime = Just model.currentTime
                                , requestElapsedTime = Nothing
                                , imageUrl = ""
                                , errorMsg = ""
                            }
                    in
                    ( updatedModel
                    , Tikz.sendTikzRequest updatedModel.serverUrl updatedModel.name content
                    )

                Nothing ->
                    ( model, Cmd.none )

        DeleteFile filename ->
            let
                updatedFiles =
                    Dict.remove filename model.files

                -- Clear selection if deleting the currently selected file
                updatedModel =
                    if model.selectedFilename == Just filename then
                        { model
                            | files = updatedFiles
                            , selectedFilename = Nothing
                            , textInput = ""
                            , name = "new-file"
                            , imageUrl = ""
                            , errorMsg = ""
                        }

                    else
                        { model | files = updatedFiles }
            in
            ( updatedModel, saveFiles (encodeFiles updatedFiles) )

        ImportFile ->
            ( model, Select.file [ "text/plain", ".tikz" ] FileSelected )

        FileSelected file ->
            ( model
            , Task.perform (FileLoaded (File.name file)) (File.toString file)
            )

        FileLoaded filename content ->
            let
                updatedFiles =
                    Dict.insert filename content model.files

                nameWithoutExtension =
                    String.replace ".tikz" "" filename

                updatedModel =
                    { model
                        | files = updatedFiles
                        , selectedFilename = Just filename
                        , textInput = content
                        , name = nameWithoutExtension
                        , requestStartTime = Just model.currentTime
                        , requestElapsedTime = Nothing
                        , imageUrl = ""
                        , errorMsg = ""
                    }
            in
            ( updatedModel
            , Cmd.batch
                [ saveFiles (encodeFiles updatedFiles)
                , Tikz.sendTikzRequest updatedModel.serverUrl nameWithoutExtension content
                ]
            )

        SaveFile ->
            let
                filename =
                    if String.endsWith ".tikz" model.name then
                        model.name

                    else
                        model.name ++ ".tikz"

                updatedFiles =
                    Dict.insert filename model.textInput model.files
            in
            ( { model
                | files = updatedFiles
                , selectedFilename = Just filename
              }
            , Cmd.batch
                [ Download.string filename "text/plain" model.textInput
                , saveFiles (encodeFiles updatedFiles)
                ]
            )

        NewFile ->
            ( { model
                | textInput = ""
                , name = "new-file"
                , imageUrl = ""
                , errorMsg = ""
                , selectedFilename = Nothing
                , requestStartTime = Nothing
                , requestElapsedTime = Nothing
              }
            , Cmd.none
            )

        FilesFromStorage value ->
            let
                filesFromStorage =
                    decodeFiles value

                -- Merge: start with initial files from Data, then overlay localStorage files
                -- This ensures initial files are always present, but localStorage can override them
                mergedFiles =
                    Dict.union filesFromStorage (Dict.fromList Data.tikz)
            in
            ( { model | files = mergedFiles }
            , if Dict.isEmpty filesFromStorage then
                -- First load: save the initial files
                saveFiles (encodeFiles mergedFiles)

              else
                Cmd.none
            )


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus status ->
            "Bad status: " ++ String.fromInt status

        Http.BadBody body ->
            "Bad body: " ++ body


-- PORTS

port saveFiles : Encode.Value -> Cmd msg


port loadFiles : (Encode.Value -> msg) -> Sub msg


-- HELPERS

encodeFiles : Dict String String -> Encode.Value
encodeFiles files =
    files
        |> Dict.toList
        |> List.map (\( k, v ) -> ( k, Encode.string v ))
        |> Encode.object


decodeFiles : Encode.Value -> Dict String String
decodeFiles value =
    case Decode.decodeValue (Decode.dict Decode.string) value of
        Ok files ->
            files

        Err _ ->
            Dict.empty


-- HTTP




encodeTikzRequest : String -> String -> Encode.Value
encodeTikzRequest name content =
    Tikz.jsonForTikzRequest name content




-- VIEW

view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "height" "100vh"
        , style "width" "100vw"
        , style "margin" "0"
        , style "padding" "0"
        ]
        [ filePanel model.files model.selectedFilename
        , middlePanel model.name model.textInput
        , rightPanel model.imageUrl model.errorMsg model.requestStartTime model.currentTime model.requestElapsedTime
        ]


-- FILE PANEL

filePanel : Dict String String -> Maybe String -> Html Msg
filePanel files selectedFilename =
    div
        [ style "width" "200px"
        , style "min-width" "200px"
        , style "padding" "20px"
        , style "border-right" "2px solid #ccc"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "10px"
        , style "background-color" "#fafafa"
        ]
        [ div
            [ style "font-size" "16px"
            , style "font-weight" "bold"
            , style "color" "#333"
            , style "margin-bottom" "10px"
            ]
            [ Html.text "TikZ Files" ]
        , div
            [ style "flex" "1"
            , style "overflow-y" "auto"
            , style "border" "1px solid #ddd"
            , style "border-radius" "4px"
            , style "background-color" "#fff"
            ]
            (files
                |> Dict.keys
                |> List.sort
                |> List.map
                    (\filename ->
                        let
                            isSelected =
                                case selectedFilename of
                                    Just selected ->
                                        selected == filename

                                    Nothing ->
                                        False
                        in
                        div
                            [ onClick (SelectFile filename)
                            , style "padding" "8px 12px"
                            , style "cursor" "pointer"
                            , style "border-bottom" "1px solid #eee"
                            , style "background-color"
                                (if isSelected then
                                    "#e3f2fd"

                                 else
                                    "#fff"
                                )
                            , style "color"
                                (if isSelected then
                                    "#1976d2"

                                 else
                                    "#333"
                                )
                            , style "font-weight"
                                (if isSelected then
                                    "bold"

                                 else
                                    "normal"
                                )
                            , style "display" "flex"
                            , style "justify-content" "space-between"
                            , style "align-items" "center"
                            ]
                            [ span [] [ Html.text filename ]
                            , span
                                [ stopPropagationOn "click" (Decode.succeed ( DeleteFile filename, True ))
                                , style "cursor" "pointer"
                                , style "color" "#999"
                                , style "font-size" "12px"
                                , style "padding" "2px 6px"
                                , style "hover" "color: #d32f2f"
                                ]
                                [ Html.text "×" ]
                            ]
                    )
            )
        , button
            [ onClick NewFile
            , style "padding" "10px"
            , style "background-color" "#616161"
            , style "color" "white"
            , style "border" "none"
            , style "border-radius" "4px"
            , style "cursor" "pointer"
            , style "font-size" "14px"
            ]
            [ Html.text "New File" ]
        , button
            [ onClick ImportFile
            , style "padding" "10px"
            , style "background-color" "#616161"
            , style "color" "white"
            , style "border" "none"
            , style "border-radius" "4px"
            , style "cursor" "pointer"
            , style "font-size" "14px"
            ]
            [ Html.text "Import File" ]
        , button
            [ onClick SaveFile
            , style "padding" "10px"
            , style "background-color" "#616161"
            , style "color" "white"
            , style "border" "none"
            , style "border-radius" "4px"
            , style "cursor" "pointer"
            , style "font-size" "14px"
            ]
            [ Html.text "Save File" ]
        ]


-- MIDDLE PANEL

middlePanel : String -> String -> Html Msg
middlePanel name text =
    div
        [ style "flex" "1"
        , style "padding" "20px"
        , style "border-right" "2px solid #ccc"
        , style "overflow" "hidden"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "10px"
        ]
        [ div
            [ style "font-size" "24px"
            , style "color" "#333"
            , style "text-align" "center"
            , style "margin-bottom" "10px"
            ]
            [ Html.text "TikZ to PNG Converter" ]
        , textarea
            [ style "width" "100%"
            , style "flex" "1"
            , style "resize" "none"
            , style "font-family" "monospace"
            , style "font-size" "14px"
            , style "padding" "10px"
            , style "border" "1px solid #ddd"
            , style "border-radius" "4px"
            , placeholder "Enter TikZ code here..."
            , value text
            , onInput TextChanged
            ]
            []
        , div
            [ style "display" "flex"
            , style "flex-direction" "column"
            , style "gap" "5px"
            ]
            [ label
                [ style "font-size" "14px"
                , style "font-weight" "bold"
                , style "color" "#333"
                ]
                [ Html.text "Name:" ]
            , input
                [ type_ "text"
                , style "padding" "8px"
                , style "border" "1px solid #ddd"
                , style "border-radius" "4px"
                , style "font-size" "14px"
                , placeholder "e.g., tikz-request"
                , value name
                , onInput NameChanged
                ]
                []
            ]
        , button
            [ onClick SendRequest
            , style "padding" "10px 20px"
            , style "background-color" "#616161"
            , style "color" "white"
            , style "border" "none"
            , style "border-radius" "4px"
            , style "cursor" "pointer"
            , style "font-size" "16px"
            ]
            [ Html.text "Render" ]
        ]


rightPanel : String -> String -> Maybe Posix -> Posix -> Maybe Float -> Html Msg
rightPanel imageUrl errorMsg requestStartTime currentTime requestElapsedTime =
    div
        [ style "flex" "1"
        , style "padding" "20px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "background-color" "#f5f5f5"
        , style "flex-direction" "column"
        , style "gap" "20px"
        , style "position" "relative"
        ]
        [ if not (String.isEmpty errorMsg) then
            div
                [ style "color" "#d32f2f"
                , style "font-size" "16px"
                , style "padding" "15px"
                , style "background-color" "#ffebee"
                , style "border" "1px solid #d32f2f"
                , style "border-radius" "4px"
                , style "max-width" "80%"
                ]
                [ Html.text ("Error: " ++ errorMsg) ]
          else if String.isEmpty imageUrl then
            div
                [ style "color" "#999"
                , style "font-size" "18px"
                ]
                [ Html.text "Image will appear here" ]
          else
            img
                [ src imageUrl
                , style "max-width" "100%"
                , style "max-height" "100%"
                , style "object-fit" "contain"
                ]
                []
        , progressIndicator requestStartTime currentTime requestElapsedTime
        ]


-- PROGRESS INDICATOR

progressIndicator : Maybe Posix -> Posix -> Maybe Float -> Html Msg
progressIndicator maybeStartTime currentTime maybeElapsedTime =
    case ( maybeStartTime, maybeElapsedTime ) of
        ( Nothing, Nothing ) ->
            div [] []

        ( _, Just frozenElapsedSeconds ) ->
            -- Request completed, show frozen time
            let
                percentFilled =
                    min 100.0 (frozenElapsedSeconds / 10.0 * 100.0)
            in
            renderProgressBar frozenElapsedSeconds percentFilled

        ( Just startTime, Nothing ) ->
            -- Request in progress, calculate live time
            let
                elapsedMs =
                    Time.posixToMillis currentTime - Time.posixToMillis startTime

                elapsedSeconds =
                    toFloat elapsedMs / 1000.0

                percentFilled =
                    min 100.0 (elapsedSeconds / 10.0 * 100.0)
            in
            renderProgressBar elapsedSeconds percentFilled


renderProgressBar : Float -> Float -> Html Msg
renderProgressBar elapsedSeconds percentFilled =
            div
                [ style "width" "100%"
                , style "padding" "20px"
                , style "position" "absolute"
                , style "bottom" "0"
                , style "left" "0"
                , style "background-color" "#fff"
                , style "border-top" "1px solid #ccc"
                ]
                [ div
                    [ style "text-align" "center"
                    , style "margin-bottom" "10px"
                    , style "font-size" "14px"
                    , style "color" "#666"
                    ]
                    [ Html.text (String.fromFloat (toFloat (round (elapsedSeconds * 10)) / 10) ++ " seconds") ]
                , div
                    [ style "position" "relative"
                    , style "width" "100%"
                    , style "height" "40px"
                    , style "border" "2px solid #333"
                    , style "border-radius" "4px"
                    , style "overflow" "hidden"
                    ]
                    [ -- Filled portion
                      div
                        [ style "position" "absolute"
                        , style "left" "0"
                        , style "top" "0"
                        , style "height" "100%"
                        , style "width" (String.fromFloat percentFilled ++ "%")
                        , style "background-color" "#4CAF50"
                        , style "transition" "width 0.1s linear"
                        ]
                        []
                    , -- Graduation marks
                      div
                        [ style "position" "absolute"
                        , style "left" "0"
                        , style "top" "0"
                        , style "width" "100%"
                        , style "height" "100%"
                        , style "display" "flex"
                        ]
                        (List.range 0 10
                            |> List.map
                                (\i ->
                                    div
                                        [ style "flex" "1"
                                        , style "border-right"
                                            (if i < 10 then
                                                "1px solid #999"

                                             else
                                                "none"
                                            )
                                        , style "position" "relative"
                                        , style "display" "flex"
                                        , style "align-items" "flex-end"
                                        , style "justify-content" "center"
                                        , style "padding-bottom" "2px"
                                        ]
                                        [ div
                                            [ style "font-size" "10px"
                                            , style "color" "#666"
                                            ]
                                            [ Html.text (String.fromInt i) ]
                                        ]
                                )
                        )
                    ]
                ]