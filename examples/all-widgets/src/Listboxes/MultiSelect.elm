module Listboxes.MultiSelect
    exposing
        ( Model
        , Msg
        , init
        , subscriptions
        , update
        , view
        )

{-

   Copyright 2018 Fabian Kirchner

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

-}

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Json.Decode as Decode
import Set exposing (Set)
import Widget.Listbox as Listbox exposing (Listbox)


type alias Model =
    { availableListbox : Listbox
    , available : List String
    , selectedAvailable : Set String
    , chosenListbox : Listbox
    , chosen : List String
    , selectedChosen : Set String
    }


init : Model
init =
    { availableListbox = Listbox.init
    , available =
        [ "Leather seats"
        , "Front seat warmers"
        , "Rear bucket seats"
        , "Rear seat warmers"
        , "Front sun roof"
        , "Rear sun roof"
        , "Privacy cloque"
        , "Food synthesizer"
        , "Advanced waste recycling system"
        , "Turbo vertical take-off capability"
        ]
    , selectedAvailable = Set.empty
    , chosenListbox = Listbox.init
    , chosen = []
    , selectedChosen = Set.empty
    }



---- UPDATE


type Msg
    = NoOp
    | AvailableListboxMsg (Listbox.Msg String)
    | AddClicked
    | ChosenListboxMsg (Listbox.Msg String)
    | RemoveClicked


