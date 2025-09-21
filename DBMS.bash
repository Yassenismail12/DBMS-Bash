#!/bin/bash

# =============================================================================
# BASH DBMS
# =============================================================================

# Global variables
current_database=""
script_dir=$(pwd)
temp_dir="/tmp"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if zenity is installed
check_zenity() {
    if ! command -v zenity &> /dev/null; then
        echo "=========================================="
        echo "ERROR: Zenity is not installed!"
        echo "=========================================="
        echo "Please install Zenity first:"
        echo ""
        echo "Ubuntu/Debian: sudo apt-get install zenity"
        echo "CentOS/RHEL:   sudo yum install zenity"
        echo "Fedora:        sudo dnf install zenity"
        echo "Arch Linux:    sudo pacman -S zenity"
        echo "macOS:         brew install zenity"
        echo "=========================================="
        exit 1
    fi
}

# Validate database/table names (alphanumeric and underscores only)
validate_name() {
    local name="$1"
    local type="$2"
    
    # Check if empty
    if [ -z "$name" ]; then
        zenity --error --text="Error: $type name cannot be empty!" --width=350
        return 1
    fi
    
    # Check length (max 50 characters)
    if [ ${#name} -gt 50 ]; then
        zenity --error --text="Error: $type name too long (max 50 characters)!" --width=350
        return 1
    fi
    
    # Check for valid characters (alphanumeric, underscore, no spaces or special chars)
    if ! [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        zenity --error --text="Error: $type name must:\n• Start with a letter\n• Contain only letters, numbers, and underscores\n• No spaces or special characters allowed" --width=400
        return 1
    fi
    
    # Check for reserved names
    case "$name" in
        "con"|"prn"|"aux"|"nul"|"temp"|"tmp"|"system"|"admin")
            zenity --error --text="Error: '$name' is a reserved name!" --width=350
            return 1
            ;;
    esac
    
    return 0
}

# Validate integer input
validate_integer() {
    local value="$1"
    local field_name="$2"
    
    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        zenity --error --text="Error: '$field_name' must be a valid integer!\nExample: 123, -456, 0" --width=350
        return 1
    fi
    
    # Check for reasonable range (-999999999 to 999999999)
    if [ "$value" -lt -999999999 ] || [ "$value" -gt 999999999 ]; then
        zenity --error --text="Error: '$field_name' value out of range!\nRange: -999,999,999 to 999,999,999" --width=350
        return 1
    fi
    
    return 0
}

# Validate string input
validate_string() {
    local value="$1"
    local field_name="$2"
    
    if [ -z "$value" ]; then
        zenity --error --text="Error: '$field_name' cannot be empty!" --width=350
        return 1
    fi
    
    # Check length (max 255 characters)
    if [ ${#value} -gt 255 ]; then
        zenity --error --text="Error: '$field_name' too long!\nMaximum length: 255 characters\nCurrent length: ${#value}" --width=350
        return 1
    fi
    
    # Check for pipe character (used as delimiter)
    if [[ "$value" == *"|"* ]]; then
        zenity --error --text="Error: '$field_name' cannot contain pipe character (|)\nThis character is reserved for internal use." --width=400
        return 1
    fi
    
    return 0
}

# Create secure temporary file
create_temp_file() {
    local temp_file="$temp_dir/dbms_temp_$$_$(date +%s).txt"
    touch "$temp_file"
    chmod 600 "$temp_file"
    echo "$temp_file"
}

# Clean up temporary files
cleanup_temp_files() {
    rm -f "$temp_dir"/dbms_temp_$$_*.txt 2>/dev/null
}

# =============================================================================
# MENU FUNCTIONS
# =============================================================================

show_main_menu() {
    zenity --list \
        --title="Bash DBMS - Main Menu" \
        --text="<b>Team 2 - BASH Database Management System</b>\n\nSelect an operation:" \
        --column="Option" --column="Description" \
        --width=550 --height=380 \
        "1" "Create Database - Create a new database" \
        "2" "List Databases - View all available databases" \
        "3" "Connect To Database - Connect to an existing database" \
        "4" "Drop Database - Delete a database permanently" \
        "5" "Exit - Close the application" \
        2>/dev/null
}

show_database_menu() {
    zenity --list \
        --title="Database Menu - $current_database" \
        --text="<b>Connected to Database: $current_database</b>\n\nSelect a table operation:" \
        --column="Option" --column="Description" \
        --width=580 --height=450 \
        "1" "Create Table - Create a new table" \
        "2" "List Tables - View all tables in database" \
        "3" "Drop Table - Delete a table permanently" \
        "4" "Insert Data - Add new record to table" \
        "5" "Select Data - View table contents" \
        "6" "Delete Data - Remove records from table" \
        "7" "Update Data - Modify existing records" \
        "8" "Back to Main Menu - Return to main menu" \
        2>/dev/null
}

# =============================================================================
# DATABASE OPERATIONS
# =============================================================================

create_database() {
    while true; do
        db_name=$(zenity --entry \
            --title="Create Database" \
            --text="Enter database name:\n\n<i>Rules:\n• Must start with a letter\n• Can contain letters, numbers, and underscores\n• Maximum 50 characters\n• No spaces or special characters</i>" \
            --width=450 2>/dev/null)
        
        # Check if user cancelled
        if [ $? -ne 0 ]; then
            return
        fi
        
        # Validate name
        if ! validate_name "$db_name" "Database"; then
            continue
        fi
        
        # Check if database already exists
        if [ -d "$script_dir/$db_name" ]; then
            if zenity --question --text="Database '$db_name' already exists!\n\nWould you like to try a different name?" --width=350; then
                continue
            else
                return
            fi
        fi
        
        # Create database directory
        if mkdir "$script_dir/$db_name" 2>/dev/null; then
            zenity --info --text="Database '$db_name' created successfully!\n\nLocation: $script_dir/$db_name" --width=400
            break
        else
            zenity --error --text="Failed to create database '$db_name'!\n\nPossible causes:\n• Permission denied\n• Disk full\n• Invalid path" --width=400
            return
        fi
    done
}

list_databases() {
    local db_list=""
    local db_count=0
    
    # Scan for database directories
    for dir in "$script_dir"/*/; do
        if [ -d "$dir" ]; then
            db_count=$((db_count + 1))
            dir_name=$(basename "$dir")
            
            # Count tables in database
            table_count=0
            for table in "$dir"*.txt; do
                [ -f "$table" ] && table_count=$((table_count + 1))
            done
            
            db_list="$db_list$db_count. $dir_name ($table_count tables)\n"
        fi
    done
    
    if [ $db_count -eq 0 ]; then
        zenity --info \
            --title="Database List" \
            --text="No databases found!\n\n<i>Create your first database using 'Create Database' option.</i>" \
            --width=350
    else
        zenity --info \
            --title="Available Databases ($db_count found)" \
            --text="<b>Available Databases:</b>\n\n$db_list\n<i>Use 'Connect To Database' to work with tables.</i>" \
            --width=450 --height=350
    fi
}

connect_database() {
    # First show available databases
    local db_options=""
    local has_databases=false
    
    for dir in "$script_dir"/*/; do
        if [ -d "$dir" ]; then
            has_databases=true
            dir_name=$(basename "$dir")
            
            # Count tables
            table_count=0
            for table in "$dir"*.txt; do
                [ -f "$table" ] && table_count=$((table_count + 1))
            done
            
            db_options="$db_options FALSE $dir_name ($table_count tables)"
        fi
    done
    
    if [ "$has_databases" = false ]; then
        zenity --info --text="No databases available!\n\n<i>Create a database first using 'Create Database'.</i>" --width=350
        return
    fi
    
    # Let user select from available databases
    db_name=$(zenity --list --radiolist \
        --title="Connect to Database" \
        --text="<b>Select a database to connect:</b>" \
        --column="Select" --column="Database (Tables)" \
        --width=400 --height=300 \
        $db_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$db_name" ]; then
        return
    fi
    
    # Extract database name (remove table count)
    db_name=$(echo "$db_name" | sed 's/ (.*//')
    
    if [ -d "$script_dir/$db_name" ]; then
        current_database="$db_name"
        zenity --info --text="Successfully connected to database '$db_name'!\n\n<i>You can now create and manage tables.</i>" --width=400
        
        # Database menu loop
        while true; do
            choice=$(show_database_menu)
            if [ $? -ne 0 ]; then
                current_database=""
                break
            fi
            
            case $choice in
                "1") create_table ;;
                "2") list_tables ;;
                "3") drop_table ;;
                "4") insert_into_table ;;
                "5") select_from_table ;;
                "6") delete_from_table ;;
                "7") update_table ;;
                "8") current_database=""; break ;;
                *) zenity --error --text="Invalid option selected!" --width=300 ;;
            esac
        done
    else
        zenity --error --text="Database '$db_name' no longer exists!\n\nIt may have been deleted by another process." --width=400
    fi
}

