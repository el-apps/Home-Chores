port module Main exposing (..)

import Browser
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Value)
import Time



-- MAIN


main : Program Int Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }



-- PORTS


port newEvent : Value -> Cmd msg


port onNewHistory : (Value -> msg) -> Sub msg



-- MODEL


type alias Event =
    { uuid : String
    , timestamp : Time.Posix
    , userUuid : String
    , itemUuid : String
    , action : String
    , payload : String
    }


type Chore
    = RepeatedWeekly
        { uuid : String
        , name : String
        , day : Time.Weekday
        }
    | OneTime
        { uuid : String
        , name : String
        }


type alias ChoreCompletion =
    { choreUuid : String
    , timestamp : Time.Posix
    }


type alias Model =
    { chores : List Chore
    , choreCompletions : List ChoreCompletion
    , currentTime : Time.Posix
    }


init : Int -> ( Model, Cmd Msg )
init nowMillis =
    let
        nowPosix =
            Time.millisToPosix nowMillis
    in
    ( Model [] [] nowPosix
    , Cmd.none
    )


defaultChoreName : String
defaultChoreName =
    "New Chore"


defaultChoreDay : Time.Weekday
defaultChoreDay =
    Time.Mon



-- DECODERS


eventsDecoder : Decode.Decoder (List Event)
eventsDecoder =
    Decode.list eventDecoder


eventDecoder : Decode.Decoder Event
eventDecoder =
    Decode.map6
        (\uuid ts user item action payload ->
            { uuid = uuid
            , timestamp = Time.millisToPosix ts
            , userUuid = user
            , itemUuid = item
            , action = action
            , payload = payload
            }
        )
        (Decode.field "uuid" Decode.string)
        (Decode.field "timestamp" Decode.int)
        (Decode.field "userUuid" Decode.string)
        (Decode.field "itemUuid" Decode.string)
        (Decode.field "action" Decode.string)
        (Decode.field "payload" Decode.string)


updatePayloadDecoder : Decode.Decoder ( String, String )
updatePayloadDecoder =
    Decode.map2 Tuple.pair
        (Decode.field "field" Decode.string)
        (Decode.field "value" Decode.string)


completePayloadDecoder : Decode.Decoder Time.Posix
completePayloadDecoder =
    Decode.field "timestamp" Decode.int
        |> Decode.map Time.millisToPosix


weekdayFromString : String -> Maybe Time.Weekday
weekdayFromString s =
    case s of
        "Mon" ->
            Just Time.Mon

        "Tue" ->
            Just Time.Tue

        "Wed" ->
            Just Time.Wed

        "Thu" ->
            Just Time.Thu

        "Fri" ->
            Just Time.Fri

        "Sat" ->
            Just Time.Sat

        "Sun" ->
            Just Time.Sun

        _ ->
            Nothing


buildModelFromEvents : Time.Posix -> List Event -> Model
buildModelFromEvents currentTime events =
    let
        sorted =
            List.sortBy (\e -> Time.posixToMillis e.timestamp) events

        step event ( items, completionsAccumulator ) =
            case event.action of
                "addChore" ->
                    ( Dict.update event.itemUuid
                        (\maybe -> Just (Maybe.withDefault Dict.empty maybe))
                        items
                    , completionsAccumulator
                    )

                "updateChore" ->
                    case Decode.decodeString updatePayloadDecoder event.payload of
                        Ok ( field, value ) ->
                            ( Dict.update event.itemUuid
                                (\maybeAttrs ->
                                    let
                                        attrs =
                                            Maybe.withDefault Dict.empty maybeAttrs
                                    in
                                    Just (Dict.insert field value attrs)
                                )
                                items
                            , completionsAccumulator
                            )

                        Err _ ->
                            ( items, completionsAccumulator )

                "completeChore" ->
                    case Decode.decodeString completePayloadDecoder event.payload of
                        Ok ts ->
                            ( items
                            , { choreUuid = event.itemUuid, timestamp = ts } :: completionsAccumulator
                            )

                        Err _ ->
                            ( items, completionsAccumulator )

                _ ->
                    ( items, completionsAccumulator )

        ( choresDict, completions ) =
            List.foldl step ( Dict.empty, [] ) sorted

        toChore ( uuid, attrs ) =
            case Dict.get "type" attrs of
                Just "repeated_weekly" ->
                    let
                        name =
                            Maybe.withDefault defaultChoreName (Dict.get "name" attrs)

                        day =
                            Dict.get "day" attrs
                                |> Maybe.andThen weekdayFromString
                                |> Maybe.withDefault defaultChoreDay
                    in
                    Just (RepeatedWeekly { uuid = uuid, name = name, day = day })

                _ ->
                    let
                        name =
                            Maybe.withDefault defaultChoreName (Dict.get "name" attrs)
                    in
                    Just (OneTime { uuid = uuid, name = name })
    in
    { chores = choresDict |> Dict.toList |> List.filterMap toChore
    , choreCompletions = List.reverse completions
    , currentTime = currentTime
    }



