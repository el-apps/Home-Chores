module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, h2, input, node, p, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Time



-- MAIN


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type Chore
    = RepeatedWeekly
        { uuid : String
        , name : String
        , day : Time.Weekday
        }


type alias ChoreCompletion =
    { choreUuid : String
    , timestamp : Time.Posix
    }


type alias Model =
    { name : String
    , password : String
    , confirmPassword : String
    , chores : List Chore
    }


init : Model
init =
    Model ""
        ""
        ""
        [ RepeatedWeekly { uuid = "c892a6cb-cfbc-4d05-8888-28b54f0ffe90", name = "Implement add chore", day = Time.Mon }
        , RepeatedWeekly { uuid = "228a6965-28e2-4026-b6a9-6c0cc4a57026", name = "Implement complete chore", day = Time.Tue }
        ]



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
    node "main"
        []
        [ div []
            (h2 [] [ text "Chores" ]
                :: List.map viewChore model.chores
            )
        ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg ] []


viewValidation : Model -> Html msg
viewValidation model =
    if model.password /= model.confirmPassword then
        p [] [ text "Passwords do not match!" ]

    else
        Html.text ""


viewChore : Chore -> Html msg
viewChore chore =
    case chore of
        RepeatedWeekly { name } ->
            p [] [ text ("Chore: " ++ name) ]
