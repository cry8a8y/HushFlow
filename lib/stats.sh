#!/bin/bash
# HushFlow stats — session statistics and streak tracking
# Usage: hushflow stats

STATS_DIR="$HOME/.hushflow"
STATS_FILE="$STATS_DIR/stats.log"

# TSV format: timestamp\tcycles\tduration_seconds\texercise\tanimation\ttheme

if [ ! -f "$STATS_FILE" ] || [ ! -s "$STATS_FILE" ]; then
    echo "HushFlow Stats"
    echo "=============="
    echo ""
    echo "  No sessions recorded yet."
    echo "  Start a breathing session and stats will appear here."
    exit 0
fi

# Get current date info
TODAY=$(date +%Y-%m-%d)
WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null || echo "")

# Calculate streak (consecutive days with at least one session)
get_streak() {
    local dates
    dates=$(awk -F'\t' '{
        ts=$1
        cmd="date -d @" ts " +%Y-%m-%d 2>/dev/null || date -r " ts " +%Y-%m-%d 2>/dev/null"
        cmd | getline d
        close(cmd)
        if (d != "") print d
    }' "$STATS_FILE" | sort -u | tail -30)

    if [ -z "$dates" ]; then
        echo 0
        return
    fi

    local streak=0
    local check_date="$TODAY"
    while true; do
        if echo "$dates" | grep -q "^${check_date}$"; then
            streak=$((streak + 1))
            # Go back one day
            if [[ "$OSTYPE" == darwin* ]]; then
                check_date=$(date -j -v-${streak}d +%Y-%m-%d 2>/dev/null || break)
            else
                check_date=$(date -d "$TODAY - ${streak} days" +%Y-%m-%d 2>/dev/null || break)
            fi
        else
            break
        fi
    done
    echo "$streak"
}

# Parse stats with awk
read_stats() {
    local period="$1"  # "today", "week", "all"
    local now
    now=$(date +%s)
    local day_start week_start

    if [[ "$OSTYPE" == darwin* ]]; then
        day_start=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TODAY 00:00:00" +%s 2>/dev/null || echo 0)
        if [ -n "$WEEK_AGO" ]; then
            week_start=$(date -j -f "%Y-%m-%d %H:%M:%S" "$WEEK_AGO 00:00:00" +%s 2>/dev/null || echo 0)
        else
            week_start=0
        fi
    else
        day_start=$(date -d "$TODAY 00:00:00" +%s 2>/dev/null || echo 0)
        if [ -n "$WEEK_AGO" ]; then
            week_start=$(date -d "$WEEK_AGO 00:00:00" +%s 2>/dev/null || echo 0)
        else
            week_start=0
        fi
    fi

    awk -F'\t' -v period="$period" -v day_start="$day_start" -v week_start="$week_start" '
    {
        ts=$1; cycles=$2; dur=$3; exercise=$4; anim=$5
        if (period == "today" && ts < day_start) next
        if (period == "week" && ts < week_start) next
        total_sessions++
        total_cycles += cycles
        total_dur += dur
        ex_count[exercise]++
        anim_count[anim]++
    }
    END {
        if (total_sessions == 0) {
            print "sessions=0"
            exit
        }
        print "sessions=" total_sessions
        print "cycles=" total_cycles
        print "duration=" total_dur

        # Find most used exercise
        max_ex_count=0; max_ex=""
        for (e in ex_count) {
            if (ex_count[e] > max_ex_count) { max_ex_count=ex_count[e]; max_ex=e }
        }
        print "fav_exercise=" max_ex

        # Find most used animation
        max_anim_count=0; max_anim=""
        for (a in anim_count) {
            if (anim_count[a] > max_anim_count) { max_anim_count=anim_count[a]; max_anim=a }
        }
        print "fav_animation=" max_anim
    }
    ' "$STATS_FILE"
}

format_duration() {
    local secs=$1
    if [ "$secs" -ge 3600 ]; then
        echo "$((secs / 3600))h $((secs % 3600 / 60))m"
    elif [ "$secs" -ge 60 ]; then
        echo "$((secs / 60))m $((secs % 60))s"
    else
        echo "${secs}s"
    fi
}

print_period() {
    local label="$1"
    local data="$2"

    local sessions cycles duration fav_exercise fav_animation
    sessions=$(echo "$data" | grep "^sessions=" | cut -d= -f2)
    cycles=$(echo "$data" | grep "^cycles=" | cut -d= -f2)
    duration=$(echo "$data" | grep "^duration=" | cut -d= -f2)
    fav_exercise=$(echo "$data" | grep "^fav_exercise=" | cut -d= -f2)
    fav_animation=$(echo "$data" | grep "^fav_animation=" | cut -d= -f2)

    echo "  $label"
    if [ "${sessions:-0}" -eq 0 ]; then
        echo "    No sessions"
    else
        echo "    Sessions: $sessions  |  Cycles: ${cycles:-0}  |  Time: $(format_duration "${duration:-0}")"
        [ -n "$fav_exercise" ] && echo "    Favorite: $fav_exercise ($fav_animation)"
    fi
}

# Display
streak=$(get_streak)

echo "HushFlow Stats"
echo "=============="
if [ "$streak" -gt 0 ]; then
    echo "  Streak: ${streak} day(s)"
fi
echo ""

today_data=$(read_stats today)
week_data=$(read_stats week)
all_data=$(read_stats all)

print_period "Today" "$today_data"
echo ""
print_period "This Week" "$week_data"
echo ""
print_period "All Time" "$all_data"
echo ""
