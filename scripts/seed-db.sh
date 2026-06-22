#!/usr/bin/env bash

set -u

API_URL="${API_URL:-http://localhost:5011}"
POST_COUNT="${POST_COUNT:-1000}"

if ! [[ "$POST_COUNT" =~ ^[0-9]+$ ]] || ((POST_COUNT < 1 || POST_COUNT > 1000)); then
    echo "POST_COUNT must be an integer between 1 and 1000." >&2
    exit 1
fi

first_names=(
    "Maya" "Jonah" "Elena" "Theo" "Nadia" "Silas" "Iris" "Caleb"
    "Amara" "Felix" "Leah" "Owen" "Priya" "Miles" "Celia" "Elias"
    "Zara" "Noah" "Lena" "Isaac" "Sofia" "Julian" "Avery" "Mateo"
    "Nora" "Darius" "Maeve" "Adrian" "Camille" "Ronan" "Talia" "Micah"
)

last_names=(
    "Bennett" "Mercer" "Vasquez" "Callahan" "Brooks" "Monroe" "Holloway" "Winters"
    "Okafor" "Navarro" "Sato" "Hartwell" "Desai" "Rowan" "Beaumont" "Park"
    "Whitaker" "Ellison" "Moreau" "Bell" "Marin" "Cross" "Sinclair" "Rivers"
    "Kessler" "Cole" "Sullivan" "Morrow" "Laurent" "Keane" "Farrell" "Quinn"
)

title_adjectives=(
    "Silent" "Hidden" "Distant" "Golden" "Restless" "Midnight"
    "Forgotten" "Crimson" "Wandering" "Last" "Glass" "Paper"
)

title_nouns=(
    "Harbor" "Compass" "Orchard" "Lantern" "Horizon" "Archive"
    "Bridge" "Garden" "Signal" "Map" "Voyage" "Clock"
)

places=(
    "an abandoned railway station" "a rain-soaked harbor" "a quiet mountain village"
    "a library beneath the city" "a lighthouse at the edge of the sea"
    "an overgrown glasshouse" "a crowded midnight market" "a cabin beside a frozen lake"
)

discoveries=(
    "a letter addressed to someone who had never existed"
    "a brass key warm from an unseen hand"
    "a map whose roads changed every morning"
    "a clock that counted backward only during storms"
    "a photograph showing tomorrow's sunrise"
    "a notebook filled with conversations yet to happen"
)

companions=(
    "a patient stray dog" "an old cartographer" "a musician with a broken violin"
    "a child carrying a red umbrella" "a gardener who spoke in riddles"
    "a sailor who claimed to remember the future"
)

obstacles=(
    "the river rose and erased the road home"
    "every clock in town stopped at once"
    "a sudden fog swallowed all familiar landmarks"
    "the bridge vanished before sunset"
    "the town began forgetting its own name"
    "a fierce storm cut the power across the valley"
)

endings=(
    "By dawn, the mystery was solved, but the answer changed everything"
    "They returned home carrying only a story no one else believed"
    "When morning arrived, the impossible path had disappeared"
    "At sunrise, they chose a new road and never looked back"
    "The secret remained safe, waiting for the next curious traveler"
    "In the end, what they found mattered less than whom they had become"
)

tags=("adventure" "fiction" "mystery" "history" "travel" "nature" "reflection" "technology")

# Build 1,024 unique first-name/last-name combinations, then shuffle their
# indexes so each run selects a different set and ordering of authors.
authors=()
for first_name in "${first_names[@]}"; do
    for last_name in "${last_names[@]}"; do
        authors+=("$first_name $last_name")
    done
done

author_indexes=()
for ((i = 0; i < ${#authors[@]}; i++)); do
    author_indexes+=("$i")
done

for ((i = ${#author_indexes[@]} - 1; i > 0; i--)); do
    j=$((RANDOM % (i + 1)))
    temporary=${author_indexes[$i]}
    author_indexes[$i]=${author_indexes[$j]}
    author_indexes[$j]=$temporary
done

echo "Seeding $POST_COUNT posts at $API_URL/posts"

for ((i = 0; i < POST_COUNT; i++)); do
    if ((POST_COUNT == 1)); then
        year=2000
    else
        year=$((2000 + (i * 26 / (POST_COUNT - 1))))
    fi

    month=$((1 + RANDOM % 12))
    day=$((1 + RANDOM % 28))
    published=$(printf "%04d-%02d-%02dT%02d:%02d:00" "$year" "$month" "$day" "$((8 + RANDOM % 12))" "$((RANDOM % 60))")

    author=${authors[${author_indexes[$i]}]}
    title="${title_adjectives[$((RANDOM % ${#title_adjectives[@]}))]} ${title_nouns[$((RANDOM % ${#title_nouns[@]}))]} $((i + 1))"
    place=${places[$((RANDOM % ${#places[@]}))]}
    discovery=${discoveries[$((RANDOM % ${#discoveries[@]}))]}
    companion=${companions[$((RANDOM % ${#companions[@]}))]}
    obstacle=${obstacles[$((RANDOM % ${#obstacles[@]}))]}
    ending=${endings[$((RANDOM % ${#endings[@]}))]}
    content="A traveler arrived at $place just before dusk. There, they discovered $discovery. With help from $companion, they followed a trail that led beyond the town. Before they could turn back, $obstacle. $ending."

    first_tag=${tags[$((RANDOM % ${#tags[@]}))]}
    second_tag=${tags[$((RANDOM % ${#tags[@]}))]}
    while [[ "$second_tag" == "$first_tag" ]]; do
        second_tag=${tags[$((RANDOM % ${#tags[@]}))]}
    done

    payload=$(printf \
        '{"author":"%s","content":"%s","description":null,"published":"%s","summary":null,"tags":["%s","%s"],"title":"%s"}' \
        "$author" "$content" "$published" "$first_tag" "$second_tag" "$title")

    response_file=$(mktemp)
    status=$(curl --silent --show-error \
        --output "$response_file" \
        --write-out "%{http_code}" \
        --header "Content-Type: application/json" \
        --data "$payload" \
        "$API_URL/posts")
    curl_exit=$?

    if ((curl_exit != 0)); then
        rm -f "$response_file"
        echo "Request $((i + 1)) failed: could not reach the API." >&2
        exit "$curl_exit"
    fi

    if [[ "$status" != "201" ]]; then
        echo "Request $((i + 1)) failed with HTTP $status:" >&2
        cat "$response_file" >&2
        echo >&2
        rm -f "$response_file"
        exit 1
    fi

    rm -f "$response_file"
    echo "[$((i + 1))/$POST_COUNT] $published | $author | $title"
done

echo "Seed complete."