-- UPDATE


type Msg
    = NewHistory Value
    | AddChore Chore


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewHistory value ->
            case Decode.decodeValue eventsDecoder value of
                Ok events ->
                    ( buildModelFromEvents model.currentTime events, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        AddChore _ ->
            -- TODO: add chore
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    node "main"
        [ class "container" ]
        [ nav [] [ ul [] [ h1 [] [ text "Chores" ] ] ]
        , ul []
            (List.map (viewChore model.currentTime model.choreCompletions) model.chores)
        ]


viewChore : Time.Posix -> List ChoreCompletion -> Chore -> Html msg
viewChore currentTime completions chore =
    let
        completed =
            isCompleted currentTime completions chore

        -- normalize a chore into a common title and optional subtitle
        ( title, maybeSubtitle ) =
            case chore of
                RepeatedWeekly { name, day } ->
                    ( name, Just ("Weekly - " ++ dayName day) )

                OneTime { name } ->
                    ( name, Nothing )

        statusCheckbox =
            input [ type_ "checkbox", checked completed ] []
    in
    div [ class "chore" ]
        [ label []
            [ statusCheckbox
            , div [ class "content" ]
                [ div [ class "title" ] [ text title ]
                , case maybeSubtitle of
                    Just s ->
                        div [ class "subtitle" ] [ text s ]

                    Nothing ->
                        text ""
                ]
            ]
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


weekMillis : Int
weekMillis =
    7 * 24 * 60 * 60 * 1000


dayMillis : Int
dayMillis =
    24 * 60 * 60 * 1000



-- 1970-01-01 was a Thursday; using Mon=0..Sun=6 so Thu == 3


epochWeekdayIndex : Int
epochWeekdayIndex =
    3


maxCompletionMillis : List ChoreCompletion -> Int
maxCompletionMillis completions =
    List.foldl (\c acc -> Basics.max acc (Time.posixToMillis c.timestamp)) 0 completions


weekdayToIndex : Time.Weekday -> Int
weekdayToIndex wd =
    case wd of
        Time.Mon ->
            0

        Time.Tue ->
            1

        Time.Wed ->
            2

        Time.Thu ->
            3

        Time.Fri ->
            4

        Time.Sat ->
            5

        Time.Sun ->
            6


isWeeklyCompleted : Time.Posix -> List ChoreCompletion -> String -> Time.Weekday -> Bool
isWeeklyCompleted currentTime completions choreUuid day =
    let
        currentMs =
            Time.posixToMillis currentTime

        -- number of days since epoch at currentMs
        dayCount =
            Basics.truncate (toFloat currentMs / toFloat dayMillis)

        -- weekday index for the day corresponding to currentMs (Mon=0..Sun=6)
        currentDayIndex =
            Basics.modBy 7 (epochWeekdayIndex + dayCount)

        targetIndex =
            weekdayToIndex day

        diff =
            currentDayIndex - targetIndex

        daysSince =
            if diff < 0 then
                diff + 7

            else
                diff

        cutoff =
            currentMs - (daysSince * dayMillis)
    in
    List.any (\c -> c.choreUuid == choreUuid && Time.posixToMillis c.timestamp >= cutoff) completions


isOneTimeCompleted : List ChoreCompletion -> String -> Bool
isOneTimeCompleted completions choreUuid =
    List.any (\c -> c.choreUuid == choreUuid) completions


isCompleted : Time.Posix -> List ChoreCompletion -> Chore -> Bool
isCompleted currentTime completions chore =
    case chore of
        RepeatedWeekly { uuid, day } ->
            isWeeklyCompleted currentTime completions uuid day

        OneTime { uuid } ->
            isOneTimeCompleted completions uuid



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    onNewHistory NewHistory
