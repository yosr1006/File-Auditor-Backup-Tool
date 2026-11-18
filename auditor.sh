#!/bin/bash

#Load helper functions
source ./lib.sh

#Directory to audit
TARGET_DIR=${1:-.}

#Backup directory
BACKUP_DIR="$TARGET_DIR/backups"

#Log file
LOG_FILE="$TARGET_DIR/auditor.log"

#Check directory
require_dir "$TARGET_DIR"

if [ $? -ne 0 ]; then
    exit 1
fi

#List files and folders and count them
scan_directory() {

    local files_count=0
    local folders_count=0

    for f in "$TARGET_DIR"/*
    do

        if [ -e "$f" ]; then

            if [ -d "$f" ]; then

                echo "[dir ] $(basename "$f")"
                folders_count=$((folders_count+1))

            elif [ -f "$f" ]; then

                echo "[file] $(basename "$f")"
                files_count=$((files_count+1))

            fi

        fi

    done

    echo
    echo "Files: $files_count     Folders: $folders_count"

    log_action "Scan completed"
}


#Check read, write and execute permissions
permission_audit() {

    local unreadable=0
    local executable=0
    local permissions=""

    for f in "$TARGET_DIR"/*
    do

        if [ -f "$f" ]; then

            permissions=""

            if [ -r "$f" ]; then
                permissions="${permissions}r"
            else
                permissions="${permissions}-"
            fi

            if [ -w "$f" ]; then
                permissions="${permissions}w"
            else
                permissions="${permissions}-"
            fi

            if [ -x "$f" ]; then
                permissions="${permissions}x"
                executable=$((executable+1))
            else
                permissions="${permissions}-"
            fi

            if [ ! -r "$f" ]; then
                unreadable=$((unreadable+1))
            fi

            echo "$permissions   $(basename "$f")"

        fi

    done

    echo
    echo "Unreadable files: $unreadable"
    echo "Executable files: $executable"

    log_action "Permission audit completed"
}


#Count files according to their extensions
extension_report() {

    declare -A extensions

    extensions=(
        [txt]=0
        [log]=0
        [sh]=0
        [jpg]=0
        [other]=0
    )

    for f in "$TARGET_DIR"/*
    do

        if [ -f "$f" ]; then

            filename=$(basename "$f")

            ext="${filename##*.}"

            if [ "$filename" == "$ext" ]; then
                ext="other"
            fi

            if [ "$ext" != "txt" ] &&
               [ "$ext" != "log" ] &&
               [ "$ext" != "sh" ] &&
               [ "$ext" != "jpg" ]; then

                ext="other"

            fi

            extensions[$ext]=$((extensions[$ext]+1))

        fi

    done

    for ext in txt log sh jpg other
    do
        echo "$ext : ${extensions[$ext]}"
    done

    log_action "Extension report completed"
}

#Search for files containing specific text in their names
search_file() {

    local search_text
    local found=0

    read -p "Enter search text: " search_text

    for f in "$TARGET_DIR"/*
    do

        if [ -f "$f" ]; then

            filename=$(basename "$f")

            if [[ "$filename" == *"$search_text"* ]]; then

                echo "Found: $filename"
                found=$((found+1))

            fi

        fi

    done

    if [ "$found" -eq 0 ]; then
        echo "No matching files found."
    fi

    log_action "Search completed"
}

#Copy readable files to the backups folder
backup_all() {

    local saved=0
    local skipped=0
    local filename
    local backup_name
    local current_date

    mkdir -p "$BACKUP_DIR"

    current_date=$(date +%Y%m%d_%H%M%S)

    for f in "$TARGET_DIR"/*
    do

        if [ -f "$f" ]; then

            filename=$(basename "$f")

            if [ -r "$f" ]; then

                backup_name="${filename%.*}_${current_date}.bak"

                cp "$f" "$BACKUP_DIR/$backup_name"

                saved=$((saved+1))

            else

                log_error "Cannot read file: $filename"

                skipped=$((skipped+1))

            fi

        fi

    done

    echo
    echo "Backup completed."
    echo "Files saved: $saved"
    echo "Files skipped: $skipped"

    log_action "Backup completed"
}

#Display all available backup files
list_backups() {

    local found=0

    if [ -d "$BACKUP_DIR" ]; then

        for f in "$BACKUP_DIR"/*.bak
        do

            if [ -f "$f" ]; then

                echo "$(basename "$f")"
                found=$((found+1))

            fi

        done

    fi

    if [ "$found" -eq 0 ]; then
        echo "(no backups yet)"
    fi

    log_action "Backup list displayed"
}

#Restore a selected backup without overwriting original files
restore_backup() {

    local backup_name
    local restore_path

    read -p "Enter backup name: " backup_name

    if [ ! -f "$BACKUP_DIR/$backup_name" ]; then

        log_error "Backup does not exist."
        log_action "Restore failed"

        return 1

    fi

    restore_path="$TARGET_DIR/restored_$backup_name"

    if [ -e "$restore_path" ]; then

        log_error "File already exists. Cannot overwrite."

        log_action "Restore failed"

        return 1

    fi

    cp "$BACKUP_DIR/$backup_name" "$restore_path"

    echo "Backup restored successfully: $(basename "$restore_path")"

    log_action "Restore completed"

    return 0
}

#Menu
show_menu() {

    local choice

    while true
    do

        echo
        echo "    FILE AUDITOR & BACKUP TOOL   "
        echo "1. Scan Directory"
        echo "2. Permission Audit"
        echo "3. Extension Report"
        echo "4. Search File"
        echo "5. Backup All"
        echo "6. List Backups"
        echo "7. Restore Backup"
        echo "8. Exit"

        echo
        read -p "Enter your choice: " choice

        if [ "$choice" -eq 1 ]; then

            scan_directory

        elif [ "$choice" -eq 2 ]; then

            permission_audit

        elif [ "$choice" -eq 3 ]; then

            extension_report

        elif [ "$choice" -eq 4 ]; then

            search_file

        elif [ "$choice" -eq 5 ]; then

            backup_all

        elif [ "$choice" -eq 6 ]; then

            list_backups

        elif [ "$choice" -eq 7 ]; then

            restore_backup

        elif [ "$choice" -eq 8 ]; then

            echo "Goodbye!"
            break

        else

            log_error "Invalid choice. Try again."

        fi

    done
}

#Execute command-line action or open the menu
if [ -z "$2" ]; then

    show_menu

elif [ "$2" == "scan" ]; then

    scan_directory

elif [ "$2" == "perms" ]; then

    permission_audit

elif [ "$2" == "ext" ]; then

    extension_report

elif [ "$2" == "backup" ]; then

    backup_all

else

    log_error "Invalid action."
    exit 1

fi

