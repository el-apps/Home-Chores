module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
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
    { chores : List Chore
    , completedChores : List ChoreCompletion
    }


init : Model
init =
    Model
        [ RepeatedWeekly { uuid = "c892a6cb-cfbc-4d05-8888-28b54f0ffe90", name = "Implement add chore", day = Time.Mon }
        , RepeatedWeekly { uuid = "228a6965-28e2-4026-b6a9-6c0cc4a57026", name = "Implement complete chore", day = Time.Tue }
        ]
        []



-- UPDATE


type Msg
    = AddChore Chore


update : Msg -> Model -> Model
update msg model =
    case msg of
        AddChore _ ->
            model



-- VIEW


view : Model -> Html Msg
view model =
    node "main"
        []
        [ div []
            (h1 [] [ text "Chores" ]
                :: List.map viewChore model.chores
            )
        ]


viewChore : Chore -> Html msg
viewChore chore =
    case chore of
        RepeatedWeekly { name, day } ->
            article []
                [ header []
                    [ h2 [] [ text name ]
                    , text ("Weekly - " ++ dayName day)
                    ]
                , text "Needs Done"

                -- TODO: add button to mark chore done
                ]


dayName : Time.Weekday -> String
dayName day =
    case day of
        Time.Mon ->
            "Monday"

        Time.Tue ->
            "Tuesday"

        Time.Wed ->
            "Wednesday"

        Time.Thu ->
            "Thursday"

        Time.Fri ->
            "Friday"

        Time.Sat ->
            "Saturday"

        Time.Sun ->
            "Sunday"
