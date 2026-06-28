#!/usr/bin/env bash

set -u

API_URL="${API_URL:-http://localhost:5011}"
DEFAULT_POST_COUNT="${POST_COUNT:-1000}"

if (($# > 1)); then
    echo "Usage: $0 [post_count]" >&2
    echo "You can also set POST_COUNT and API_URL as environment variables." >&2
    exit 1
fi

POST_COUNT="${1:-$DEFAULT_POST_COUNT}"

if ! [[ "$POST_COUNT" =~ ^[0-9]+$ ]] || ((POST_COUNT < 1)); then
    echo "POST_COUNT must be a positive integer." >&2
    exit 1
fi

START_YEAR=2000
END_YEAR=2026
MINUTES_PER_DAY=1440

is_leap_year() {
    local year=$1

    if (((year % 400 == 0) || (year % 4 == 0 && year % 100 != 0))); then
        return 0
    fi

    return 1
}

days_in_year() {
    local year=$1

    if is_leap_year "$year"; then
        echo 366
    else
        echo 365
    fi
}

TOTAL_DAYS=0
for ((year = START_YEAR; year <= END_YEAR; year++)); do
    TOTAL_DAYS=$((TOTAL_DAYS + $(days_in_year "$year")))
done

format_published_date() {
    local index=$1
    local post_count=$2
    local year

    if ((post_count == 1)); then
        printf "%04d-01-01T08:00:00" "$START_YEAR"
        return
    fi

    local total_minutes=$((TOTAL_DAYS * MINUTES_PER_DAY - 1))
    local minute_offset=$((index * total_minutes / (post_count - 1)))
    local day_offset=$((minute_offset / MINUTES_PER_DAY))
    local minute_of_day=$((minute_offset % MINUTES_PER_DAY))
    local hour=$((minute_of_day / 60))
    local minute=$((minute_of_day % 60))

    for ((year = START_YEAR; year <= END_YEAR; year++)); do
        local year_days
        year_days=$(days_in_year "$year")

        if ((day_offset < year_days)); then
            break
        fi

        day_offset=$((day_offset - year_days))
    done

    local month_lengths=(31 28 31 30 31 30 31 31 30 31 30 31)
    if is_leap_year "$year"; then
        month_lengths[1]=29
    fi

    local month=1
    local month_index
    for ((month_index = 0; month_index < 12; month_index++)); do
        if ((day_offset < month_lengths[month_index])); then
            month=$((month_index + 1))
            break
        fi

        day_offset=$((day_offset - month_lengths[month_index]))
    done

    local day=$((day_offset + 1))

    printf "%04d-%02d-%02dT%02d:%02d:00" "$year" "$month" "$day" "$hour" "$minute"
}

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

echo "Seeding $POST_COUNT posts at $API_URL/posts with dates from $START_YEAR through $END_YEAR"

for ((i = 0; i < POST_COUNT; i++)); do
    published=$(format_published_date "$i" "$POST_COUNT")

    author=${authors[${author_indexes[$((i % ${#author_indexes[@]}))]}]}
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