drop_database() {
    # Show available databases for deletion
    local db_options=""
    local has_databases=false
    
    for dir in "$script_dir"/*/; do
        if [ -d "$dir" ]; then
            has_databases=true
            dir_name=$(basename "$dir")
            
            # Count tables
            table_count=0
            for table in "$dir"*.txt; do
                [ -f "$table" ] && table_count=$((table_count + 1))
            done
            
            db_options="$db_options FALSE $dir_name ($table_count tables)"
        fi
    done
    
    if [ "$has_databases" = false ]; then
        zenity --info --text="No databases available to delete!" --width=350
        return
    fi
    
    # Let user select database to delete
    db_name=$(zenity --list --radiolist \
        --title="Drop Database" \
        --text="<b>WARNING: Select database to DELETE permanently:</b>" \
        --column="Select" --column="Database (Tables)" \
        --width=400 --height=300 \
        $db_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$db_name" ]; then
        return
    fi
    
    # Extract database name (remove table count)
    db_name=$(echo "$db_name" | sed 's/ (.*//')
    
    if [ -d "$script_dir/$db_name" ]; then
        # Final confirmation with detailed warning
        if zenity --question \
            --title="DANGER: Permanent Deletion" \
            --text="<b>WARNING: This action cannot be undone!</b>\n\nYou are about to permanently delete:\n\nDatabase: <b>$db_name</b>\nAll tables and their data\n\nThis will:\n• Remove all data permanently\n• Cannot be recovered\n• Affect any applications using this database\n\n<b>Are you absolutely sure?</b>" \
            --width=500; then
            
            # Disconnect if currently connected
            if [ "$current_database" = "$db_name" ]; then
                current_database=""
            fi
            
            # Delete database
            if rm -rf "$script_dir/$db_name" 2>/dev/null; then
                zenity --info --text="Database '$db_name' deleted successfully!\n\n<i>All data has been permanently removed.</i>" --width=400
            else
                zenity --error --text="Failed to delete database '$db_name'!\n\nPossible causes:\n• Permission denied\n• Database in use\n• File system error" --width=400
            fi
        fi
    else
        zenity --error --text="Database '$db_name' not found!\n\nIt may have been deleted already." --width=350
    fi
}

