#!/bin/bash

current_database=""
script_dir=$(pwd) 

if ! command -v zenity &> /dev/null; then
    echo "Error: Zenity is not installed. Please install it first:"
    echo "Ubuntu/Debian: sudo apt-get install zenity"
    echo "CentOS/RHEL: sudo yum install zenity"
    echo "Arch Linux: sudo pacman -S zenity"
    exit 1
fi

show_main_menu() {
    zenity --list \
        --title="Bash DBMS - Main Menu" \
        --text="Team 2 - BASH Database Management System" \
        --column="Option" --column="Description" \
        --width=500 --height=350 \
        "1" "Create Database" \
        "2" "List Databases" \
        "3" "Connect To Database" \
        "4" "Drop Database" \
        "5" "Exit" \
        2>/dev/null
}

show_database_menu() {
    zenity --list \
        --title="Database Menu - $current_database" \
        --text="Connected to Database: $current_database" \
        --column="Option" --column="Description" \
        --width=500 --height=400 \
        "1" "Create Table" \
        "2" "List Tables" \
        "3" "Drop Table" \
        "4" "Insert into Table" \
        "5" "Select From Table" \
        "6" "Delete From Table" \
        "7" "Update Table" \
        "8" "Back to Main Menu" \
        2>/dev/null
}

create_database() {
    db_name=$(zenity --entry \
        --title="Create Database" \
        --text="Enter database name:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$db_name" ]; then
        return
    fi
    
    if [ -d "$script_dir/$db_name" ]; then
        zenity --error --text="Error: Database '$db_name' already exists!" --width=300
    else
        mkdir "$script_dir/$db_name"
        zenity --info --text="Database '$db_name' created successfully!" --width=300
    fi
}

list_databases() {
    db_list=""
    db_count=0
    
    for dir in */; do
        if [ -d "$dir" ]; then
            db_count=$((db_count + 1))
            db_list="$db_list${dir%/}\n"
        fi
    done
    
    if [ $db_count -eq 0 ]; then
        zenity --info --text="No databases found!" --width=300
    else
        zenity --info --title="Available Databases" \
            --text="Available Databases:\n\n$db_list" \
            --width=400 --height=300
    fi
}

connect_database() {
    db_name=$(zenity --entry \
        --title="Connect to Database" \
        --text="Enter database name:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$db_name" ]; then
        return
    fi
    
    if [ -d "$script_dir/$db_name" ]; then
        current_database="$db_name"
        zenity --info --text="Connected to database '$db_name'" --width=300
        
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
                *) zenity --error --text="Invalid option!" --width=300 ;;
            esac
        done
    else
        zenity --error --text="Error: Database '$db_name' does not exist!" --width=300
    fi
}

drop_database() {
    db_name=$(zenity --entry \
        --title="Drop Database" \
        --text="Enter database name to delete:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$db_name" ]; then
        return
    fi
    
    if [ -d "$script_dir/$db_name" ]; then
        if zenity --question \
            --text="WARNING: This will delete the entire database '$db_name' and all its data!\n\nAre you sure you want to continue?" \
            --width=400; then
            rm -rf "$script_dir/$db_name"
            zenity --info --text="Database '$db_name' deleted successfully!" --width=300
        fi
    else
        zenity --error --text="Error: Database '$db_name' does not exist!" --width=300
    fi
}

