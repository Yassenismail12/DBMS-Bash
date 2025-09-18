#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variables
current_database=""
script_dir=$(pwd) 

# display the main menu
show_main_menu() {
    clear
    echo "=================================="
    echo "Team 2"
    echo "=================================="
    echo "   BASH DBMS - MAIN MENU   "
    echo "=================================="
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"
    echo "=================================="
    echo -n "Please select an option (1-5): "
}

# display database menu (when connected to a database)
show_database_menu() {
    clear
    echo "========================================"
    echo "   DATABASE: $current_database"
    echo "========================================"
    echo "1. Create Table"
    echo "2. List Tables"
    echo "3. Drop Table"
    echo "4. Insert into Table"
    echo "5. Select From Table"
    echo "6. Delete From Table"
    echo "7. Update Table"
    echo "8. Back to Main Menu"
    echo "========================================"
    echo -n "Please select an option (1-8): "
}

# create a new database
create_database() {
    echo ""
    echo -e "${BLUE}Creating a new database...${NC}"
    echo -n "Enter database name: "
    read db_name
    
    if [ -z "$db_name" ]; then
        echo -e "${RED}Error: Database name cannot be empty!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    if [ -d "$script_dir/$db_name" ]; then
        echo -e "${RED}Error: Database '$db_name' already exists!${NC}"
    else
        mkdir "$script_dir/$db_name"
        echo -e "${GREEN}Database '$db_name' created successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to list all databases
list_databases() {
    echo ""
    echo -e "${BLUE}Available Databases:${NC}"
    echo "===================="
    db_count=0
    for dir in */; do
        if [ -d "$dir" ]; then
            db_count=$((db_count + 1))
            echo "$db_count. ${dir%/}" 
        fi
    done
    if [ $db_count -eq 0 ]; then
        echo "No databases found!"
    fi
    read -p "Press Enter to continue..."
}

# connect to a database
connect_database() {
    echo ""
    echo -e "${BLUE}Connect to Database:${NC}"
    echo -n "Enter database name: "
    read db_name
    if [ -d "$script_dir/$db_name" ]; then
        current_database="$db_name"
        echo -e "${GREEN}Connected to database '$db_name'${NC}"
        read -p "Press Enter to continue..."

        while true; do
            show_database_menu
            read choice
            
            case $choice in
                1) create_table ;;
                2) list_tables ;;
                3) drop_table ;;
                4) insert_into_table ;;
                5) select_from_table ;;
                6) delete_from_table ;;
                7) update_table ;;
                8) current_database=""; break ;;
                *) echo -e "${RED}Invalid option!${NC}"; read -p "Press Enter to continue..." ;;
            esac
        done
    else
        echo -e "${RED}Error: Database '$db_name' does not exist!${NC}"
        read -p "Press Enter to continue..."
    fi
}

