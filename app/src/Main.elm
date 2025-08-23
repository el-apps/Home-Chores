port module Main exposing (..)

import Browser
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Time



-- MAIN


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }



-- PORTS


port newEvent : Value -> Cmd msg


port onNewHistory : (Value -> msg) -> Sub msg


port receiveCurrentTime : (Int -> msg) -> Sub msg



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
    , choreCreated : Dict String Int
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( Model [] [] (Time.millisToPosix 0) Dict.empty
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

        step event ( items, completionsAccumulator, createdDict ) =
            case event.action of
                "addChore" ->
                    ( Dict.update event.itemUuid
                        (\maybe -> Just (Maybe.withDefault Dict.empty maybe))
                        items
                    , completionsAccumulator
                    , Dict.insert event.itemUuid (Time.posixToMillis event.timestamp) createdDict
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
                            , createdDict
                            )

                        Err _ ->
                            Debug.log ("failed to decode updateChore payload: " ++ event.payload) ( items, completionsAccumulator, createdDict )

                "completeChore" ->
                    ( items
                    , { choreUuid = event.itemUuid, timestamp = event.timestamp } :: completionsAccumulator
                    , createdDict
                    )

                _ ->
                    Debug.log ("unknown event action: " ++ event.action) ( items, completionsAccumulator, createdDict )

        ( choresDict, completions, createdDict ) =
            List.foldl step ( Dict.empty, [], Dict.empty ) sorted

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
    , choreCreated = createdDict
    }



-- UPDATE


type Msg
    = NewHistory Value
    | AddChore Chore
    | AddChoreClicked
    | ToggleComplete String
    | TickTime Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewHistory value ->
            case Decode.decodeValue eventsDecoder value of
                Ok events ->
                    ( buildModelFromEvents model.currentTime events, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        TickTime nowMillis ->
            ( { model | currentTime = Time.millisToPosix nowMillis }, Cmd.none )

        AddChore _ ->
            -- TODO: add chore
            ( model, Cmd.none )

        AddChoreClicked ->
            ( model
            , newEvent
                (Encode.object
                    [ ( "userUuid", Encode.string "me" )
                    , ( "action", Encode.string "addChore" )
                    , ( "payload", Encode.object [] )
                    ]
                )
            )

        ToggleComplete choreUuid ->
            ( model
            , newEvent
                (Encode.object
                    [ ( "userUuid", Encode.string "me" )
                    , ( "itemUuid", Encode.string choreUuid )
                    , ( "action", Encode.string "completeChore" )
                    , ( "payload", Encode.object [ ( "timestamp", model.currentTime |> Time.posixToMillis |> Encode.int ) ] )
                    ]
                )
            )



-- VIEW


view : Model -> Html Msg
view model =
    node "main"
        [ class "container" ]
        [ nav []
            [ ul []
                [ h1 [] [ text "Chores" ]
                , button [ onClick AddChoreClicked ] [ text "Add" ]
                ]
            ]
        , ul []
            (List.map (viewChore model.currentTime model.choreCompletions) (sortChores model))
        ]


viewChore : Time.Posix -> List ChoreCompletion -> Chore -> Html Msg
viewChore currentTime completions chore =
    let
        completed =
            isCompleted currentTime completions chore

        -- normalize a chore into a common uuid, title and optional subtitle
        ( choreUuid, title, maybeSubtitle ) =
            case chore of
                RepeatedWeekly { uuid, name, day } ->
                    ( uuid, name, Just ("Weekly - " ++ dayName day) )

                OneTime { uuid, name } ->
                    ( uuid, name, Nothing )

        statusCheckbox =
            input [ type_ "checkbox", checked completed, onClick (ToggleComplete choreUuid) ] []
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



-- helper: sort chores by completion (incomplete first) then by creation timestamp

sortChores : Model -> List Chore
sortChores model =
    let
        getUuid chore =
            case chore of
                RepeatedWeekly { uuid } ->
                    uuid

                OneTime { uuid } ->
                    uuid

        completionScore chore =
            if isCompleted model.currentTime model.choreCompletions chore then
                1
            else
                0

        compareChores a b =
            let
                scoreA =
                    completionScore a

                scoreB =
                    completionScore b

                createdA =
                    Dict.get (getUuid a) model.choreCreated |> Maybe.withDefault 0

                createdB =
                    Dict.get (getUuid b) model.choreCreated |> Maybe.withDefault 0
            in
            case Basics.compare scoreA scoreB of
                EQ ->
                    Basics.compare createdA createdB

                other ->
                    other
    in
    List.sortWith compareChores model.chores


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onNewHistory NewHistory
        , receiveCurrentTime TickTime
        ]