type OutMsg
    = EntrySelected String
    | EntriesSelected (List String)
    | AllEntriesSelected
    | EntryUnselected String
    | AllEntriesUnselected


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        AvailableListboxMsg listboxMsg ->
            let
                ( newListbox, listboxCmd, newSelection ) =
                    Listbox.update updateConfig
                        (List.map Listbox.option model.available)
                        listboxMsg
                        model.availableListbox
                        (Set.toList model.selectedAvailable)
            in
            ( { model
                | availableListbox = newListbox
                , selectedAvailable = Set.fromList newSelection
              }
            , Cmd.map AvailableListboxMsg listboxCmd
            )

        AddClicked ->
            ( { model
                | available =
                    model.selectedAvailable
                        |> Set.diff (Set.fromList model.available)
                        |> Set.toList
                , selectedAvailable = Set.empty
                , chosen =
                    model.chosen ++ Set.toList model.selectedAvailable
              }
            , Cmd.none
            )

        ChosenListboxMsg listboxMsg ->
            let
                ( newListbox, listboxCmd, newSelection ) =
                    Listbox.update updateConfig
                        (List.map Listbox.option model.chosen)
                        listboxMsg
                        model.chosenListbox
                        (Set.toList model.selectedChosen)
            in
            ( { model
                | chosenListbox = newListbox
                , selectedChosen = Set.fromList newSelection
              }
            , Cmd.map ChosenListboxMsg listboxCmd
            )

        RemoveClicked ->
            ( { model
                | available = model.available ++ Set.toList model.selectedChosen
                , selectedChosen = Set.empty
                , chosen =
                    model.selectedChosen
                        |> Set.diff (Set.fromList model.chosen)
                        |> Set.toList
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map AvailableListboxMsg (Listbox.subscriptions model.availableListbox)
        , Sub.map ChosenListboxMsg (Listbox.subscriptions model.chosenListbox)
        ]



---- VIEW


view : Model -> Html Msg
view model =
    let
        availableEntries =
            List.map Listbox.option model.available

        chosenEntries =
            List.map Listbox.option model.chosen
    in
    Html.div
        [ Attributes.class "columns" ]
        [ Html.div
            [ Attributes.class "column" ]
            [ Html.div
                [ Attributes.class "field" ]
                [ Html.label
                    [ Attributes.class "label"
                    , Attributes.id "available-label"
                    ]
                    [ Html.text "Available upgrades:" ]
                , Html.div
                    [ Attributes.class "control" ]
                    [ Listbox.customView
                        viewConfig
                        { id = "available-listbox"
                        , labelledBy = "available-label"
                        , lift = AvailableListboxMsg
                        , onKeyDown =
                            Decode.field "key" Decode.string
                                |> Decode.andThen
                                    (\code ->
                                        case code of
                                            "Enter" ->
                                                Decode.succeed AddClicked

                                            _ ->
                                                Decode.fail "not handling that key here"
                                    )
                        , onMouseDown = Decode.fail "not handling this event here"
                        , onMouseUp = Decode.fail "not handling this event here"
                        , onBlur = Decode.fail "not handling this event here"
                        }
                        availableEntries
                        model.availableListbox
                        (Set.toList model.selectedAvailable)
                    ]
                ]
            , Html.div
                [ Attributes.class "field"
                , Attributes.class "is-grouped"
                ]
                [ Html.div
                    [ Attributes.class "control" ]
                    [ Html.button
                        [ Attributes.class "button"
                        , Attributes.disabled (Set.isEmpty model.selectedAvailable)
                        , Events.onClick AddClicked
                        , Attributes.attribute "aria-keyshortcuts" "Enter"
                        , Attributes.attribute "aria-disabled" <|
                            boolToString (Set.isEmpty model.selectedAvailable)
                        ]
                        [ Html.span []
                            [ Html.text "Add " ]
                        , Html.span
                            [ Attributes.class "icon"
                            , Attributes.class "is-small"
                            , Attributes.style "font-size" "12px"
                            ]
                            [ Html.i
                                [ Attributes.class "fas"
                                , Attributes.class "fa-arrow-right"
                                ]
                                []
                            ]
                        ]
                    ]
                ]
            ]
        , Html.div
            [ Attributes.class "column" ]
            [ Html.div
                [ Attributes.class "field" ]
                [ Html.label
                    [ Attributes.class "label"
                    , Attributes.id "chosen-label"
                    ]
                    [ Html.text "Upgrades you have chosen:" ]
                , Html.div
                    [ Attributes.class "control" ]
                    [ Listbox.customView
                        viewConfig
                        { id = "chosen-listbox"
                        , labelledBy = "chosen-label"
                        , lift = ChosenListboxMsg
                        , onKeyDown =
                            Decode.field "key" Decode.string
                                |> Decode.andThen
                                    (\code ->
                                        case code of
                                            "Delete" ->
                                                Decode.succeed RemoveClicked

                                            _ ->
                                                Decode.fail "not handling that key here"
                                    )
                        , onMouseDown = Decode.fail "not handling this event here"
                        , onMouseUp = Decode.fail "not handling this event here"
                        , onBlur = Decode.fail "not handling this event here"
                        }
                        chosenEntries
                        model.chosenListbox
                        (Set.toList model.selectedChosen)
                    ]
                ]
            , Html.div
                [ Attributes.class "field"
                , Attributes.class "is-grouped"
                ]
                [ Html.div
                    [ Attributes.class "control" ]
                    [ Html.button
                        [ Attributes.class "button"
                        , Attributes.disabled (Set.isEmpty model.selectedChosen)
                        , Events.onClick RemoveClicked
                        , Attributes.attribute "aria-keyshortcuts" "Delete"
                        , Attributes.attribute "aria-disabled" <|
                            boolToString (Set.isEmpty model.selectedChosen)
                        ]
                        [ Html.span
                            [ Attributes.class "icon"
                            , Attributes.class "is-small"
                            , Attributes.style "font-size" "12px"
                            ]
                            [ Html.i
                                [ Attributes.class "fas"
                                , Attributes.class "fa-arrow-left"
                                ]
                                []
                            ]
                        , Html.span []
                            [ Html.text " Remove" ]
                        ]
                    ]
                ]
            ]
        ]



---- CONFIGURATION


updateConfig : Listbox.UpdateConfig String
updateConfig =
    Listbox.updateConfig identity
        { jumpAtEnds = True
        , separateFocus = True
        , selectionFollowsFocus = False
        , handleHomeAndEnd = True
        , typeAhead = Listbox.noTypeAhead
        , minimalGap = 0
        , initialGap = 0
        }


viewConfig : Listbox.ViewConfig String Never
viewConfig =
    Listbox.viewConfig identity
        { ul = [ Attributes.class "list" ]
        , liOption =
            \{ selected, keyboardFocused, mouseFocused, maybeQuery } name ->
                { attributes =
                    [ Attributes.class "entry"
                    , Attributes.classList
                        [ ( "entry--keyboard-focused", keyboardFocused )
                        , ( "entry--mouse-focused", mouseFocused )
                        ]
                    ]
                , children =
                    [ Html.span
                        [ Attributes.class "icon"
                        , Attributes.class "is-small"
                        , Attributes.style "margin-right" "5px"
                        , Attributes.style "font-size" "12px"
                        , Attributes.style "width" "16px"
                        ]
                        [ if selected then
                            Html.i
                                [ Attributes.class "fas"
                                , Attributes.class "fa-check"
                                ]
                                []
                          else
                            Html.text ""
                        ]
                    , Html.text name
                    ]
                }
        , liDivider = Listbox.noDivider
        , empty = Html.div [] [ Html.text "this list is empty" ]
        , focusable = True
        }



---- HELPER


boolToString : Bool -> String
boolToString b =
    if b then
        "true"
    else
        "false"
