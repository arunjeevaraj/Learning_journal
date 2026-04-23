#!/bin/bash


# --- activate the python virtual environment.
source mkdoc/bin/activate

# --- Configuration ---
HOST="127.0.0.1"
PORT="8000"
URL="http://$HOST:$PORT"
DOCS_DIR="docs"

usage() {
    echo "Usage: ./manage.sh [command]"
    echo "Commands:"
    echo "  serve          : Start local preview"
    echo "  new <dir>      : Create a new note in a specific folder (e.g., ./manage.sh new python)"
    echo "  push           : Sync to GitHub"
    exit 1
}

case "$1" in
    serve)
        echo "🚀 Starting local preview at $URL"
        (sleep 2 && python3 -m webbrowser "$URL") &
        mkdocs serve -a "$HOST:$PORT"
        ;;

    new)
        # Check if directory name was provided
        target_dir="$2"
        if [ -z "$target_dir" ] || [ ! -d "$DOCS_DIR/$target_dir" ]; then
            echo "❌ Error: Please specify a valid directory inside /docs (e.g., til, python, DSP)"
            exit 1
        fi

        read -p "Enter Topic: " topic
        if [ -z "$topic" ]; then exit 1; fi
        
        filename=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
        filepath="$DOCS_DIR/$target_dir/${filename}.md"
        index_file="$DOCS_DIR/$target_dir/index.md"
        datestamp=$(date +'%Y-%m-%d')
        
        # 1. Create the unique page
        if [ ! -f "$filepath" ]; then
            {
                echo "---"
                echo "date: $datestamp"
                echo "---"
                echo "# $topic"
                echo -e "\n**Date:** $datestamp"
                echo -e "\n## Context"
                echo -e "\n## Implementation / Notes"
            } > "$filepath"
            
            # 2. Update the directory's index.md if it exists
            if [ -f "$index_file" ]; then
                # Prepend link after the H1 title
                sed -i "/# /a * [$datestamp] [$topic](./${filename}.md)" "$index_file"
                echo "🔗 Updated $index_file"
            fi
            echo "📝 Created: $filepath"
        else
            echo "⚠️  Note exists. Opening for edit."
        fi
        
        codium "$filepath"
        ;;

    push)
        git add .
        read -p "Commit message: " msg
        msg=${msg:-"update journal $(date +'%Y-%m-%d')"}
        git commit -m "$msg"
        git push origin main
        ;;

    *)
        usage
        ;;
esac