# drop/delete a database
drop_database() {
    echo ""
    echo -e "${BLUE}Drop Database:${NC}"
    echo -n "Enter database name to delete: "
    read db_name
    
    if [ -d "$script_dir/$db_name" ]; then
        echo -e "${RED}WARNING: This will delete the entire database and all its data!${NC}"
        echo -n "Are you sure? (yes/no): "
        read confirm
        
        if [ "$confirm" = "yes" ]; then
            rm -rf "$script_dir/$db_name"
            echo -e "${GREEN}Database '$db_name' deleted successfully!${NC}"
        else
            echo "Database deletion cancelled."
        fi
    else
        echo -e "${RED}Error: Database '$db_name' does not exist!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

create_table() {
    echo ""
    echo -e "${BLUE}Create Table in Database: $current_database${NC}"
    echo -n "Enter table name: "
    read table_name
    
    if [ -z "$table_name" ]; then
        echo -e "${RED}Error: Table name cannot be empty!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    if [ -f "$script_dir/$current_database/$table_name.txt" ]; then
        echo -e "${RED}Error: Table '$table_name' already exists!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -n "Enter number of columns: "
    read num_columns
    
    if ! [[ "$num_columns" =~ ^[0-9]+$ ]] || [ "$num_columns" -lt 1 ]; then
        echo -e "${RED}Error: Invalid number of columns!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    column_names=()
    column_types=()
    primary_key=""
    echo ""
    echo "Enter column details:"
    for ((i=1; i<=num_columns; i++)); do
        echo -n "Column $i name: "
        read col_name
        column_names+=("$col_name")
        
        echo "Column $i data type:"
        echo "1. int (integer)"
        echo "2. str (string)"
        echo -n "Choose (1 or 2): "
        read col_type_choice
        
        if [ "$col_type_choice" = "1" ]; then
            column_types+=("int")
        else
            column_types+=("str")
        fi
    done
    echo ""
    echo "Available columns for primary key:"
    for ((i=0; i<${#column_names[@]}; i++)); do
        echo "$((i+1)). ${column_names[i]}"
    done
    echo -n "Choose primary key column number (or 0 for none): "
    read pk_choice
    
    if [ "$pk_choice" -gt 0 ] && [ "$pk_choice" -le "${#column_names[@]}" ]; then
        primary_key="${column_names[$((pk_choice-1))]}"
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

    echo -e "${GREEN}Table '$table_name' created successfully!${NC}"
    read -p "Press Enter to continue..."
}

# list all tables
list_tables() {
    echo ""
    echo -e "${BLUE}Tables in Database: $current_database${NC}"
    echo "=========================="
    
    table_count=0
    
    for file in "$script_dir/$current_database"/*.txt; do
        if [ -f "$file" ]; then
            table_count=$((table_count + 1))
            table_name=$(basename "$file" .txt)
            echo "$table_count. $table_name"
        fi
    done
    
    if [ $table_count -eq 0 ]; then
        echo "No tables found in this database!"
    fi
    
    read -p "Press Enter to continue..."
}

# drop/delete a table
drop_table() {
    echo ""
    echo -e "${BLUE}Drop Table from Database: $current_database${NC}"
    echo -n "Enter table name to delete: "
    read table_name
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ -f "$table_file" ]; then
        echo -e "${RED}WARNING: This will delete the table and all its data!${NC}"
        echo -n "Are you sure? (yes/no): "
        read confirm
        
        if [ "$confirm" = "yes" ]; then
            rm "$table_file"
            echo -e "${GREEN}Table '$table_name' deleted successfully!${NC}"
        else
            echo "Table deletion cancelled."
        fi
    else
        echo -e "${RED}Error: Table '$table_name' does not exist!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# insert data into table
insert_into_table() {
    echo ""
    echo -e "${BLUE}Insert Data into Table${NC}"
    echo -n "Enter table name: "
    read table_name
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        echo -e "${RED}Error: Table '$table_name' does not exist!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    headers=$(sed -n '3p' "$table_file")
    types=$(sed -n '4p' "$table_file")
    primary_key=$(sed -n '2p' "$table_file" | cut -d':' -f2 | xargs)
    
    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"
    
    echo ""
    echo "Enter data for each column:"

    row_data=()

    for ((i=0; i<${#header_array[@]}; i++)); do
        while true; do
            echo -n "${header_array[i]} (${type_array[i]}): "
            read value
            
            if [ "${type_array[i]}" = "int" ]; then
                if [[ "$value" =~ ^[0-9]+$ ]]; then
                    break
                else
                    echo -e "${RED}Error: Please enter a valid integer!${NC}"
                fi
            else
                if [ ! -z "$value" ]; then
                    break
                else
                    echo -e "${RED}Error: Value cannot be empty!${NC}"
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
                echo -e "${RED}Error: Primary key '$pk_value' already exists!${NC}"
                read -p "Press Enter to continue..."
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
    
    echo -e "${GREEN}Data inserted successfully!${NC}"
    read -p "Press Enter to continue..."
}

# select/display data from table
select_from_table() {
    echo ""
    echo -e "${BLUE}Select Data from Table${NC}"
    echo -n "Enter table name: "
    read table_name
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        echo -e "${RED}Error: Table '$table_name' does not exist!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo -e "${GREEN}Data in table '$table_name':${NC}"
    echo "=================================="
    
    headers=$(sed -n '3p' "$table_file")
    echo -e "${BLUE}$headers${NC}"
    echo "=================================="
    
    row_count=0
    tail -n +5 "$table_file" | while read -r line; do
        if [ ! -z "$line" ]; then
            echo "$line"
            row_count=$((row_count + 1))
        fi
    done
    
    data_rows=$(tail -n +5 "$table_file" | wc -l)
    echo "=================================="
    echo "Total rows: $data_rows"
    
    read -p "Press Enter to continue..."
}

# delete data from table (simple version)
delete_from_table() {
    echo ""
    echo -e "${BLUE}Delete Data from Table${NC}"
    echo -n "Enter table name: "
    read table_name
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        echo -e "${RED}Error: Table '$table_name' does not exist!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo "Current data in table:"
    headers=$(sed -n '3p' "$table_file")
    echo -e "${BLUE}$headers${NC}"
    echo "=================================="
    
    row_num=1
    tail -n +5 "$table_file" | while read -r line; do
        if [ ! -z "$line" ]; then
            echo "$row_num. $line"
            row_num=$((row_num + 1))
        fi
    done
    
    echo ""
    echo -n "Enter row number to delete (0 to cancel): "
    read row_to_delete
    
    if [ "$row_to_delete" = "0" ]; then
        echo "Delete operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    total_rows=$(tail -n +5 "$table_file" | grep -c .)
    if ! [[ "$row_to_delete" =~ ^[0-9]+$ ]] || [ "$row_to_delete" -lt 1 ] || [ "$row_to_delete" -gt "$total_rows" ]; then
        echo -e "${RED}Error: Invalid row number!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    temp_file="/tmp/dbms_temp.txt"
    head -4 "$table_file" > "$temp_file"
    current_row=1
    tail -n +5 "$table_file" | while read -r line; do
        if [ ! -z "$line" ]; then
            if [ "$current_row" -ne "$row_to_delete" ]; then
                echo "$line" >> "$temp_file"
            fi
            current_row=$((current_row + 1))
        fi
    done
    mv "$temp_file" "$table_file"
    
    echo -e "${GREEN}Row deleted successfully!${NC}"
    read -p "Press Enter to continue..."
}

# update data in table (simple version)
update_table() {
    echo ""
    echo -e "${BLUE}Update Data in Table${NC}"
    echo -n "Enter table name: "
    read table_name
    
    table_file="$script_dir/$current_database/$table_name.txt"
    
    if [ ! -f "$table_file" ]; then
        echo -e "${RED}Error: Table '$table_name' does not exist!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    echo ""
    echo "Current data in table:"
    headers=$(sed -n '3p' "$table_file")
    echo -e "${BLUE}$headers${NC}"
    echo "=================================="
    row_num=1
    tail -n +5 "$table_file" | while read -r line; do
        if [ ! -z "$line" ]; then
            echo "$row_num. $line"
            row_num=$((row_num + 1))
        fi
    done
    echo ""
    echo -n "Enter row number to update (0 to cancel): "
    read row_to_update
    
    if [ "$row_to_update" = "0" ]; then
        echo "Update operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    total_rows=$(tail -n +5 "$table_file" | grep -c .)
    if ! [[ "$row_to_update" =~ ^[0-9]+$ ]] || [ "$row_to_update" -lt 1 ] || [ "$row_to_update" -gt "$total_rows" ]; then
        echo -e "${RED}Error: Invalid row number!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    headers=$(sed -n '3p' "$table_file")
    types=$(sed -n '4p' "$table_file")
    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"
    old_row=$(tail -n +5 "$table_file" | sed -n "${row_to_update}p")
    IFS='|' read -ra old_data <<< "$old_row"
    
    echo ""
    echo "Enter new data (press Enter to keep current value):"
    new_row_data=()
    
    for ((i=0; i<${#header_array[@]}; i++)); do
        while true; do
            echo -n "${header_array[i]} (${type_array[i]}) [current: ${old_data[i]}]: "
            read value
            
            if [ -z "$value" ]; then
                value="${old_data[i]}"
            fi
            if [ "${type_array[i]}" = "int" ]; then
                if [[ "$value" =~ ^[0-9]+$ ]]; then
                    break
                else
                    echo -e "${RED}Error: Please enter a valid integer!${NC}"
                fi
            else
                if [ ! -z "$value" ]; then
                    break
                else
                    echo -e "${RED}Error: Value cannot be empty!${NC}"
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
    tail -n +5 "$table_file" | while read -r line; do
        if [ ! -z "$line" ]; then
            if [ "$current_row" -eq "$row_to_update" ]; then
                echo "$new_row_string" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
            current_row=$((current_row + 1))
        fi
    done
    mv "$temp_file" "$table_file"
    
    echo -e "${GREEN}Row updated successfully!${NC}"
    read -p "Press Enter to continue..."
}

main() {
    echo -e "${GREEN}Welcome to Bash DBMS ${NC}"
    echo -e "Team :"
    echo -e "1 - Yassen Mohamed Abdulhamid"
    echo -e "2 - Mostafa Mohamed Abdullatif"
    echo -e "3 - Abdulrahman Raafat"
    echo -e "4 - Ahmed Atef"
    echo ""
    read -p "Press Enter to start..."
    while true; do
        show_main_menu
        read choice
        case $choice in
            1) create_database ;;
            2) list_databases ;;
            3) connect_database ;;
            4) drop_database ;;
            5) 
                echo -e "${GREEN}Thank you for using Simple Bash DBMS!${NC}"
                echo "Goodbye!"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option! Please choose 1-5.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

main
