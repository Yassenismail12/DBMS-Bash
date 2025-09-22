# Bash DBMS - Detailed Function Analysis

## Setup and Configuration

### Global Variables and Colors
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
current_database=""
script_dir=$(pwd)
```
- **Purpose**: Sets up ANSI color codes for terminal output formatting and initializes global state
- **Functionality**: `current_database` tracks the active database connection, `script_dir` stores the working directory

---

## Menu Display Functions

### `show_main_menu()`
```bash
show_main_menu() {
    clear
    echo "=================================="
    echo "   SIMPLE BASH DBMS - MAIN MENU   "
    echo "=================================="
    echo "1. Create Database"
    echo "2. List Databases" 
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"
    echo "=================================="
    echo -n "Please select an option (1-5): "
}
```
- **Purpose**: Displays the main navigation menu
- **Code Analysis**: Uses `clear` to refresh screen, presents numbered options with visual formatting
- **User Flow**: Entry point for all database-level operations

### `show_database_menu()`
```bash
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
```
- **Purpose**: Displays table-level operations menu when connected to a database
- **Code Analysis**: Shows current database name in header, provides all CRUD operations
- **Context Awareness**: Only accessible when `current_database` is set

---

## Database Management Functions

### `create_database()`
```bash
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
    
    # Create directory for the database
    if [ -d "$script_dir/$db_name" ]; then
        echo -e "${RED}Error: Database '$db_name' already exists!${NC}"
    else
        mkdir "$script_dir/$db_name"
        echo -e "${GREEN}Database '$db_name' created successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..."
}
```
- **Input Validation**: Checks for empty names using `[ -z "$db_name" ]`
- **Duplicate Prevention**: Uses `[ -d "$script_dir/$db_name" ]` to check if directory exists
- **File System Operation**: `mkdir` creates the database directory
- **Error Handling**: Clear error messages with color coding
- **User Experience**: Pause with "Press Enter to continue..."

### `list_databases()`
```bash
list_databases() {
    echo ""
    echo -e "${BLUE}Available Databases:${NC}"
    echo "===================="
    
    db_count=0
    
    for dir in */; do
        if [ -d "$dir" ]; then
            db_count=$((db_count + 1))
            echo "$db_count. ${dir%/}" # Remove trailing slash
        fi
    done
    
    if [ $db_count -eq 0 ]; then
        echo "No databases found!"
    fi
    
    read -p "Press Enter to continue..."
}
```
- **Directory Traversal**: `for dir in */` iterates through directories
- **Path Manipulation**: `${dir%/}` removes trailing slash using parameter expansion
- **Counter Logic**: Tracks and displays numbered list
- **Empty State Handling**: Shows message when no databases exist
- **Code Technique**: Uses shell globbing pattern `*/` to match directories only

### `connect_database()`
```bash
connect_database() {
    echo ""
    echo -e "${BLUE}Connect to Database:${NC}"
    echo -n "Enter database name: "
    read db_name
    
    if [ -z "$db_name" ]; then
        echo -e "${RED}Error: Database name cannot be empty!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
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
```
- **State Management**: Sets `current_database` global variable
- **Sub-menu Loop**: `while true` creates persistent database context
- **Case Statement**: Routes user choices to appropriate table functions
- **Context Exit**: Option 8 clears `current_database` and breaks loop
- **Validation**: Ensures database exists before connecting

### `drop_database()`
```bash
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
```
- **Safety Mechanism**: Requires explicit "yes" confirmation
- **Destructive Operation**: `rm -rf` removes directory and all contents
- **User Protection**: Clear warning message about data loss
- **Confirmation Logic**: Only proceeds if user types exactly "yes"

---

## Table Management Functions

### `create_table()`
This is the most complex function - let me break it into sections:

#### Input and Validation Section
```bash
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
```
- **File Check**: Uses `[ -f "path" ]` to check if table file exists
- **Naming Convention**: Tables stored as `.txt` files

#### Column Definition Section
```bash
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
```
- **Regex Validation**: `^[0-9]+$` ensures positive integer input
- **Array Initialization**: Creates arrays for column metadata
- **Data Structures**: Uses Bash arrays to store column information

#### Column Information Gathering
```bash
for ((i=1; i<=num_columns; i++)); do
    echo -n "Column $i name: "
    
    while true ; do
        read col_name
        if [[ " ${column_names[@]} " =~ " $col_name " ]]; then
            echo "$input already exist try another name please!"
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
```
- **Duplicate Prevention**: Checks if column name already exists in array
- **Array Search**: `[[ " ${column_names[@]} " =~ " $col_name " ]]` searches array elements
- **Array Append**: `column_names+=("$col_name")` adds to array
- **Type Selection**: Simple binary choice for data types

#### Primary Key Selection
```bash
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
```
- **Array Length**: `${#column_names[@]}` gets array size
- **Index Conversion**: Converts 1-based user input to 0-based array index
- **Bounds Checking**: Validates choice is within array bounds

#### File Creation Section
```bash
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
```
- **File Structure**: Creates 4-line header (metadata, primary key, column names, types)
- **String Building**: Constructs pipe-separated strings
- **File Operations**: `>` creates/overwrites, `>>` appends

### `list_tables()`
```bash
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
```
- **Pattern Matching**: `*.txt` glob pattern matches table files
- **File Extraction**: `basename "$file" .txt` removes path and extension
- **Counter Display**: Shows numbered list of tables

### `drop_table()`
```bash
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
```
- **Similar Pattern**: Follows same confirmation pattern as drop_database
- **File Deletion**: `rm "$table_file"` removes single file (not recursive)

---

## Data Manipulation Functions

### `insert_into_table()`
This function handles data insertion with validation:

#### Table Structure Reading
```bash
headers=$(sed -n '3p' "$table_file")
types=$(sed -n '4p' "$table_file")
primary_key=$(sed -n '2p' "$table_file" | cut -d':' -f2 | xargs)

IFS='|' read -ra header_array <<< "$headers"
IFS='|' read -ra type_array <<< "$types"
```
- **sed Commands**: `sed -n '3p'` extracts specific line numbers
- **String Processing**: `cut -d':' -f2` splits on colon, takes second field
- **xargs**: Trims whitespace
- **Array Conversion**: `IFS='|' read -ra` splits string into array using pipe delimiter

#### Data Input and Validation
```bash
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
```
- **Type Validation**: Different validation for int vs string types
- **Loop Until Valid**: `while true` with `break` ensures valid input
- **Regex Matching**: `^[0-9]+$` validates integer format

#### Primary Key Constraint Checking
```bash
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
        
        if grep -q "|$pk_value|" "$table_file" 2>/dev/null || 
           grep -q "^$pk_value|" "$table_file" 2>/dev/null || 
           grep -q "|$pk_value$" "$table_file" 2>/dev/null; then
            echo -e "${RED}Error: Primary key '$pk_value' already exists!${NC}"
            read -p "Press Enter to continue..."
            return
        fi
    fi
fi
```
- **Index Finding**: Linear search to find primary key column index
- **Pattern Matching**: Multiple grep patterns to catch PK at different positions
- **Error Suppression**: `2>/dev/null` suppresses error messages

#### Row Construction and Storage
```bash
row_string=""
for ((i=0; i<${#row_data[@]}; i++)); do
    if [ $i -eq 0 ]; then
        row_string="${row_data[i]}"
    else
        row_string="$row_string|${row_data[i]}"
    fi
done

echo "$row_string" >> "$table_file"
```
- **String Building**: Constructs pipe-separated row
- **File Append**: Adds new row to end of table file

### `select_from_table()`
```bash
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
```
- **File Slice**: `tail -n +5` starts from line 5 (skipping headers)
- **Line Processing**: `while read -r line` processes each data row
- **Row Counting**: `wc -l` counts total lines
- **Display Formatting**: Headers in blue, data in default color

### `delete_from_table()`
```bash
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
    tail -n +5 $table_file | cat -n  
    
    echo ""
    echo -n "Enter row number to delete (0 to cancel): "
    read row_to_delete
    
    row_to_del=$((row_to_delete + 4))
    
    if [ "$row_to_delete" = "0" ]; then
        echo "Delete operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi  
    
    total_rows=$(wc -l < "$table_file")  
    
    if ! [[ "$row_to_del" =~ ^[0-9]+$ ]] || [ "$row_to_del" -lt 1 ] || [ "$row_to_del" -gt "$total_rows" ]; then
        echo -e "${RED}Error: Invalid row number!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
 
    sed -i "${row_to_del}d" "$table_file"
    
    echo -e "${GREEN}Row deleted successfully!${NC}"
    read -p "Press Enter to continue..."
}
```
- **Row Display**: `cat -n` numbers the output lines
- **Index Calculation**: `row_to_del=$((row_to_delete + 4))` adjusts for header lines
- **In-place Editing**: `sed -i "${row_to_del}d"` deletes specific line number
- **Bounds Validation**: Checks row number against total file lines

### `update_table()`
This is the most complex data function:

#### Current Data Display
```bash
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
```
- **Numbered Display**: Shows current data with row numbers

#### Row Selection and Validation
```bash
echo -n "Enter row number to update (0 to cancel): "
read row_to_update

total_rows=$(tail -n +5 "$table_file" | grep -c .)
if ! [[ "$row_to_update" =~ ^[0-9]+$ ]] || [ "$row_to_update" -lt 1 ] || [ "$row_to_update" -gt "$total_rows" ]; then
    echo -e "${RED}Error: Invalid row number!${NC}"
    read -p "Press Enter to continue..."
    return
fi
```
- **Line Counting**: `grep -c .` counts non-empty lines
- **Range Validation**: Ensures row number is within valid range

#### Current Value Preservation
```bash
old_row=$(tail -n +5 "$table_file" | sed -n "${row_to_update}p")
IFS='|' read -ra old_data <<< "$old_row"

echo "Enter new data (press Enter to keep current value):"

for ((i=0; i<${#header_array[@]}; i++)); do
    while true; do
        echo -n "${header_array[i]} (${type_array[i]}) [current: ${old_data[i]}]: "
        read value
        
        if [ -z "$value" ]; then
            value="${old_data[i]}"
        fi
        # ... validation logic ...
    done
    new_row_data+=("$value")
done
```
- **Old Data Extraction**: Gets existing values for display
- **Default Values**: Empty input keeps current value
- **User-Friendly**: Shows current value in prompt

#### File Update with Temporary File
```bash
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
```
- **Atomic Update**: Uses temporary file to prevent corruption
- **Header Preservation**: Copies first 4 lines unchanged
- **Selective Replace**: Only updates target row
- **File Replacement**: `mv` makes change atomic

---

## Main Program Controller

### `main()`
```bash
main() {
    echo -e "${GREEN}Welcome to Simple Bash DBMS!${NC}"
    echo "This is a beginner-friendly database management system."
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
```
- **Program Entry**: Welcome message and initialization
- **Infinite Loop**: `while true` keeps program running until exit
- **Function Dispatch**: Case statement routes to appropriate functions
- **Clean Exit**: Option 5 provides graceful program termination
- **Error Handling**: Catches invalid menu choices

---

## Key Programming Techniques Used

1. **Array Manipulation**: Dynamic arrays for column management
2. **String Processing**: IFS manipulation, parameter expansion
3. **File I/O**: Reading specific lines with sed, appending data
4. **Input Validation**: Regex patterns, range checking
5. **State Management**: Global variables for database context
6. **Error Handling**: Consistent error messaging and user feedback
7. **Menu Systems**: Nested menu structures with proper navigation
8. **Data Integrity**: Primary key constraints, type validation
9. **File System Operations**: Directory and file manipulation
10. **User Interface**: Color coding, formatting, confirmation dialogs
