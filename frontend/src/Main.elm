module Main exposing (..)

import Browser
import Html exposing (Html, button, div, h1, input, p, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)



-- MAIN


main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model =
    { name : String
    , password : String
    , confirmPassword : String
    }


init : Model
init =
    Model "" "" ""



-- UPDATE


type Msg
    = Name String
    | Password String
    | ConfirmPassword String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Name newName ->
            { model | name = newName }

        Password newPassword ->
            { model | password = newPassword }

        ConfirmPassword newConfirmPassword ->
            { model | confirmPassword = newConfirmPassword }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        ([ h1 [] [ text "Login" ]
         , input [ value model.name, onInput Name ] []
         , input [ value model.password, type_ "password", onInput Password ] []
         , input [ value model.confirmPassword, type_ "password", onInput ConfirmPassword ] []
         ]
            ++ (if model.password /= model.confirmPassword then
                    [ p [] [ text "Passwords do not match!" ] ]

                else
                    []
               )
        )
