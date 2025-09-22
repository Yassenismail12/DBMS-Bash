#!/bin/bash

# colors 
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

current_database=""
script_dir=$(pwd) # Get current directory where script is located

# Enhanced warning function
show_warning() {
    local message="$1"
    local action="$2"
    
    echo ""
    echo -e "${RED}⚠️  WARNING ⚠️${NC}"
    echo -e "${RED}================================${NC}"
    echo -e "${YELLOW}$message${NC}"
    echo -e "${RED}================================${NC}"
    echo ""
    echo -e "${RED}This action cannot be undone!${NC}"
    echo ""
    echo -n "Type 'YES' (in capital letters) to confirm $action: "
    read confirmation
    
    if [ "$confirmation" = "YES" ]; then
        return 0  # Confirmed
    else
        echo -e "${GREEN}Operation cancelled for safety.${NC}"
        read -p "Press Enter to continue..."
        return 1  # Not confirmed
    fi
}

# Enhanced confirmation for updates
show_update_warning() {
    local table_name="$1"
    local row_number="$2"
    
    echo ""
    echo -e "${YELLOW}⚠️  UPDATE CONFIRMATION ⚠️${NC}"
    echo -e "${YELLOW}============================${NC}"
    echo -e "You are about to update row $row_number in table '$table_name'"
    echo -e "Original data will be permanently replaced."
    echo -e "${YELLOW}============================${NC}"
    echo ""
    echo -n "Are you sure you want to proceed? (yes/no): "
    read confirmation
    
    if [ "$confirmation" = "yes" ]; then
        return 0  # Confirmed
    else
        echo -e "${GREEN}Update operation cancelled.${NC}"
        read -p "Press Enter to continue..."
        return 1  # Not confirmed
    fi
}

# display the main menu
show_main_menu() {
    clear
    echo "=================================="
    echo "       MAIN MENU   "
    echo "=================================="
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"
    echo "=================================="
    echo -n "Please select an option (1-5): "
}

#when connected to a exist db
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