# =============================================================================
# TABLE OPERATIONS
# =============================================================================

create_table() {
    # Get table name with validation
    while true; do
        table_name=$(zenity --entry \
            --title="Create Table" \
            --text="Enter table name:\n\n<i>Rules:\n• Must start with a letter\n• Can contain letters, numbers, and underscores\n• Maximum 50 characters\n• No spaces or special characters</i>" \
            --width=450 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        if ! validate_name "$table_name" "Table"; then
            continue
        fi
        
        if [ -f "$script_dir/$current_database/$table_name.txt" ]; then
            if zenity --question --text="Table '$table_name' already exists!\n\nWould you like to try a different name?" --width=350; then
                continue
            else
                return
            fi
        fi
        
        break
    done
    
    # Get number of columns
    while true; do
        num_columns=$(zenity --entry \
            --title="Create Table - Columns" \
            --text="Enter number of columns for table '$table_name':\n\n<i>Range: 1 to 20 columns</i>" \
            --width=400 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        if ! [[ "$num_columns" =~ ^[0-9]+$ ]] || [ "$num_columns" -lt 1 ] || [ "$num_columns" -gt 20 ]; then
            zenity --error --text="Invalid number of columns!\n\n• Must be a number between 1 and 20\n• Current input: '$num_columns'" --width=350
            continue
        fi
        
        break
    done
    
    # Get column details
    column_names=()
    column_types=()
    
    for ((i=1; i<=num_columns; i++)); do
        # Get column name
        while true; do
            col_name=$(zenity --entry \
                --title="Create Table - Column $i of $num_columns" \
                --text="Enter name for column $i:\n\n<i>Column naming rules:\n• Must start with a letter\n• Can contain letters, numbers, and underscores\n• Maximum 30 characters</i>" \
                --width=450 2>/dev/null)
            
            if [ $? -ne 0 ]; then
                return
            fi
            
            # Validate column name (shorter limit)
            if [ -z "$col_name" ]; then
                zenity --error --text="Column name cannot be empty!" --width=300
                continue
            fi
            
            if [ ${#col_name} -gt 30 ]; then
                zenity --error --text="Column name too long (max 30 characters)!" --width=350
                continue
            fi
            
            if ! [[ "$col_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
                zenity --error --text="Invalid column name!\n\nMust:\n• Start with a letter\n• Contain only letters, numbers, underscores\n• No spaces or special characters" --width=400
                continue
            fi
            
            # Check for duplicate column names
            duplicate=false
            for existing_col in "${column_names[@]}"; do
                if [ "$existing_col" = "$col_name" ]; then
                    duplicate=true
                    break
                fi
            done
            
            if [ "$duplicate" = true ]; then
                zenity --error --text="Column name '$col_name' already exists!\n\nPlease choose a different name." --width=350
                continue
            fi
            
            break
        done
        
        column_names+=("$col_name")
        
        # Get column type
        col_type=$(zenity --list \
            --title="Create Table - Column '$col_name' Type" \
            --text="Select data type for column '<b>$col_name</b>':" \
            --column="Type" --column="Description" --column="Example" \
            --width=500 --height=250 \
            "int" "Integer numbers" "123, -456, 0" \
            "str" "Text strings" "Hello, John Doe" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        column_types+=("$col_type")
    done
    
    # Primary key selection
    pk_options="TRUE None (No primary key)"
    for ((i=0; i<${#column_names[@]}; i++)); do
        pk_options="$pk_options FALSE ${column_names[i]} (${column_types[i]})"
    done
    
    primary_key=$(zenity --list --radiolist \
        --title="Primary Key Selection" \
        --text="<b>Select primary key for table '$table_name':</b>\n\n<i>Primary key ensures each record is unique.\nRecommended for data integrity.</i>" \
        --column="Select" --column="Column" \
        --width=450 --height=300 \
        $pk_options 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    # Extract primary key name
    if [[ "$primary_key" == *"None"* ]]; then
        primary_key=""
    else
        primary_key=$(echo "$primary_key" | sed 's/ (.*//')
    fi
    
    # Create table file
    table_file="$script_dir/$current_database/$table_name.txt"
    
    # Write table metadata
    {
        echo "# Table: $table_name"
        echo "# Primary Key: $primary_key"
        echo "# Created: $(date '+%Y-%m-%d %H:%M:%S')"
    } > "$table_file"
    
    # Write headers and types
    header=""
    types_line=""
    for ((i=0; i<${#column_names[@]}; i++)); do
        if [ $i -eq 0 ]; then
            header="${column_names[i]}"
            types_line="${column_types[i]}"
        else
            header="$header|${column_names[i]}"
            types_line="$types_line|${column_types[i]}"
        fi
    done
    
    echo "$header" >> "$table_file"
    echo "$types_line" >> "$table_file"
    
    # Success message with summary
    summary="Table '$table_name' created successfully!\n\n"
    summary="${summary}<b>Table Summary:</b>\n"
    summary="${summary}• Columns: $num_columns\n"
    if [ -z "$primary_key" ]; then
        summary="${summary}• Primary Key: None\n"
    else
        summary="${summary}• Primary Key: $primary_key\n"
    fi
    summary="${summary}\n<i>You can now insert data into this table.</i>"
    
    zenity --info --text="$summary" --width=450
}

list_tables() {
    local table_list=""
    local table_count=0
    
    for file in "$script_dir/$current_database"/*.txt; do
        if [ -f "$file" ]; then
            table_count=$((table_count + 1))
            table_name=$(basename "$file" .txt)
            
            # Get table info
            if [ -r "$file" ]; then
                row_count=$(tail -n +6 "$file" 2>/dev/null | grep -c .) || row_count=0
                primary_key=$(sed -n '2p' "$file" 2>/dev/null | cut -d':' -f2 | xargs)
                
                if [ -z "$primary_key" ]; then
                    primary_key="None"
                fi
                
                table_list="$table_list$table_count. $table_name ($row_count rows, PK: $primary_key)\n"
            else
                table_list="$table_list$table_count. $table_name (Access denied)\n"
            fi
        fi
    done
    
    if [ $table_count -eq 0 ]; then
        zenity --info \
            --title="Tables in Database: $current_database" \
            --text="No tables found in database '$current_database'!\n\n<i>Create your first table using 'Create Table' option.</i>" \
            --width=400
    else
        zenity --info \
            --title="Tables in Database: $current_database ($table_count found)" \
            --text="<b>Available Tables:</b>\n\n$table_list\n<i>Use other menu options to work with table data.</i>" \
            --width=550 --height=400
    fi
}

drop_table() {
    # Get list of available tables
    local table_options=""
    local has_tables=false
    
    for file in "$script_dir/$current_database"/*.txt; do
        if [ -f "$file" ]; then
            has_tables=true
            table_name=$(basename "$file" .txt)
            
            # Get row count
            row_count=$(tail -n +6 "$file" 2>/dev/null | grep -c .) || row_count=0
            
            table_options="$table_options FALSE $table_name ($row_count rows)"
        fi
    done
    
    if [ "$has_tables" = false ]; then
        zenity --info --text="No tables found in database '$current_database'!\n\n<i>Create a table first using 'Create Table'.</i>" --width=400
        return
    fi
    
    # Let user select table to delete
    table_name=$(zenity --list --radiolist \
        --title="Drop Table" \
        --text="<b>WARNING: Select table to DELETE permanently:</b>\n\nDatabase: $current_database" \
        --column="Select" --column="Table (Rows)" \
        --width=450 --height=350 \
        $table_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    # Extract table name (remove row count)
    table_name=$(echo "$table_name" | sed 's/ (.*//')
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ -f "$table_file" ]; then
        # Get table details for confirmation
        row_count=$(tail -n +6 "$table_file" 2>/dev/null | grep -c .) || row_count=0
        
        # Final confirmation
        if zenity --question \
            --title="DANGER: Permanent Deletion" \
            --text="<b>WARNING: This action cannot be undone!</b>\n\nYou are about to permanently delete:\n\nTable: <b>$table_name</b>\nDatabase: <b>$current_database</b>\nRecords: <b>$row_count</b>\n\nThis will:\n• Remove all data permanently\n• Cannot be recovered\n\n<b>Are you absolutely sure?</b>" \
            --width=500; then
            
            if rm "$table_file" 2>/dev/null; then
                zenity --info --text="Table '$table_name' deleted successfully!\n\n<i>All data has been permanently removed.</i>" --width=400
            else
                zenity --error --text="Failed to delete table '$table_name'!\n\nPossible causes:\n• Permission denied\n• File in use\n• File system error" --width=400
            fi
        fi
    else
        zenity --error --text="Table '$table_name' not found!\n\nIt may have been deleted already." --width=350
    fi
}

# =============================================================================
# DATA OPERATIONS
# =============================================================================

insert_into_table() {
    # Get list of available tables
    local table_options=""
    local has_tables=false
    
    for file in "$script_dir/$current_database"/*.txt; do
        if [ -f "$file" ]; then
            has_tables=true
            table_name=$(basename "$file" .txt)
            
            # Get column count
            col_count=$(sed -n '4p' "$file" 2>/dev/null | tr -cd '|' | wc -c) || col_count=0
            col_count=$((col_count + 1))
            
            table_options="$table_options FALSE $table_name ($col_count columns)"
        fi
    done
    
    if [ "$has_tables" = false ]; then
        zenity --info --text="No tables found in database '$current_database'!\n\n<i>Create a table first using 'Create Table'.</i>" --width=400
        return
    fi
    
    # Let user select table
    table_name=$(zenity --list --radiolist \
        --title="Insert Data" \
        --text="<b>Select table to insert data:</b>\n\nDatabase: $current_database" \
        --column="Select" --column="Table (Columns)" \
        --width=400 --height=300 \
        $table_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    # Extract table name
    table_name=$(echo "$table_name" | sed 's/ (.*//')
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        zenity --error --text="Table '$table_name' not found!" --width=350
        return
    fi
    
    # Read table structure
    headers=$(sed -n '4p' "$table_file" 2>/dev/null)
    types=$(sed -n '5p' "$table_file" 2>/dev/null)
    primary_key=$(sed -n '2p' "$table_file" 2>/dev/null | cut -d':' -f2 | xargs)
    
    if [ -z "$headers" ] || [ -z "$types" ]; then
        zenity --error --text="Table '$table_name' is corrupted!\n\nUnable to read table structure." --width=350
        return
    fi
    
    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"
    
    # Collect data for each column
    row_data=()
    
    for ((i=0; i<${#header_array[@]}; i++)); do
        while true; do
            # Show field info with validation rules
            field_info="Enter value for column '<b>${header_array[i]}</b>':\n\n"
            field_info="${field_info}Type: ${type_array[i]}\n"
            
            if [ "${type_array[i]}" = "int" ]; then
                field_info="${field_info}Format: Integer numbers\n"
                field_info="${field_info}Examples: 123, -456, 0\n"
                field_info="${field_info}Range: -999,999,999 to 999,999,999"
            else
                field_info="${field_info}Format: Text string\n"
                field_info="${field_info}Examples: Hello, John Doe\n"
                field_info="${field_info}Max length: 255 characters\n"
                field_info="${field_info}Cannot contain pipe symbol (|)"
            fi
            
            # Check if this is primary key
            if [ "${header_array[i]}" = "$primary_key" ]; then
                field_info="${field_info}\n\n<b>This is the primary key - must be unique!</b>"
            fi
            
            value=$(zenity --entry \
                --title="Insert Data - Column ${header_array[i]}" \
                --text="$field_info" \
                --width=550 2>/dev/null)
            
            if [ $? -ne 0 ]; then
                return
            fi
            
            # Validate based on type
            if [ "${type_array[i]}" = "int" ]; then
                if validate_integer "$value" "${header_array[i]}"; then
                    break
                fi
            else
                if validate_string "$value" "${header_array[i]}"; then
                    break
                fi
            fi
        done
        
        row_data+=("$value")
    done
    
    # Check primary key constraint
    if [ ! -z "$primary_key" ]; then
        pk_index=-1
        for ((i=0; i<${#header_array[@]}; i++)); do
            if [ "${header_array[i]}" = "$primary_key" ]; then
                pk_index=$i
                break
            fi
        done
        
        if [ $pk_index -ge 0 ]; then
            pk_value="${row_data[pk_index]}"
            
            # Check if primary key already exists
            if tail -n +6 "$table_file" 2>/dev/null | grep -q "^$pk_value|" || tail -n +6 "$table_file" 2>/dev/null | grep -q "|$pk_value|" || tail -n +6 "$table_file" 2>/dev/null | grep -q "|$pk_value$" || tail -n +6 "$table_file" 2>/dev/null | grep -q "^$pk_value$"; then
                zenity --error --text="Primary key violation!\n\nValue '$pk_value' for primary key '$primary_key' already exists in the table.\n\n<i>Primary key values must be unique.</i>" --width=450
                return
            fi
        fi
    fi
    
    # Build row string
    row_string=""
    for ((i=0; i<${#row_data[@]}; i++)); do
        if [ $i -eq 0 ]; then
            row_string="${row_data[i]}"
        else
            row_string="$row_string|${row_data[i]}"
        fi
    done
    
    # Insert data
    if echo "$row_string" >> "$table_file"; then
        # Show success with data preview
        preview="Data inserted successfully!\n\n"
        preview="${preview}<b>Inserted Record:</b>\n"
        for ((i=0; i<${#header_array[@]}; i++)); do
            preview="${preview}• ${header_array[i]}: ${row_data[i]}\n"
        done
        preview="${preview}\n<i>Record added to table '$table_name'.</i>"
        
        zenity --info --text="$preview" --width=450
    else
        zenity --error --text="Failed to insert data!\n\nPossible causes:\n• Permission denied\n• Disk full\n• File system error" --width=400
    fi
}

select_from_table() {
    # Get list of available tables
    local table_options=""
    local has_tables=false
    
    for file in "$script_dir/$current_database"/*.txt; do
        if [ -f "$file" ]; then
            has_tables=true
            table_name=$(basename "$file" .txt)
            
            # Get row count
            row_count=$(tail -n +6 "$file" 2>/dev/null | grep -c .) || row_count=0
            
            table_options="$table_options FALSE $table_name ($row_count rows)"
        fi
    done
    
    if [ "$has_tables" = false ]; then
        zenity --info --text="No tables found in database '$current_database'!\n\n<i>Create a table first using 'Create Table'.</i>" --width=400
        return
    fi
    
    # Let user select table
    table_name=$(zenity --list --radiolist \
        --title="Select Data" \
        --text="<b>Select table to view data:</b>\n\nDatabase: $current_database" \
        --column="Select" --column="Table (Rows)" \
        --width=400 --height=300 \
        $table_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    # Extract table name
    table_name=$(echo "$table_name" | sed 's/ (.*//')
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        zenity --error --text="Table '$table_name' not found!" --width=350
        return
    fi
    
    # Read table data
    headers=$(sed -n '4p' "$table_file" 2>/dev/null)
    data_content=$(tail -n +6 "$table_file" 2>/dev/null | grep -v '^')
    
    if [ -z "$headers" ]; then
        zenity --error --text="Table '$table_name' is corrupted!\n\nUnable to read table headers." --width=350
        return
    fi
    
    # Count rows
    if [ -z "$data_content" ]; then
        data_rows=0
    else
        data_rows=$(echo "$data_content" | wc -l)
    fi
    
    if [ $data_rows -eq 0 ]; then
        zenity --info \
            --title="Table Data: $table_name" \
            --text="Table '$table_name' is empty!\n\n<b>Table Structure:</b>\n$headers\n\n<i>Use 'Insert Data' to add records.</i>" \
            --width=500
    else
        # Format data for display
        display_text="<b>Table: $table_name</b>\n"
        display_text="${display_text}Database: $current_database\n\n"
        display_text="${display_text}<b>Headers:</b>\n$headers\n\n"
        display_text="${display_text}<b>Data ($data_rows rows):</b>\n\n$data_content\n\n"
        display_text="${display_text}<i>Total records: $data_rows</i>"
        
        zenity --info \
            --title="Table Data: $table_name" \
            --text="$display_text" \
            --width=700 --height=500
    fi
}

delete_from_table() {
    # Get list of available tables
    local table_options=""
    local has_tables=false
    
    for file in "$script_dir/$current_database"/*.txt; do
        if [ -f "$file" ]; then
            has_tables=true
            table_name=$(basename "$file" .txt)
            
            # Get row count
            row_count=$(tail -n +6 "$file" 2>/dev/null | grep -c .) || row_count=0
            
            if [ $row_count -gt 0 ]; then
                table_options="$table_options FALSE $table_name ($row_count rows)"
            fi
        fi
    done
    
    if [ "$has_tables" = false ]; then
        zenity --info --text="No tables with data found in database '$current_database'!\n\n<i>Insert data into tables first.</i>" --width=400
        return
    fi
    
    # Let user select table
    table_name=$(zenity --list --radiolist \
        --title="Delete Data" \
        --text="<b>Select table to delete data from:</b>\n\nDatabase: $current_database" \
        --column="Select" --column="Table (Rows)" \
        --width=450 --height=300 \
        $table_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    # Extract table name
    table_name=$(echo "$table_name" | sed 's/ (.*//')
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        zenity --error --text="Table '$table_name' not found!" --width=350
        return
    fi
    
    headers=$(sed -n '4p' "$table_file" 2>/dev/null)
    
    # Build list of rows for selection
    row_options=""
    row_num=1
    
    while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            # Truncate long lines for display
            display_line="$line"
            if [ ${#display_line} -gt 80 ]; then
                display_line="${display_line:0:77}..."
            fi
            row_options="$row_options FALSE $row_num $display_line"
            row_num=$((row_num + 1))
        fi
    done < <(tail -n +6 "$table_file")
    
    if [ -z "$row_options" ]; then
        zenity --info --text="Table '$table_name' is empty!\n\n<i>No data to delete.</i>" --width=350
        return
    fi
    
    # Let user select row to delete
    selected_row=$(zenity --list --radiolist \
        --title="Delete Row from $table_name" \
        --text="<b>Headers:</b> $headers\n\n<b>WARNING: Select row to DELETE permanently:</b>" \
        --column="Select" --column="Row#" --column="Data" \
        --width=800 --height=450 \
        $row_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$selected_row" ]; then
        return
    fi
    
    # Get the actual row data for confirmation
    actual_row=$(tail -n +6 "$table_file" | sed -n "${selected_row}p")
    
    # Final confirmation
    if zenity --question \
        --title="Confirm Deletion" \
        --text="<b>Are you sure you want to delete this record?</b>\n\nTable: $table_name\nRow #: $selected_row\nData: $actual_row\n\n<b>This action cannot be undone!</b>" \
        --width=550; then
        
        # Create temporary file for deletion
        temp_file=$(create_temp_file)
        
        # Copy header lines
        head -5 "$table_file" > "$temp_file"
        
        # Copy all rows except the selected one
        current_row=1
        while IFS= read -r line; do
            if [ ! -z "$line" ]; then
                if [ "$current_row" -ne "$selected_row" ]; then
                    echo "$line" >> "$temp_file"
                fi
                current_row=$((current_row + 1))
            fi
        done < <(tail -n +6 "$table_file")
        
        # Replace original file
        if mv "$temp_file" "$table_file" 2>/dev/null; then
            zenity --info --text="Record deleted successfully!\n\n<i>Row #$selected_row has been permanently removed from table '$table_name'.</i>" --width=450
        else
            zenity --error --text="Failed to delete record!\n\nPossible causes:\n• Permission denied\n• File system error" --width=400
            rm -f "$temp_file" 2>/dev/null
        fi
    fi
}

update_table() {
    # Get list of available tables with data
    local table_options=""
    local has_tables=false
    
    for file in "$script_dir/$current_database"/*.txt; do
        if [ -f "$file" ]; then
            table_name=$(basename "$file" .txt)
            
            # Get row count
            row_count=$(tail -n +6 "$file" 2>/dev/null | grep -c .) || row_count=0
            
            if [ $row_count -gt 0 ]; then
                has_tables=true
                table_options="$table_options FALSE $table_name ($row_count rows)"
            fi
        fi
    done
    
    if [ "$has_tables" = false ]; then
        zenity --info --text="No tables with data found in database '$current_database'!\n\n<i>Insert data into tables first.</i>" --width=400
        return
    fi
    
    # Let user select table
    table_name=$(zenity --list --radiolist \
        --title="Update Data" \
        --text="<b>Select table to update data:</b>\n\nDatabase: $current_database" \
        --column="Select" --column="Table (Rows)" \
        --width=450 --height=300 \
        $table_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    # Extract table name
    table_name=$(echo "$table_name" | sed 's/ (.*//')
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        zenity --error --text="Table '$table_name' not found!" --width=350
        return
    fi
    
    headers=$(sed -n '4p' "$table_file" 2>/dev/null)
    
    # Build list of rows for selection
    row_options=""
    row_num=1
    
    while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            # Truncate long lines for display
            display_line="$line"
            if [ ${#display_line} -gt 80 ]; then
                display_line="${display_line:0:77}..."
            fi
            row_options="$row_options FALSE $row_num $display_line"
            row_num=$((row_num + 1))
        fi
    done < <(tail -n +6 "$table_file")
    
    if [ -z "$row_options" ]; then
        zenity --info --text="Table '$table_name' is empty!\n\n<i>No data to update.</i>" --width=350
        return
    fi
    
    # Let user select row to update
    selected_row=$(zenity --list --radiolist \
        --title="Update Row in $table_name" \
        --text="<b>Headers:</b> $headers\n\n<b>Select row to UPDATE:</b>" \
        --column="Select" --column="Row#" --column="Data" \
        --width=800 --height=450 \
        $row_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$selected_row" ]; then
        return
    fi
    
    # Get table structure
    types=$(sed -n '5p' "$table_file" 2>/dev/null)
    primary_key=$(sed -n '2p' "$table_file" 2>/dev/null | cut -d':' -f2 | xargs)
    
    if [ -z "$types" ]; then
        zenity --error --text="Table '$table_name' is corrupted!\n\nUnable to read table structure." --width=350
        return
    fi
    
    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"
    
    # Get old row data
    old_row=$(tail -n +6 "$table_file" | sed -n "${selected_row}p")
    IFS='|' read -ra old_data <<< "$old_row"
    
    # Collect new data for each column
    new_row_data=()
    
    for ((i=0; i<${#header_array[@]}; i++)); do
        while true; do
            # Show current value and field info
            field_info="Update value for column '<b>${header_array[i]}</b>':\n\n"
            field_info="${field_info}Type: ${type_array[i]}\n"
            field_info="${field_info}Current value: <b>${old_data[i]}</b>\n\n"
            
            if [ "${type_array[i]}" = "int" ]; then
                field_info="${field_info}Format: Integer numbers\n"
                field_info="${field_info}Examples: 123, -456, 0\n"
                field_info="${field_info}Range: -999,999,999 to 999,999,999"
            else
                field_info="${field_info}Format: Text string\n"
                field_info="${field_info}Examples: Hello, John Doe\n"
                field_info="${field_info}Max length: 255 characters\n"
                field_info="${field_info}Cannot contain pipe symbol (|)"
            fi
            
            # Check if this is primary key
            if [ "${header_array[i]}" = "$primary_key" ]; then
                field_info="${field_info}\n\n<b>This is the primary key - must be unique!</b>"
            fi
            
            field_info="${field_info}\n\n<i>Leave empty to keep current value</i>"
            
            value=$(zenity --entry \
                --title="Update Data - Column ${header_array[i]}" \
                --text="$field_info" \
                --entry-text="${old_data[i]}" \
                --width=550 2>/dev/null)
            
            if [ $? -ne 0 ]; then
                return
            fi
            
            # If empty, keep old value
            if [ -z "$value" ]; then
                value="${old_data[i]}"
            fi
            
            # Validate based on type
            if [ "${type_array[i]}" = "int" ]; then
                if validate_integer "$value" "${header_array[i]}"; then
                    break
                fi
            else
                if validate_string "$value" "${header_array[i]}"; then
                    break
                fi
            fi
        done
        
        new_row_data+=("$value")
    done
    
    # Check primary key constraint (if primary key was changed)
    if [ ! -z "$primary_key" ]; then
        pk_index=-1
        for ((i=0; i<${#header_array[@]}; i++)); do
            if [ "${header_array[i]}" = "$primary_key" ]; then
                pk_index=$i
                break
            fi
        done
        
        if [ $pk_index -ge 0 ] && [ "${new_row_data[pk_index]}" != "${old_data[pk_index]}" ]; then
            pk_value="${new_row_data[pk_index]}"
            
            # Check if new primary key value already exists
            if tail -n +6 "$table_file" 2>/dev/null | grep -q "^$pk_value|" || tail -n +6 "$table_file" 2>/dev/null | grep -q "|$pk_value|" || tail -n +6 "$table_file" 2>/dev/null | grep -q "|$pk_value$" || tail -n +6 "$table_file" 2>/dev/null | grep -q "^$pk_value$"; then
                zenity --error --text="Primary key violation!\n\nValue '$pk_value' for primary key '$primary_key' already exists in the table.\n\n<i>Primary key values must be unique.</i>" --width=450
                return
            fi
        fi
    fi
    
    # Build new row string
    new_row_string=""
    for ((i=0; i<${#new_row_data[@]}; i++)); do
        if [ $i -eq 0 ]; then
            new_row_string="${new_row_data[i]}"
        else
            new_row_string="$new_row_string|${new_row_data[i]}"
        fi
    done
    
    # Show changes for confirmation
    changes=""
    has_changes=false
    for ((i=0; i<${#header_array[@]}; i++)); do
        if [ "${old_data[i]}" != "${new_row_data[i]}" ]; then
            has_changes=true
            changes="${changes}• ${header_array[i]}: '${old_data[i]}' → '${new_row_data[i]}'\n"
        fi
    done
    
    if [ "$has_changes" = false ]; then
        zenity --info --text="No changes made!\n\nAll values remain the same." --width=350
        return
    fi
    
    # Confirm update
    if zenity --question \
        --title="Confirm Update" \
        --text="<b>Confirm the following changes:</b>\n\nTable: $table_name\nRow #: $selected_row\n\n<b>Changes:</b>\n$changes\n<b>Continue with update?</b>" \
        --width=500; then
        
        # Create temporary file for update
        temp_file=$(create_temp_file)
        
        # Copy header lines
        head -5 "$table_file" > "$temp_file"
        
        # Copy all rows, replacing the selected one
        current_row=1
        while IFS= read -r line; do
            if [ ! -z "$line" ]; then
                if [ "$current_row" -eq "$selected_row" ]; then
                    echo "$new_row_string" >> "$temp_file"
                else
                    echo "$line" >> "$temp_file"
                fi
                current_row=$((current_row + 1))
            fi
        done < <(tail -n +6 "$table_file")
        
        # Replace original file
        if mv "$temp_file" "$table_file" 2>/dev/null; then
            zenity --info --text="Record updated successfully!\n\n<i>Row #$selected_row in table '$table_name' has been updated.</i>" --width=450
        else
            zenity --error --text="Failed to update record!\n\nPossible causes:\n• Permission denied\n• File system error" --width=400
            rm -f "$temp_file" 2>/dev/null
        fi
    fi
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    # Check dependencies
    check_zenity
    
    # Set trap for cleanup
    trap cleanup_temp_files EXIT
    
    # Welcome message
    zenity --info \
        --title="Welcome to Bash DBMS" \
        --text="<b>Welcome to Enhanced Bash DBMS!</b>\n\n<b>Development Team:</b>\n• Yassen Mohamed Abdulhamid\n• Mostafa Mohamed Abdullatif\n• Abdulrahman Raafat\n• Ahmed Atef\n" \
        --width=500
    
    # Main program loop
    while true; do
        choice=$(show_main_menu)
        
        # Handle user cancellation or window close
        if [ $? -ne 0 ]; then
            if zenity --question --text="Are you sure you want to exit Bash DBMS?" --width=300; then
                break
            else
                continue
            fi
        fi
        
        # Handle menu selections
        case $choice in
            "1") create_database ;;
            "2") list_databases ;;
            "3") connect_database ;;
            "4") drop_database ;;
            "5") 
                zenity --info --text="Thank you for using Enhanced Bash DBMS!\n\n<b>Goodbye!</b>\n\n<i>All your data has been safely saved.</i>" --width=400
                break
                ;;
            *) 
                zenity --error --text="Invalid option selected!\n\nPlease choose a valid menu option." --width=350
                ;;
        esac
    done
    
    # Final cleanup
    cleanup_temp_files
    exit 0
}

# =============================================================================
# PROGRAM ENTRY POINT
# =============================================================================

# Run the main function
main "$@"