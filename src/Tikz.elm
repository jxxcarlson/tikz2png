module Tikz exposing ( jsonForTikzRequest)

{-| Convert a LaTeX document to JSON format for the /tikz2png endpoint.

Example usage:

    input = """
    \\documentclass[varwidth,border=5]{standalone}
    \\usepackage{tikz}
    \\usetikzlibrary{lindenmayersystems}
    ...preamble...
    \\begin{document}
    ...content...
    \\end{document}
    """

    latexToTikzJson "fractal" input
    -- Returns: JSON string ready for the /tikz2png endpoint

-}

import Json.Encode as Encode


type alias TikzRequest =
    { name : String
    , preamble : Maybe String
    , content : String
    }

jsonForTikzRequest : String -> String -> Encode.Value
jsonForTikzRequest name document =
    parseLatexDocument name document
        |> encodeTikzRequest

encodeTikzRequest : TikzRequest -> Encode.Value
encodeTikzRequest tikzRequest =
    Encode.object
        [ ( "name", Encode.string tikzRequest.name )
        , ( "content", Encode.string tikzRequest.content )
        , ( "preamble"
          , case tikzRequest.preamble of
                Nothing ->
                    Encode.null

                Just p ->
                    Encode.string p
          )
        ]


{-| Encode TikzRequest to JSON string.
-}
encodeTikzRequestStr : TikzRequest -> String
encodeTikzRequestStr request =
    let
        fields =
            [ Just ( "name", Encode.string request.name )
            , Just ( "content", Encode.string request.content )
            , Maybe.map (\p -> ( "preamble", Encode.string p )) request.preamble
            ]
                |> List.filterMap identity
    in
    Encode.object fields
        |> Encode.encode 2


{-| Parse a LaTeX document into preamble and content sections.
-}
parseLatexDocument : String -> String -> TikzRequest
parseLatexDocument name document =
    let
        -- Find \begin{document}
        beginDoc =
            "\\begin{document}"

        endDoc =
            "\\end{document}"
    in
    -- Check if this is a full LaTeX document or just raw TikZ code
    if String.contains beginDoc document then
        -- Full LaTeX document - parse it
        let
            -- Split on \begin{document}
            parts =
                String.split beginDoc document

            beforeBegin =
                List.head parts |> Maybe.withDefault ""

            afterBegin =
                parts
                    |> List.drop 1
                    |> String.join beginDoc

            -- Extract content (between \begin{document} and \end{document})
            content =
                afterBegin
                    |> String.split endDoc
                    |> List.head
                    |> Maybe.withDefault ""
                    |> String.trim

            -- Extract preamble (after \documentclass line, before \begin{document})
            preamble =
                extractPreamble beforeBegin
        in
        { name = name
        , preamble = preamble
        , content = content
        }

    else
        -- Raw TikZ code - treat entire input as content
        { name = name
        , preamble = Nothing
        , content = String.trim document
        }


{-| Extract preamble from the part before \begin{document}.
Skip the \documentclass line and take everything after it.
-}
extractPreamble : String -> Maybe String
extractPreamble beforeBegin =
    let
        lines =
            String.lines beforeBegin

        -- Find the first line that starts with \documentclass
        dropDocumentClass =
            lines
                |> List.indexedMap Tuple.pair
                |> List.filter (\( _, line ) -> String.startsWith "\\documentclass" (String.trim line))
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.map (\idx -> List.drop (idx + 1) lines)
                |> Maybe.withDefault lines

        preambleText =
            dropDocumentClass
                |> String.join "\n"
                |> String.trim
    in
    if String.isEmpty preambleText then
        Nothing

    else
        Just preambleText





{-| Example usage with the fractal document.
-}
exampleFractal : String
exampleFractal =
    """\\documentclass[varwidth,border=5]{standalone}
\\usepackage{tikz}
\\usetikzlibrary{lindenmayersystems}
\\pgfdeclarelindenmayersystem{square fractal}{%
  \\symbol{S}{\\pgflsystemstep=0.5\\pgflsystemstep}
  \\symbol{A}{\\pgftransformshift%
    {\\pgfqpoint{0.75\\pgflsystemstep}{0.75\\pgflsystemstep}}}
  \\symbol{R}{\\pgftransformrotate{90}}
  \\symbol{Q}{%
    \\pgfpathrectangle{\\pgfqpoint{-0.5\\pgflsystemstep}{-0.5\\pgflsystemstep}}%
    {\\pgfqpoint{\\pgflsystemstep}{\\pgflsystemstep}}%
  }
  \\rule{Q -> [SQ[ASQ][RASQ][RRASQ][RRRASQ]]}
}
\\begin{document}
\\foreach\\i in {0,...,5}{%
\\tikz\\fill [l-system={square fractal, step=5cm, axiom=Q, order=\\i}]
  lindenmayer system;
\\ifodd\\i\\par\\bigskip\\leavevmode\\fi
}
\\end{document}"""

