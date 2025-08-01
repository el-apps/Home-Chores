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
         , viewInput "text" "Name" model.name Name
         , viewInput "password" "Password" model.password Password
         , viewInput "password" "Re-enter Password" model.confirmPassword ConfirmPassword
         ]
            ++ (if model.password /= model.confirmPassword then
                    [ p [] [ text "Passwords do not match!" ] ]

                else
                    []
               )
        )


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg ] []
