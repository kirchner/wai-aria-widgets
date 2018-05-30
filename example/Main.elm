module Main exposing (main)

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

import Browser
import Html exposing (Html)
import Html.Attributes as Attributes
import Listbox exposing (Listbox)
import Listbox.Dropdown as Dropdown exposing (Dropdown)
import Set exposing (Set)


main : Program {} Model Msg
main =
    Browser.embed
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



---- MODEL


type alias Model =
    { selectedLocales : Set String
    , listbox : Listbox
    , selectedLocale : Maybe String
    , dropdown : Dropdown
    }


init _ =
    ( { selectedLocales = Set.empty
      , listbox = Listbox.unfocused
      , selectedLocale = Nothing
      , dropdown = Dropdown.closed
      }
    , Cmd.none
    )



---- UPDATE


type Msg
    = ListboxMsg (Listbox.Msg String)
    | DropdownMsg (Dropdown.Msg String)


type OutMsg
    = EntrySelected String
    | EntryUnselected String


update msg model =
    case Debug.log "msg" msg of
        ListboxMsg listboxMsg ->
            let
                ( newListbox, listboxCmd, maybeOutMsg ) =
                    Listbox.update
                        [ Listbox.onEntrySelect EntrySelected
                        , Listbox.onEntryUnselect EntryUnselected
                        ]
                        model.listbox
                        listboxMsg
            in
            ( { model
                | listbox = newListbox
                , selectedLocales =
                    case maybeOutMsg of
                        Nothing ->
                            model.selectedLocales

                        Just (EntrySelected locale) ->
                            Set.insert locale model.selectedLocales

                        Just (EntryUnselected locale) ->
                            Set.remove locale model.selectedLocales
              }
            , Cmd.map ListboxMsg listboxCmd
            )

        DropdownMsg dropdownMsg ->
            let
                ( newDropdown, dropdownCmd, maybeOutMsg ) =
                    Dropdown.update EntrySelected model.dropdown dropdownMsg
            in
            ( { model
                | dropdown = newDropdown
                , selectedLocale =
                    case maybeOutMsg of
                        Just (EntrySelected locale) ->
                            Just locale

                        _ ->
                            model.selectedLocale
              }
            , Cmd.map DropdownMsg dropdownCmd
            )



---- SUBSCRIPTIONS


subscriptions model =
    Sub.batch
        [ Sub.map ListboxMsg (Listbox.subscriptions model.listbox)
        , Sub.map DropdownMsg (Dropdown.subscriptions model.dropdown)
        ]



---- VIEW