create_table() {
    table_name=$(zenity --entry \
        --title="Create Table" \
        --text="Enter table name:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    if [ -f "$script_dir/$current_database/$table_name.txt" ]; then
        zenity --error --text="Error: Table '$table_name' already exists!" --width=300
        return
    fi
    
    num_columns=$(zenity --entry \
        --title="Create Table" \
        --text="Enter number of columns:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || ! [[ "$num_columns" =~ ^[0-9]+$ ]] || [ "$num_columns" -lt 1 ]; then
        zenity --error --text="Error: Invalid number of columns!" --width=300
        return
    fi
    
    column_names=()
    column_types=()
    
    for ((i=1; i<=num_columns; i++)); do
        col_name=$(zenity --entry \
            --title="Create Table" \
            --text="Enter name for column $i:" \
            --width=300 2>/dev/null)
        
        if [ $? -ne 0 ] || [ -z "$col_name" ]; then
            return
        fi
        
        column_names+=("$col_name")
        
        col_type=$(zenity --list \
            --title="Create Table" \
            --text="Select data type for column '$col_name':" \
            --column="Type" --column="Description" \
            --width=300 --height=200 \
            "int" "Integer" \
            "str" "String" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        column_types+=("$col_type")
    done
    
    pk_options=""
    for ((i=0; i<${#column_names[@]}; i++)); do
        pk_options="$pk_options FALSE ${column_names[i]}"
    done
    pk_options="$pk_options TRUE None"
    
    primary_key=$(zenity --list --radiolist \
        --title="Primary Key Selection" \
        --text="Select primary key column:" \
        --column="Select" --column="Column" \
        --width=300 --height=250 \
        $pk_options 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    if [ "$primary_key" = "None" ]; then
        primary_key=""
    fi
    
    table_file="$script_dir/$current_database/$table_name.txt"
    echo "# Table: $table_name" > "$table_file"
    echo "# Primary Key: $primary_key" >> "$table_file"
    
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
    
    zenity --info --text="Table '$table_name' created successfully!" --width=300
}

list_tables() {
    table_list=""
    table_count=0
    
    for file in "$script_dir/$current_database"/*.txt; do
        if [ -f "$file" ]; then
            table_count=$((table_count + 1))
            table_name=$(basename "$file" .txt)
            table_list="$table_list$table_name\n"
        fi
    done
    
    if [ $table_count -eq 0 ]; then
        zenity --info --text="No tables found in database '$current_database'!" --width=300
    else
        zenity --info --title="Tables in Database: $current_database" \
            --text="Available Tables:\n\n$table_list" \
            --width=400 --height=300
    fi
}

drop_table() {
    table_name=$(zenity --entry \
        --title="Drop Table" \
        --text="Enter table name to delete:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ -f "$table_file" ]; then
        if zenity --question \
            --text="WARNING: This will delete table '$table_name' and all its data!\n\nAre you sure you want to continue?" \
            --width=400; then
            rm "$table_file"
            zenity --info --text="Table '$table_name' deleted successfully!" --width=300
        fi
    else
        zenity --error --text="Error: Table '$table_name' does not exist!" --width=300
    fi
}

insert_into_table() {
    table_name=$(zenity --entry \
        --title="Insert Data" \
        --text="Enter table name:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        zenity --error --text="Error: Table '$table_name' does not exist!" --width=300
        return
    fi
    
    headers=$(sed -n '3p' "$table_file")
    types=$(sed -n '4p' "$table_file")
    primary_key=$(sed -n '2p' "$table_file" | cut -d':' -f2 | xargs)
    
    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"
    
    row_data=()
    
    for ((i=0; i<${#header_array[@]}; i++)); do
        while true; do
            value=$(zenity --entry \
                --title="Insert Data" \
                --text="Enter value for ${header_array[i]} (${type_array[i]}):" \
                --width=300 2>/dev/null)
            
            if [ $? -ne 0 ]; then
                return
            fi
            
            if [ "${type_array[i]}" = "int" ]; then
                if [[ "$value" =~ ^[0-9]+$ ]]; then
                    break
                else
                    zenity --error --text="Please enter a valid integer!" --width=300
                fi
            else
                if [ ! -z "$value" ]; then
                    break
                else
                    zenity --error --text="Value cannot be empty!" --width=300
                fi
            fi
        done
        
        row_data+=("$value")
    done
    
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
            
            if grep -q "|$pk_value|" "$table_file" 2>/dev/null || grep -q "^$pk_value|" "$table_file" 2>/dev/null || grep -q "|$pk_value$" "$table_file" 2>/dev/null; then
                zenity --error --text="Error: Primary key '$pk_value' already exists!" --width=300
                return
            fi
        fi
    fi
    
    row_string=""
    for ((i=0; i<${#row_data[@]}; i++)); do
        if [ $i -eq 0 ]; then
            row_string="${row_data[i]}"
        else
            row_string="$row_string|${row_data[i]}"
        fi
    done
    
    echo "$row_string" >> "$table_file"
    zenity --info --text="Data inserted successfully!" --width=300
}

select_from_table() {
    table_name=$(zenity --entry \
        --title="Select Data" \
        --text="Enter table name:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        zenity --error --text="Error: Table '$table_name' does not exist!" --width=300
        return
    fi
    
    headers=$(sed -n '3p' "$table_file")
    data_content=$(tail -n +5 "$table_file" | grep -v '^$')
    data_rows=$(echo "$data_content" | wc -l)
    
    if [ -z "$data_content" ]; then
        zenity --info --text="Table '$table_name' is empty." --width=300
    else
        display_text="Headers: $headers\n\n$data_content\n\nTotal rows: $data_rows"
        zenity --info --title="Data in Table: $table_name" \
            --text="$display_text" \
            --width=600 --height=400
    fi
}

delete_from_table() {
    table_name=$(zenity --entry \
        --title="Delete Data" \
        --text="Enter table name:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        zenity --error --text="Error: Table '$table_name' does not exist!" --width=300
        return
    fi
    
    headers=$(sed -n '3p' "$table_file")
    
    row_options=""
    row_num=1
    while read -r line; do
        if [ ! -z "$line" ]; then
            row_options="$row_options FALSE $row_num $line"
            row_num=$((row_num + 1))
        fi
    done < <(tail -n +5 "$table_file")
    
    if [ -z "$row_options" ]; then
        zenity --info --text="Table '$table_name' is empty." --width=300
        return
    fi
    
    selected_row=$(zenity --list --radiolist \
        --title="Delete Row" \
        --text="Headers: $headers\n\nSelect row to delete:" \
        --column="Select" --column="Row#" --column="Data" \
        --width=700 --height=400 \
        $row_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$selected_row" ]; then
        return
    fi
    
    if zenity --question \
        --text="Are you sure you want to delete row $selected_row?" \
        --width=300; then
        
        temp_file="/tmp/dbms_temp.txt"
        head -4 "$table_file" > "$temp_file"
        current_row=1
        
        while read -r line; do
            if [ ! -z "$line" ]; then
                if [ "$current_row" -ne "$selected_row" ]; then
                    echo "$line" >> "$temp_file"
                fi
                current_row=$((current_row + 1))
            fi
        done < <(tail -n +5 "$table_file")
        
        mv "$temp_file" "$table_file"
        zenity --info --text="Row deleted successfully!" --width=300
    fi
}

update_table() {
    table_name=$(zenity --entry \
        --title="Update Data" \
        --text="Enter table name:" \
        --width=300 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$table_name" ]; then
        return
    fi
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        zenity --error --text="Error: Table '$table_name' does not exist!" --width=300
        return
    fi
    
    headers=$(sed -n '3p' "$table_file")
    
    row_options=""
    row_num=1
    while read -r line; do
        if [ ! -z "$line" ]; then
            row_options="$row_options FALSE $row_num $line"
            row_num=$((row_num + 1))
        fi
    done < <(tail -n +5 "$table_file")
    
    if [ -z "$row_options" ]; then
        zenity --info --text="Table '$table_name' is empty." --width=300
        return
    fi
    
    selected_row=$(zenity --list --radiolist \
        --title="Update Row" \
        --text="Headers: $headers\n\nSelect row to update:" \
        --column="Select" --column="Row#" --column="Data" \
        --width=700 --height=400 \
        $row_options 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$selected_row" ]; then
        return
    fi
    
    headers=$(sed -n '3p' "$table_file")
    types=$(sed -n '4p' "$table_file")
    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"
    
    old_row=$(tail -n +5 "$table_file" | sed -n "${selected_row}p")
    IFS='|' read -ra old_data <<< "$old_row"
    
    new_row_data=()
    
    for ((i=0; i<${#header_array[@]}; i++)); do
        while true; do
            value=$(zenity --entry \
                --title="Update Data" \
                --text="Enter new value for ${header_array[i]} (${type_array[i]})\nCurrent value: ${old_data[i]}\n(Leave empty to keep current value)" \
                --width=400 2>/dev/null)
            
            if [ $? -ne 0 ]; then
                return
            fi
            
            if [ -z "$value" ]; then
                value="${old_data[i]}"
            fi
            
            if [ "${type_array[i]}" = "int" ]; then
                if [[ "$value" =~ ^[0-9]+$ ]]; then
                    break
                else
                    zenity --error --text="Please enter a valid integer!" --width=300
                fi
            else
                if [ ! -z "$value" ]; then
                    break
                else
                    zenity --error --text="Value cannot be empty!" --width=300
                fi
            fi
        done
        
        new_row_data+=("$value")
    done
    
    new_row_string=""
    for ((i=0; i<${#new_row_data[@]}; i++)); do
        if [ $i -eq 0 ]; then
            new_row_string="${new_row_data[i]}"
        else
            new_row_string="$new_row_string|${new_row_data[i]}"
        fi
    done
    
    temp_file="/tmp/dbms_temp.txt"
    head -4 "$table_file" > "$temp_file"
    current_row=1
    
    while read -r line; do
        if [ ! -z "$line" ]; then
            if [ "$current_row" -eq "$selected_row" ]; then
                echo "$new_row_string" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
            current_row=$((current_row + 1))
        fi
    done < <(tail -n +5 "$table_file")
    
    mv "$temp_file" "$table_file"
    zenity --info --text="Row updated successfully!" --width=300
}

main() {
    zenity --info \
        --title="Welcome to Bash DBMS" \
        --text="Welcome to Bash DBMS\n\nTeam:\n1 - Yassen Mohamed Abdulhamid\n2 - Mostafa Mohamed Abdullatif\n3 - Abdulrahman Raafat\n4 - Ahmed Atef" \
        --width=400
    
    while true; do
        choice=$(show_main_menu)
        if [ $? -ne 0 ]; then
            break
        fi
        
        case $choice in
            "1") create_database ;;
            "2") list_databases ;;
            "3") connect_database ;;
            "4") drop_database ;;
            "5") 
                zenity --info --text="Thank you for using Bash DBMS!\nGoodbye!" --width=300
                exit 0
                ;;
            *) 
                zenity --error --text="Invalid option! Please choose a valid option." --width=300
                ;;
        esac
    done
}

main