# create a new db
create_database() {
    echo ""
    echo -e "${BLUE}Creating a new database...${NC}"
    echo -n "Enter database name: "
    read db_name
    
    # Check if database name is empty
    if [ -z "$db_name" ]; then
        echo -e "${RED}Error: Database name cannot be empty!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # dir for each database
    if [ -d "$script_dir/$db_name" ]; then
        echo -e "${RED}Error: Database '$db_name' already exists!${NC}"
    else
        mkdir "$script_dir/$db_name"
        echo -e "${GREEN}Database '$db_name' created successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# list all databases
list_databases() {
    echo ""
    echo -e "${BLUE}Available Databases:${NC}"
    echo "===================="
    
    # Count databases
    db_count=0
    
    # Loop through directories in current folder
    for dir in */; do
        if [ -d "$dir" ]; then
            db_count=$((db_count + 1))
            echo "$db_count. ${dir%/}" # Remove trailing slash
        fi
    done
    
    # validate databases 
    if [ $db_count -eq 0 ]; then
        echo "No databases found!"
    fi
    
    read -p "Press Enter to continue..."
}

#connect to exist database
connect_database() {
    echo ""
    echo -e "${BLUE}Connect to Database:${NC}"
    echo -n "Enter database name: "
    read db_name
    
    # Check if database name is empty
    if [ -z "$db_name" ]; then
        echo -e "${RED}Error: Database name cannot be empty!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # database existance
    if [ -d "$script_dir/$db_name" ]; then
        current_database="$db_name"
        echo -e "${GREEN}Connected to database '$db_name'${NC}"
        read -p "Press Enter to continue..."
        
        # Show database menu until user goes back
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
    
    # Check if database exists
    if [ -d "$script_dir/$db_name" ]; then
        # Enhanced warning for database deletion
        if show_warning "You are about to DELETE the entire database '$db_name'!\nAll tables and data inside this database will be PERMANENTLY LOST!" "database deletion"; then
            rm -rf "$script_dir/$db_name"
            echo -e "${GREEN}Database '$db_name' deleted successfully!${NC}"
        fi
    else
        echo -e "${RED}Error: Database '$db_name' does not exist!${NC}"
        read -p "Press Enter to continue..."
    fi
}

# create a table
create_table() {
    echo ""
    echo -e "${BLUE}Create Table in Database: $current_database${NC}"
    echo -n "Enter table name: "
    read table_name
    
    # Check if table name is empty
    if [ -z "$table_name" ]; then
        echo -e "${RED}Error: Table name cannot be empty!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Check if table already exists
    if [ -f "$script_dir/$current_database/$table_name.txt" ]; then
        echo -e "${RED}Error: Table '$table_name' already exists!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    #take number of columns
    echo -n "Enter number of columns: "
    read num_columns
    
    # validate number of columns
    if ! [[ "$num_columns" =~ ^[0-9]+$ ]] || [ "$num_columns" -lt 1 ]; then
        echo -e "${RED}Error: Invalid number of columns!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # store column info in arrays 
    column_names=()
    column_types=()
    primary_key=""
    
    # Get column information
    echo ""
    echo "Enter column details:"
    for ((i=1; i<=num_columns; i++)); do
        echo -n "Column $i name: "
        
        while true ; do
            read col_name
            #validate column name
            if [[ " ${column_names[@]} " =~ " $col_name " ]]; then
                echo "$col_name already exists, try another name please!"
            else	
                column_names+=("$col_name")
                break;
            fi 
        done	
       
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
    
    # take primary key
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
    
    # table structure file
    table_file="$script_dir/$current_database/$table_name.txt"
    
    # (first line)table metadata
    echo "# Table: $table_name" > "$table_file"
    echo "# Primary Key: $primary_key" >> "$table_file"
    
    # Write column headers
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
    
    # Loop through .txt files in database directory
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
        # Enhanced warning for table deletion
        if show_warning "You are about to DELETE table '$table_name'!\nAll data in this table will be PERMANENTLY LOST!" "table deletion"; then
            rm "$table_file"
            echo -e "${GREEN}Table '$table_name' deleted successfully!${NC}"
        fi
    else
        echo -e "${RED}Error: Table '$table_name' does not exist!${NC}"
        read -p "Press Enter to continue..."
    fi
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

    # Read table structure
    # get headers and types
    headers=$(sed -n '3p' "$table_file")
    types=$(sed -n '4p' "$table_file")
    primary_key=$(sed -n '2p' "$table_file" | cut -d':' -f2 | xargs)
    
    # Convert to arrays
    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"
    
    echo ""
    echo "Enter data for each column:"
    
    # Array to store the new row data
    row_data=()
    
    # Get data for each column
    for ((i=0; i<${#header_array[@]}; i++)); do
        while true; do
            echo -n "${header_array[i]} (${type_array[i]}): "
            read value
            
            # Validate data type
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
    
    # Check primary key constraint
    if [ ! -z "$primary_key" ]; then
        # Find primary key column index
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
            if grep -q "|$pk_value|" "$table_file" 2>/dev/null || grep -q "^$pk_value|" "$table_file" 2>/dev/null || grep -q "|$pk_value$" "$table_file" 2>/dev/null; then
                echo -e "${RED}Error: Primary key '$pk_value' already exists!${NC}"
                read -p "Press Enter to continue..."
                return
            fi
        fi
    fi
    
    # Build the row string
    row_string=""
    for ((i=0; i<${#row_data[@]}; i++)); do
        if [ $i -eq 0 ]; then
            row_string="${row_data[i]}"
        else
            row_string="$row_string|${row_data[i]}"
        fi
    done
    
    # Show insertion confirmation
    echo ""
    echo -e "${YELLOW}Data to be inserted:${NC}"
    echo -e "${BLUE}$headers${NC}"
    echo "$row_string"
    echo ""
    echo -n "Confirm insertion? (yes/no): "
    read confirm
    
    if [ "$confirm" = "yes" ]; then
        # Add the row to the file
        echo "$row_string" >> "$table_file"
        echo -e "${GREEN}Data inserted successfully!${NC}"
    else
        echo -e "${YELLOW}Data insertion cancelled.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# select data from table
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

# delete from table
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
    echo "Current data in table '$table_name':"
    echo "===================================="
    headers=$(sed -n '3p' "$table_file")
    echo -e "${BLUE}$headers${NC}"
    echo "===================================="
    
    # Show data with row numbers
    tail -n +5 "$table_file" | cat -n  
    
    echo ""
    echo -n "Enter row number to delete (0 to cancel): "
    read row_to_delete
    
    if [ "$row_to_delete" = "0" ]; then
        echo "Delete operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi  
    
    row_to_del=$((row_to_delete + 4))
    total_rows=$(wc -l < "$table_file")  
    
    # validate row number
    if ! [[ "$row_to_delete" =~ ^[0-9]+$ ]] || [ "$row_to_delete" -lt 1 ]; then
        echo -e "${RED}Error: Invalid row number!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Check if row exists
    actual_data_rows=$(tail -n +5 "$table_file" | grep -c .)
    if [ "$row_to_delete" -gt "$actual_data_rows" ]; then
        echo -e "${RED}Error: Row number $row_to_delete does not exist!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Show the row to be deleted
    row_to_show=$(tail -n +5 "$table_file" | sed -n "${row_to_delete}p")
    
    # Enhanced warning for row deletion
    if show_warning "You are about to DELETE row $row_to_delete from table '$table_name':\n\n${BLUE}$headers${NC}\n$row_to_show\n\nThis data will be PERMANENTLY LOST!" "row deletion"; then
        sed -i "${row_to_del}d" "$table_file"
        echo -e "${GREEN}Row deleted successfully!${NC}"
    fi
}

# update table
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
    
    # Show rows with numbers
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
    
    # validate row number
    total_rows=$(tail -n +5 "$table_file" | grep -c .)
    if ! [[ "$row_to_update" =~ ^[0-9]+$ ]] || [ "$row_to_update" -lt 1 ] || [ "$row_to_update" -gt "$total_rows" ]; then
        echo -e "${RED}Error: Invalid row number!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Show update warning
    if ! show_update_warning "$table_name" "$row_to_update"; then
        return
    fi
    
    # Get table structure
    headers=$(sed -n '3p' "$table_file")
    types=$(sed -n '4p' "$table_file")
    
    # Convert to arrays
    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"
    
    # Get current row data
    old_row=$(tail -n +5 "$table_file" | sed -n "${row_to_update}p")
    IFS='|' read -ra old_data <<< "$old_row"
    
    echo ""
    echo "Enter new data (press Enter to keep current value):"
    
    # Array to store new data
    new_row_data=()
    
    # Get data for each column
    for ((i=0; i<${#header_array[@]}; i++)); do
        while true; do
            echo -n "${header_array[i]} (${type_array[i]}) [current: ${old_data[i]}]: "
            read value
            
            # If empty, keep current value
            if [ -z "$value" ]; then
                value="${old_data[i]}"
            fi
            
            # Validate data type
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
    
    # Build new row string
    new_row_string=""
    for ((i=0; i<${#new_row_data[@]}; i++)); do
        if [ $i -eq 0 ]; then
            new_row_string="${new_row_data[i]}"
        else
            new_row_string="$new_row_string|${new_row_data[i]}"
        fi
    done
    
    # Show before and after comparison
    echo ""
    echo -e "${YELLOW}Update Summary:${NC}"
    echo "================="
    echo -e "${BLUE}$headers${NC}"
    echo -e "Old: ${RED}$old_row${NC}"
    echo -e "New: ${GREEN}$new_row_string${NC}"
    echo ""
    echo -n "Confirm update? (yes/no): "
    read final_confirm
    
    if [ "$final_confirm" = "yes" ]; then
        # Create temp file
        temp_file="/tmp/dbms_temp.txt"
        
        # Copy header
        head -4 "$table_file" > "$temp_file"
        
        # Copy rows with update
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
        
        # Replace original file
        mv "$temp_file" "$table_file"
        
        echo -e "${GREEN}Row updated successfully!${NC}"
    else
        echo -e "${YELLOW}Update operation cancelled.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Main function
main() {
    echo -e "${GREEN}Welcome to Bash DBMS!${NC}"
    echo "Team 2 Bash DBMS - Enhanced Version with Safety Warnings"
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
                echo ""
                echo -e "${YELLOW}Are you sure you want to exit? (yes/no): ${NC}"
                read exit_confirm
                if [ "$exit_confirm" = "yes" ]; then
                    echo -e "${GREEN}Thank you for using Bash DBMS!${NC}"
                    echo "Goodbye!"
                    exit 0
                fi
                ;;
            *) 
                echo -e "${RED}Invalid option! Please choose 1-5.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Start the program
main
