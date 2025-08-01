module Main exposing (..)

import Browser
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


-- MAIN


main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model =
    { count : Int, text : String }


init : Model
init =
    { count = 314, text = "" }



-- UPDATE


type Msg
    = UpdateCount Int
    | Reset
    | UpdateText String


update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdateCount delta ->
            { model | count = model.count + delta }

        Reset ->
            { model | count = 0 }

        UpdateText newText ->
            { model | text = newText }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick (UpdateCount -1) ] [ text "-" ]
        , div [] [ text (String.fromInt model.count) ]
        , button [ onClick (UpdateCount 1) ] [ text "+" ]
        , button [ onClick Reset ] [ text "reset!" ]
        , input [ placeholder "Text to reverse", value model.text, onInput UpdateText ] []
        , div [] [ text (String.reverse model.text) ]
        ]
