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
    = Increment
    | Decrement
    | Reset
    | UpdateText String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            { model | count = model.count + 1 }

        Decrement ->
            { model | count = model.count - 1 }

        Reset ->
            { model | count = 0 }

        UpdateText newText ->
            { model | text = newText }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (String.fromInt model.count) ]
        , button [ onClick Increment ] [ text "+" ]
        , button [ onClick Reset ] [ text "reset!" ]
        , input [ placeholder "Text to reverse", value model.text, onInput UpdateText ] []
        , div [] [ text (String.reverse model.text) ]
        ]