view model =
    Html.section
        [ Attributes.class "section" ]
        [ Html.div
            [ Attributes.class "container" ]
            [ Html.div
                [ Attributes.class "columns" ]
                [ Html.div
                    [ Attributes.class "column" ]
                    [ Html.form []
                        [ Html.div
                            [ Attributes.class "field" ]
                            [ Html.label
                                [ Attributes.id "locales-label" ]
                                [ Html.text "Locale" ]
                            , Html.div
                                [ Attributes.class "control" ]
                                [ model.selectedLocales
                                    |> Set.toList
                                    |> Listbox.viewLazy (\_ -> 42)
                                        listboxConfig
                                        { id = "locales"
                                        , labelledBy = "locales-label"
                                        }
                                        model.listbox
                                        locales
                                    |> Html.map ListboxMsg
                                ]
                            , Html.p
                                [ Attributes.class "help" ]
                                [ Html.text <|
                                    if Set.isEmpty model.selectedLocales then
                                        "nothing selected"
                                    else
                                        "currently selected: "
                                            ++ (model.selectedLocales
                                                    |> Set.toList
                                                    |> String.join ", "
                                               )
                                ]
                            ]
                        ]
                    ]
                , Html.div
                    [ Attributes.class "column" ]
                    [ Html.form []
                        [ Html.div
                            [ Attributes.class "field" ]
                            [ Html.label
                                [ Attributes.id "locales-dropdown-label" ]
                                [ Html.text "Locale" ]
                            , Html.div
                                [ Attributes.class "control" ]
                                [ model.selectedLocale
                                    |> Dropdown.view dropdownConfig
                                        { id = "locales-dropdown"
                                        , labelledBy = "locales-dropdown-label"
                                        }
                                        model.dropdown
                                        locales
                                    |> Html.map DropdownMsg
                                ]
                            , Html.p
                                [ Attributes.class "help" ]
                                [ Html.text <|
                                    case model.selectedLocale of
                                        Nothing ->
                                            "nothing selected"

                                        Just selectedLocale ->
                                            "currently selected: " ++ selectedLocale
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]



---- CONFIG


listboxConfig : Listbox.Config String
listboxConfig =
    { uniqueId = identity
    , behaviour =
        { jumpAtEnds = True
        , separateFocus = True
        , selectionFollowsFocus = False
        , handleHomeAndEnd = True
        , typeAhead =
            Listbox.typeAhead 200 <|
                \query value ->
                    String.toLower value
                        |> String.contains (String.toLower query)
        }
    , view =
        { ul = [ Attributes.class "list" ]
        , li =
            \{ selected, keyboardFocused, mouseFocused, maybeQuery } name ->
                { attributes =
                    [ Attributes.class "entry"
                    , Attributes.classList
                        [ ( "entry--selected", selected )
                        , ( "entry--keyboard-focused", keyboardFocused )
                        , ( "entry--mouse-focused", mouseFocused )
                        ]
                    ]
                , children = liChildren maybeQuery name
                }
        , empty = Html.div [] [ Html.text "this list is empty" ]
        }
    }


dropdownConfig : Dropdown.Config String
dropdownConfig =
    { uniqueId = identity
    , behaviour =
        { jumpAtEnds = True
        , closeAfterMouseSelection = True
        , separateFocus = True
        , selectionFollowsFocus = False
        , handleHomeAndEnd = True
        , typeAhead =
            Listbox.typeAhead 200 <|
                \query value ->
                    String.toLower value
                        |> String.contains (String.toLower query)
        }
    , view =
        { container = []
        , button =
            \{ maybeSelection, open } ->
                { attributes = [ Attributes.class "button" ]
                , children =
                    [ Html.span
                        [ Attributes.style "width" "100%"
                        , Attributes.style "text-align" "left"
                        ]
                        [ maybeSelection
                            |> Maybe.withDefault "Select a locale..."
                            |> Html.text
                        ]
                    ]
                }
        , ul = [ Attributes.class "dropdown-list" ]
        , li =
            \{ selected, keyboardFocused, mouseFocused, maybeQuery } name ->
                { attributes =
                    [ Attributes.class "entry"
                    , Attributes.classList
                        [ ( "entry--selected", selected )
                        , ( "entry--keyboard-focused", keyboardFocused )
                        , ( "entry--mouse-focused", mouseFocused )
                        ]
                    ]
                , children = liChildren maybeQuery name
                }
        }
    }


liChildren : Maybe String -> String -> List (Html Never)
liChildren maybeQuery name =
    case maybeQuery of
        Nothing ->
            [ Html.text name ]

        Just query ->
            let
                queryLength =
                    String.length query
            in
            String.toLower name
                |> String.split (String.toLower query)
                |> List.map String.length
                |> List.foldl
                    (\count ( remainingName, nodes ) ->
                        case remainingName of
                            "" ->
                                ( remainingName, nodes )

                            _ ->
                                ( String.dropLeft (count + queryLength) remainingName
                                , Html.span
                                    [ Attributes.style "color" "#0091eb" ]
                                    [ Html.text (String.left queryLength (String.dropLeft count remainingName)) ]
                                    :: Html.text (String.left count remainingName)
                                    :: nodes
                                )
                    )
                    ( name, [] )
                |> Tuple.second
                |> List.reverse



---- DATA


locales : List String
locales =
    [ "Abkhazian"
    , "Achinese"
    , "Acoli"
    , "Adangme"
    , "Adyghe"
    , "Afar"
    , "Afar, Djibouti"
    , "Afar, Eritrea"
    , "Afar, Ethiopia"
    , "Afar(Ethiopic)"
    , "Afrihili"
    , "Afrikaans"
    , "Afrikaans, Namibia"
    , "Afrikaans, South Africa"
    , "Afro-Asiatic Language"
    , "Ainu"
    , "Ainu(Latin)"
    , "Akan"
    , "Akan, Ghana"
    , "Akkadian"
    , "Albanian"
    , "Albanian, Albania"
    , "Aleut"
    , "Algonquian Language"
    , "Altaic Language"
    , "Amharic"
    , "Amharic, Ethiopia"
    , "Angika"
    , "Apache Language"
    , "Arabic"
    , "Arabic, Algeria"
    , "Arabic(Perso-Arabic)"
    , "Arabic, Bahrain"
    , "Arabic, Egypt"
    , "Arabic, Iraq"
    , "Arabic, Jordan"
    , "Arabic, Kuwait"
    , "Arabic, Lebanon"
    , "Arabic, Libya"
    , "Arabic, Morocco"
    , "Arabic, Oman"
    , "Arabic, Qatar"
    , "Arabic, Saudi Arabia"
    , "Arabic, Sudan"
    , "Arabic, Syria"
    , "Arabic, Tunisia"
    , "Arabic, United Arab Emirates"
    , "Arabic, Yemen"
    , "Aragonese"
    , "Arapaho"
    , "Araucanian"
    , "Arawak"
    , "Armenian"
    , "Armenian, Armenia"
    , "Aromanian"
    , "Aromanian(Greek)"
    , "Aromanian(Latin)"
    , "Artificial Language"
    , "Assamese"
    , "Assamese, India"
    , "Asturian"
    , "Athapascan Language"
    , "Atsam"
    , "Atsam, Nigeria"
    , "Australian Language"
    , "Austronesian Language"
    , "Avaric"
    , "Avestan"
    , "Awadhi"
    , "Aymara"
    , "Azeri"
    , "Azeri(Perso-Arabic)"
    , "Azeri, Azerbaijan"
    , "Azeri, Azerbaijan(Cyrillic)"
    , "Azeri, Azerbaijan(Latin)"
    , "Azeri(Cyrillic)"
    , "Azeri(Latin)"
    , "Azeri, Iran"
    , "Azeri, Iran(Perso-Arabic)"
    , "Balinese"
    , "Baltic Language"
    , "Baluchi"
    , "Baluchi(Perso-Arabic)"
    , "Bambara"
    , "Bamileke Language"
    , "Banda"
    , "Bantu"
    , "Basa"
    , "Bashkir"
    , "Basque"
    , "Basque, France"
    , "Basque, Spain"
    , "Batak"
    , "Beja"
    , "Belarusian"
    , "Belarusian, Belarus"
    , "Belarusian(Cyrillic)"
    , "Belarusian(Latin)"
    , "Bemba"
    , "bengali"
    , "bengali, bangladesh"
    , "Bengali, India"
    , "Berber"
    , "Bhojpuri"
    , "Bihari"
    , "Bikol"
    , "Bini"
    , "Bislama"
    , "Blin"
    , "Blin, Eritrea"
    , "Blissymbols"
    , "Bosnian"
    , "Bosnian, Bosnia and Herzegovina"
    , "Braj"
    , "Breton"
    , "Buginese"
    , "Bulgarian"
    , "Bulgarian, Bulgaria"
    , "Buriat"
    , "Burmese"
    , "Burmese, Myanmar [Burma]"
    , "Caddo"
    , "Carib"
    , "Catalan"
    , "Catalan, Spain"
    , "Caucasian Language"
    , "Cebuano"
    , "Celtic Language"
    , "Central American Indian Language"
    , "Khmer"
    , "Khmer, Cambodia"
    , "Chamic Language"
    , "Chamic Language(Perso-Arabic)"
    , "Chamorro"
    , "Chechen"
    , "Cherokee"
    , "Cheyenne"
    , "Nyanja"
    , "Nyanja, Malawi"
    , "Chinese"
    , "Chinese, China"
    , "Chinese, China(Simplified Han)"
    , "Chinese, Hong Kong"
    , "Chinese, Hong Kong(Simplified Han)"
    , "Chinese, Hong Kong(Traditional Han)"
    , "Chinese, Macau"
    , "Chinese, Macau(Simplified Han)"
    , "Chinese, Macau(Traditional Han)"
    , "Chinese(Simplified Han)"
    , "Chinese, Singapore"
    , "Chinese, Singapore(Simplified Han)"
    , "Chinese, Taiwan"
    , "Chinese, Taiwan(Traditional Han)"
    , "Chinese(Traditional Han)"
    , "Chinook Jargon"
    , "Chipewyan"
    , "Choctaw"
    , "Church Slavic"
    , "Chuukese"
    , "Chuvash"
    , "Cornish"
    , "Cornish, United Kingdom"
    , "Corsican"
    , "Cree"
    , "Creek"
    , "Creole or Pidgin"
    , "Crimean Turkish"
    , "Crimean Turkish(Cyrillic)"
    , "Crimean Turkish(Latin)"
    , "Croatian"
    , "Croatian, Croatia"
    , "Cushitic Language"
    , "Czech"
    , "Czech, Czech Republic"
    , "Dakota"
    , "Danish"
    , "Danish, Denmark"
    , "Dargwa"
    , "Dayak"
    , "Delaware"
    , "Dinka"
    , "Divehi"
    , "Divehi, Maldives"
    , "Divehi(Thaana)"
    , "Dogri"
    , "Dogrib"
    , "Dravidian Language"
    , "Duala"
    , "Dutch"
    , "Dutch, Belgium"
    , "Dutch, Netherlands"
    , "Dyula"
    , "Dzongkha"
    , "Dzongkha, Bhutan"
    , "Eastern Frisian"
    , "Efik"
    , "Ekajuk"
    , "English"
    , "English, American Samoa"
    , "English, Australia"
    , "English-based Creole or Pidgin"
    , "English, Belgium"
    , "English, Belize"
    , "English, Botswana"
    , "English, Canada"
    , "English(Deseret)"
    , "English, Guam"
    , "English, Hong Kong"
    , "English, India"
    , "English, Ireland"
    , "English, Israel"
    , "English, Jamaica"
    , "English, Malta"
    , "English, Marshall Islands"
    , "English, Namibia"
    , "English, New Zealand"
    , "English, Northern Mariana Islands"
    , "English, Pakistan"
    , "English, Philippines"
    , "English(Shavian)"
    , "English, Singapore"
    , "English, South Africa"
    , "English, Trinidad and Tobago"
    , "English, United Kingdom"
    , "English, United States"
    , "English, United States(Deseret)"
    , "English, U.S. Minor Outlying Islands"
    , "English, U.S. Virgin Islands"
    , "English, Zimbabwe"
    , "Erzya"
    , "Esperanto"
    , "Estonian"
    , "Estonian, Estonia"
    , "Ewe"
    , "Ewe, Ghana"
    , "Ewe, Togo"
    , "Ewondo"
    , "Fang"
    , "Fanti"
    , "Faroese"
    , "Faroese, Faroe Islands"
    , "Fijian"
    , "Filipino"
    , "Filipino, Philippines"
    , "Finnish"
    , "Finnish, Finland"
    , "Finno-Ugrian Language"
    , "Fon"
    , "French"
    , "French-based Creole or Pidgin"
    , "French, Belgium"
    , "French, Canada"
    , "French, France"
    , "French, Luxembourg"
    , "French, Monaco"
    , "French, Senegal"
    , "French, Switzerland"
    , "French, Morocco"
    , "Friulian"
    , "Friulian, Italy"
    , "Fulah"
    , "Fulah(Perso-Arabic)"
    , "Fulah(Latin)"
    , "Ga"
    , "Scottish Gaelic"
    , "Ga, Ghana"
    , "Galician"
    , "Galician, Spain"
    , "Ganda"
    , "Gayo"
    , "Gbaya"
    , "Geez"
    , "Geez, Eritrea"
    , "Geez, Ethiopia"
    , "Georgian"
    , "Georgian, Georgia"
    , "German"
    , "German, Austria"
    , "German, Belgium"
    , "German, Germany"
    , "Germanic Language"
    , "German, Liechtenstein"
    , "German, Luxembourg"
    , "German, Switzerland"
    , "Gilbertese"
    , "Gondi"
    , "Gorontalo"
    , "Grebo"
    , "Greek"
    , "Greek, Cyprus"
    , "Greek, Greece"
    , "Guarani"
    , "Gujarati"
    , "Gujarati, India"
    , "Gwichʼin"
    , "Haida"
    , "Haitian"
    , "Hausa"
    , "Hausa(Perso-Arabic)"
    , "Hausa, Ghana"
    , "Hausa, Ghana(Latin)"
    , "Hausa(Latin)"
    , "Hausa, Niger"
    , "Hausa, Nigeria"
    , "Hausa, Nigeria(Perso-Arabic)"
    , "Hausa, Nigeria(Latin)"
    , "Hausa, Niger(Latin)"
    , "Hausa, Sudan"
    , "Hausa, Sudan(Perso-Arabic)"
    , "Hawaiian"
    , "Hawaiian, United States"
    , "Hebrew"
    , "Hebrew(Hebrew)"
    , "Hebrew, Israel"
    , "Herero"
    , "Hiligaynon"
    , "Himachali"
    , "Hindi"
    , "Hindi, India"
    , "Hiri Motu"
    , "Hittite"
    , "Hmong"
    , "Hungarian"
    , "Hungarian, Hungary"
    , "Hupa"
    , "Iban"
    , "Icelandic"
    , "Icelandic, Iceland"
    , "Ido"
    , "Igbo"
    , "Igbo, Nigeria"
    , "Ijo"
    , "Iloko"
    , "Inari Sami"
    , "Indic Language"
    , "Indo-European Language"
    , "Indonesian"
    , "Indonesian(Perso-Arabic)"
    , "Indonesian, Indonesia"
    , "Indonesian, Indonesia(Perso-Arabic)"
    , "Ingush"
    , "Interlingua"
    , "Interlingue"
    , "Inuktitut"
    , "Inuktitut, Canada"
    , "Inupiaq"
    , "Iranian Language"
    , "Irish"
    , "Irish, Ireland"
    , "Iroquoian Language"
    , "Italian"
    , "Italian, Italy"
    , "Italian, Switzerland"
    , "Japanese"
    , "Japanese, Japan"
    , "Javanese"
    , "Javanese(Javanese)"
    , "Javanese(Latin)"
    , "Judeo-Arabic"
    , "Judeo-Persian"
    , "Kabardian"
    , "Kabyle"
    , "Kachin"
    , "Kalaallisut"
    , "Kalaallisut, Greenland"
    , "Kalmyk"
    , "Kalmyk(Cyrillic)"
    , "Kalmyk(Mongolian)"
    , "Kamba"
    , "Kamba, Kenya"
    , "Kannada"
    , "Kannada, India"
    , "Kanuri"
    , "Karachay-Balkar"
    , "Kara-Kalpak"
    , "Karelian"
    , "Karen"
    , "Kashmiri"
    , "Kashmiri(Perso-Arabic)"
    , "Kashmiri(Devanagari)"
    , "Kashmiri(Latin)"
    , "Kashubian"
    , "Kawi"
    , "Kazakh"
    , "Kazakh(Perso-Arabic)"
    , "Kazakh(Cyrillic)"
    , "Kazakh, Kazakhstan"
    , "Kazakh, Kazakhstan(Perso-Arabic)"
    , "Kazakh, Kazakhstan(Cyrillic)"
    , "Kazakh, Kazakhstan(Latin)"
    , "Kazakh(Latin)"
    , "Khasi"
    , "Khoisan Language"
    , "Khotanese"
    , "Kikuyu"
    , "Kimbundu"
    , "Kinyarwanda"
    , "Kinyarwanda, Rwanda"
    , "Kirghiz(Cyrillic)"
    , "Kirghiz"
    , "Kirghiz(Perso-Arabic)"
    , "Kirghiz, Kyrgyzstan"
    , "Kirghiz(Latin)"
    , "Klingon"
    , "Komi"
    , "Kongo"
    , "Konkani"
    , "Konkani, India"
    , "Konkani, India(Kannada)"
    , "Konkani, India(Latin)"
    , "Konkani, India(Malayalam)"
    , "Konkani(Kannada)"
    , "Konkani(Latin)"
    , "Konkani(Malayalam)"
    , "Korean"
    , "Korean, South Korea"
    , "Koro"
    , "Koro, Ivory Coast"
    , "Kosraean"
    , "Kpelle"
    , "Kpelle, Guinea"
    , "Kpelle, Liberia"
    , "Kru"
    , "Kuanyama"
    , "Kumyk"
    , "Kurdish"
    , "Kurdish(Perso-Arabic)"
    , "Kurdish, Iran"
    , "Kurdish, Iran(Perso-Arabic)"
    , "Kurdish, Iraq"
    , "Kurdish, Iraq(Perso-Arabic)"
    , "Kurdish(Latin)"
    , "Kurdish, Syria"
    , "Kurdish, Syria(Perso-Arabic)"
    , "Kurdish, Turkey"
    , "Kurdish, Turkey(Latin)"
    , "Kurukh"
    , "Kutenai"
    , "Ladino"
    , "Ladino(Hebrew)"
    , "Ladino(Latin)"
    , "Lahnda"
    , "Lamba"
    , "Lao"
    , "Lao, Laos"
    , "Latin"
    , "Latvian"
    , "Latvian, Latvia"
    , "Lezghian"
    , "Limburgish"
    , "Lingala"
    , "Lingala, Congo [Republic]"
    , "Lingala, Congo [DRC]"
    , "Lithuanian"
    , "Lithuanian, Lithuania"
    , "Lojban"
    , "Lower Sorbian"
    , "Low German"
    , "Low German, Germany"
    , "Lozi"
    , "Luba-Katanga"
    , "Luba-Lulua"
    , "Luiseno"
    , "Lule Sami"
    , "Lunda"
    , "Luo"
    , "Lushai"
    , "Luxembourgish"
    , "Macedonian"
    , "Macedonian, Macedonia [FYROM]"
    , "Madurese"
    , "Magahi"
    , "Maithili"
    , "Makasar"
    , "Makasar(Buginese)"
    , "Makasar(Latin)"
    , "Malagasy"
    , "Malay"
    , "Malayalam"
    , "Malayalam(Perso-Arabic)"
    , "Malayalam, India"
    , "Malayalam, India(Perso-Arabic)"
    , "Malayalam, India(Malayalam)"
    , "Malayalam(Malayalam)"
    , "Malay(Perso-Arabic)"
    , "Malay, Brunei"
    , "Malay, Brunei(Latin)"
    , "Malay(Latin)"
    , "Malay, Malaysia"
    , "Malay, Malaysia(Latin)"
    , "Maltese"
    , "Maltese, Malta"
    , "Manchu"
    , "Mandar"
    , "Mandingo"
    , "Manipuri"
    , "Manobo Language"
    , "Manx"
    , "Manx, United Kingdom"
    , "Maori"
    , "Marathi"
    , "Marathi, India"
    , "Mari"
    , "Marshallese"
    , "Marwari"
    , "Masai"
    , "Mayan Language"
    , "Mende"
    , "Micmac"
    , "Minangkabau"
    , "Mirandese"
    , "Mohawk"
    , "Moksha"
    , "Moldavian"
    , "Moldavian, Moldova"
    , "Mongo"
    , "Mongolian"
    , "Mongolian, China"
    , "Mongolian, China(Mongolian)"
    , "Mongolian(Cyrillic)"
    , "Mongolian, Mongolia"
    , "Mongolian, Mongolia(Cyrillic)"
    , "Mongolian(Mongolian)"
    , "Mon-Khmer Language"
    , "Mossi"
    , "Multiple Languages"
    , "Munda Language"
    , "Nahuatl"
    , "Nauru"
    , "Navajo"
    , "North Ndebele"
    , "South Ndebele"
    , "South Ndebele, South Africa"
    , "Ndonga"
    , "Neapolitan"
    , "Newari"
    , "Nepali"
    , "Nepali, India"
    , "Nepali, Nepal"
    , "Nias"
    , "Niger-Kordofanian Language"
    , "Nilo-Saharan Language"
    , "Niuean"
    , "N’Ko"
    , "Nogai"
    , "No linguistic content"
    , "North American Indian Language"
    , "Northern Frisian"
    , "Northern Sami"
    , "Northern Sami, Finland"
    , "Northern Sami, Norway"
    , "Norwegian Bokmål"
    , "Norwegian Bokmål, Norway"
    , "Norwegian Nynorsk"
    , "Norwegian Nynorsk, Norway"
    , "Nubian Language"
    , "Nyamwezi"
    , "Nyankole"
    , "Nyoro"
    , "Nzima"
    , "Occitan"
    , "Occitan, France"
    , "Ojibwa"
    , "Oriya"
    , "Oriya, India"
    , "Oromo"
    , "Oromo, Ethiopia"
    , "Oromo, Kenya"
    , "Osage"
    , "Ossetic"
    , "Ossetic(Cyrillic)"
    , "Ossetic(Latin)"
    , "Otomian Language"
    , "Pahlavi"
    , "Palauan"
    , "Pali"
    , "Pali(Devanagari)"
    , "Pali(Sinhala)"
    , "Pali(Thai)"
    , "Pampanga"
    , "Pampanga, India"
    , "Pangasinan"
    , "Punjabi(Perso-Arabic)"
    , "Punjabi(Devanagari)"
    , "Punjabi(Gurmukhi)"
    , "Punjabi, India(Devanagari)"
    , "Punjabi, India(Gurmukhi)"
    , "Punjabi, Pakistan(Perso-Arabic)"
    , "Punjabi, Pakistan(Devanagari)"
    , "Papiamento"
    , "Papuan Language"
    , "Northern Sotho"
    , "Northern Sotho, South Africa"
    , "Persian"
    , "Persian, Afghanistan"
    , "Persian(Perso-Arabic)"
    , "Persian(Cyrillic)"
    , "Persian, Iran"
    , "Philippine Language"
    , "Pohnpeian"
    , "Polish"
    , "Polish, Poland"
    , "Portuguese"
    , "Portuguese-based Creole or Pidgin"
    , "Portuguese, Brazil"
    , "Portuguese, Portugal"
    , "Prakrit Language"
    , "Punjabi"
    , "Punjabi, Pakistan"
    , "Pushto"
    , "Pushto, Afghanistan"
    , "Pushto(Perso-Arabic)"
    , "Quechua"
    , "Rajasthani"
    , "Rajasthani(Perso-Arabic)"
    , "Rajasthani(Devanagari)"
    , "Rapanui"
    , "Rarotongan"
    , "Romance Language"
    , "Romanian"
    , "Romanian, Moldova"
    , "Romanian, Romania"
    , "Romansh"
    , "Romany"
    , "Rundi"
    , "Russian"
    , "Russian, Russia"
    , "Russian, Ukraine"
    , "Russian, Kazakhstan"
    , "Salishan Language"
    , "Samaritan Aramaic"
    , "Samaritan Aramaic(Syriac)"
    , "Sami Language"
    , "Samoan"
    , "Sandawe"
    , "Sango"
    , "Sanskrit"
    , "Sanskrit, India"
    , "Santali"
    , "Santali(Bengali)"
    , "Santali(Devanagari)"
    , "Santali(Latin)"
    , "Santali(Oriya)"
    , "Sardinian"
    , "Sasak"
    , "Scots"
    , "Selkup"
    , "Semitic Language"
    , "Serbian"
    , "Serbian, Bosnia and Herzegovina"
    , "Serbian, Bosnia and Herzegovina(Cyrillic)"
    , "Serbian, Bosnia and Herzegovina(Latin)"
    , "Serbian(Cyrillic)"
    , "Serbian(Latin)"
    , "Serbian, Montenegro"
    , "Serbian, Montenegro(Cyrillic)"
    , "Serbian, Montenegro(Latin)"
    , "Serbian, Serbia"
    , "Serbian, Serbia and Montenegro"
    , "Serbian, Serbia and Montenegro(Cyrillic)"
    , "Serbian, Serbia and Montenegro(Latin)"
    , "Serbian, Serbia(Cyrillic)"
    , "Serbian, Serbia(Latin)"
    , "Serbo-Croatian"
    , "Serbo-Croatian, Bosnia and Herzegovina"
    , "Serbo-Croatian, Montenegro"
    , "Serbo-Croatian, Serbia and Montenegro"
    , "Serer"
    , "Serer(Perso-Arabic)"
    , "Serer(Latin)"
    , "Shan"
    , "Shona"
    , "Sichuan Yi"
    , "Sichuan Yi, China"
    , "Sichuan Yi, China(Yi)"
    , "Sichuan Yi(Yi)"
    , "Sicilian"
    , "Sidamo"
    , "Sidamo, Ethiopia"
    , "Sidamo(Ethiopic)"
    , "Sidamo(Latin)"
    , "Sign Language"
    , "Siksika"
    , "Sindhi"
    , "Sindhi(Perso-Arabic)"
    , "Sindhi(Devanagari)"
    , "Sindhi(Gurmukhi)"
    , "Sinhala"
    , "Sinhala, Sri Lanka"
    , "Sino-Tibetan Language"
    , "Siouan Language"
    , "Skolt Sami"
    , "Slave"
    , "Slavic Language"
    , "Slovak"
    , "Slovak, Slovakia"
    , "Slovenian"
    , "Slovenian, Slovenia"
    , "Sogdien"
    , "Somali"
    , "Somali(Perso-Arabic)"
    , "Somali, Djibouti"
    , "Somali, Ethiopia"
    , "Somali, Kenya"
    , "Somali, Somalia"
    , "Songhai"
    , "Soninke"
    , "Soninke(Perso-Arabic)"
    , "Soninke(Latin)"
    , "Sorbian Language"
    , "Southern Sotho"
    , "Southern Sotho, Lesotho"
    , "Southern Sotho, South Africa"
    , "South American Indian Language"
    , "Southern Altai"
    , "Southern Sami"
    , "Spanish"
    , "Spanish, Argentina"
    , "Spanish, Bolivia"
    , "Spanish, Chile"
    , "Spanish, Colombia"
    , "Spanish, Costa Rica"
    , "Spanish, Dominican Republic"
    , "Spanish, Ecuador"
    , "Spanish, El Salvador"
    , "Spanish, Guatemala"
    , "Spanish, Honduras"
    , "Spanish, Mexico"
    , "Spanish, Nicaragua"
    , "Spanish, Panama"
    , "Spanish, Paraguay"
    , "Spanish, Peru"
    , "Spanish, Puerto Rico"
    , "Spanish, Spain"
    , "Spanish, United States"
    , "Spanish, Uruguay"
    , "Spanish, Venezuela"
    , "Sranan Tongo"
    , "Sukuma"
    , "Sumerian"
    , "Sundanese"
    , "Sundanese(Perso-Arabic)"
    , "Sundanese(Javanese)"
    , "Sundanese(Latin)"
    , "Susu"
    , "Susu(Perso-Arabic)"
    , "Susu(Latin)"
    , "Swahili"
    , "Swahili, Kenya"
    , "Swahili, Tanzania"
    , "Swati"
    , "Swati, South Africa"
    , "Swati, Swaziland"
    , "Swedish"
    , "Swedish, Finland"
    , "Swedish, Sweden"
    , "Swiss German"
    , "Swiss German, Switzerland"
    , "Syriac"
    , "Syriac(Cyrillic)"
    , "Syriac, Syria"
    , "Syriac(Syriac)"
    , "Syriac, Syria(Cyrillic)"
    , "Tagalog"
    , "Tahitian"
    , "Tai Language"
    , "Tajik"
    , "Tajik(Perso-Arabic)"
    , "Tajik(Cyrillic)"
    , "Tajik(Latin)"
    , "Tajik, Tajikistan"
    , "Tajik, Tajikistan(Perso-Arabic)"
    , "Tajik, Tajikistan(Cyrillic)"
    , "Tajik, Tajikistan(Latin)"
    , "Tamashek"
    , "Tamashek(Perso-Arabic)"
    , "Tamashek(Latin)"
    , "Tamashek(Tifinagh)"
    , "Tamil"
    , "Tamil, India"
    , "Tatar"
    , "Tatar(Cyrillic)"
    , "Tatar(Latin)"
    , "Tatar, Russia"
    , "Tatar, Russia(Cyrillic)"
    , "Tatar, Russia(Latin)"
    , "Telugu"
    , "Telugu, India"
    , "Tereno"
    , "Tetum"
    , "Thai"
    , "Thai, Thailand"
    , "Tibetan"
    , "Tibetan, China"
    , "Tibetan, India"
    , "Tigre"
    , "Tigre, Eritrea"
    , "Tigrinya"
    , "Tigrinya, Eritrea"
    , "Tigrinya, Ethiopia"
    , "Timne"
    , "Tiv"
    , "Tlingit"
    , "Tokelau"
    , "Tok Pisin"
    , "Nyasa Tonga"
    , "Nyasa Tonga, Tonga"
    , "Tonga"
    , "Tsimshian"
    , "Tsimshian, South Africa"
    , "Tsonga"
    , "Tswana"
    , "Tswana, South Africa"
    , "Tumbuka"
    , "Tupi Language"
    , "Turkish"
    , "Turkish, Turkey"
    , "Turkmen"
    , "Turkmen(Perso-Arabic)"
    , "Turkmen(Cyrillic)"
    , "Turkmen(Latin)"
    , "Tuvalu"
    , "Tuvinian"
    , "Twi"
    , "Tyap"
    , "Tyap, Nigeria"
    , "Udmurt"
    , "Udmurt(Cyrillic)"
    , "Udmurt(Latin)"
    , "Ugaritic"
    , "Uyghur"
    , "Uyghur(Perso-Arabic)"
    , "Uyghur, China"
    , "Uyghur, China(Perso-Arabic)"
    , "Uyghur, China(Cyrillic)"
    , "Uyghur, China(Latin)"
    , "Uyghur(Cyrillic)"
    , "Uyghur(Latin)"
    , "Ukrainian"
    , "Ukrainian, Ukraine"
    , "Umbundu"
    , "Miscellaneous Language"
    , "Unknown Language"
    , "Upper Sorbian"
    , "Urdu"
    , "Urdu(Perso-Arabic)"
    , "Urdu, India"
    , "Urdu, Pakistan"
    , "Uzbek"
    , "Uzbek, Afghanistan"
    , "Uzbek, Afghanistan(Perso-Arabic)"
    , "Uzbek(Perso-Arabic)"
    , "Uzbek(Cyrillic)"
    , "Uzbek(Latin)"
    , "Uzbek, Uzbekistan"
    , "Uzbek, Uzbekistan(Cyrillic)"
    , "Uzbek, Uzbekistan(Latin)"
    , "Vai"
    , "Venda"
    , "Venda, South Africa"
    , "Vietnamese"
    , "Vietnamese, Vietnam"
    , "Volapük"
    , "Votic"
    , "Wakashan Language"
    , "Walamo"
    , "Walamo, Ethiopia"
    , "Walloon"
    , "Waray"
    , "Washo"
    , "Welsh"
    , "Welsh, United Kingdom"
    , "Western Frisian"
    , "Wolof"
    , "Wolof(Perso-Arabic)"
    , "Wolof(Latin)"
    , "Wolof, Senegal"
    , "Wolof, Senegal(Perso-Arabic)"
    , "Wolof, Senegal(Latin)"
    , "Xhosa"
    , "Xhosa, South Africa"
    , "Yakut"
    , "Yao"
    , "Yapese"
    , "Yiddish"
    , "Yiddish(Hebrew)"
    , "Yoruba"
    , "Yoruba, Nigeria"
    , "Yupik Language"
    , "Zande"
    , "Zapotec"
    , "Zaza"
    , "Zenaga"
    , "Zhuang"
    , "Zulu"
    , "Zulu, South Africa"
    , "Zuni"
    ]
