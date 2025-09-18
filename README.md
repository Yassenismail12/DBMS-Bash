# Bash Database Management System 

This project is a **command-line Database Management System (DBMS)** written entirely in **Bash**.
It simulates database functionality using the **file system**, where:

* **Databases** → directories
* **Tables** → text files
* **Operations** → CRUD (Create, Read, Update, Delete)

The system emphasizes **simplicity, modularity, data validation, and a user-friendly interface**.

---

## Getting Started

Run the script in a Bash environment:

```bash
bash DBMS.bash
```

You will be greeted with an interactive, menu-driven interface to manage databases and tables.

---

## Core Concepts

* **File-Based Storage** → Directories represent databases, tables are `.txt` files.
* **Data Integrity** → Enforces primary key uniqueness and data type validation (`int`, `str`).
* **User Experience** → Color-coded terminal output, structured menus, and clear prompts.
* **Modular Design** → Each operation is encapsulated in its own function for clarity.

---

## Features

### Main Menu

1. **Create Database** → Creates a new folder.
2. **List Databases** → Displays available databases.
3. **Connect to Database** → Select a database and open the **Database Menu**.
4. **Drop Database** → Deletes a database folder and its contents.
5. **Exit** → Quits the system.

### Database Menu (when connected)

1. **Create Table** → Define columns and types, stored in a `.txt` file.
2. **List Tables** → Shows all tables in the active database.
3. **Drop Table** → Deletes a table file.
4. **Insert into Table** → Adds a new row, with validation.
5. **Select From Table** → Displays all rows with headers.
6. **Delete From Table** → Removes a specific row.
7. **Update Table** → Edits fields of an existing row.
8. **Back to Main Menu** → Disconnects from the current database.

---

## File & Data Organization

### Project Structure

```
project_directory/
├── database1/
│   ├── users.txt
│   └── products.txt
├── database2/
│   └── orders.txt
└── DBMS.bash
```

### Table File Format

Each table is a structured text file with metadata, schema, and rows.

**Example: `users.txt`**

```
# Table: users
# Primary Key: id
id|name|email|age
int|str|str|int
1|Mostafa Elelemy|Elelemy@example.com|25
2|Yassen mohamed|Yassen@example.com|30
```

* **Line 1–2** → Metadata (`# Table`, `# Primary Key`)
* **Line 3** → Column headers (`|` separated)
* **Line 4** → Data types (`int`, `str`)
* **Line 5+** → Actual data rows

---

## Technical Breakdown

### Setup & Configuration

```bash
# Colors
RED='\033[0;31m'    # Errors
GREEN='\033[0;32m'  # Success
BLUE='\033[0;34m'   # Info
NC='\033[0m'        # Reset

# Globals
current_database=""   # Active DB
script_dir=$(pwd)     # Script directory
```

### Bash Features Used

* **Arrays** → Manage columns and schema.
* **Regex** → Input validation (`[[ "$value" =~ ^[0-9]+$ ]]`).
* **I/O Redirection** → `>`, `>>`, `2>/dev/null`.
* **Parameter Expansion** → `${var%/}`, `${#array[@]}`.
* **Loops** → `for`, `while`, C-style loops.
* **Case & If** → Menu and validation logic.

### Error Handling

* Empty input checks.
* File/directory existence checks.
* Data type validation.
* Primary key uniqueness.

---

## Main Program Flow

```bash
main() {
    echo -e "${GREEN}Welcome to Bash DBMS${NC}"
    echo "Team:"
    echo "1 - Yassen Mohamed Abdulhamid"
    echo "2 - Mostafa Mohamed Abdullatif"
    echo "3 - Abdulrahman Raafat"
    echo "4 - Ahmed Atef"
    read -p "Press Enter to start..."

    while true; do
        show_main_menu
        read choice
        case $choice in
            1) create_database ;;
            2) list_databases ;;
            3) connect_database ;;
            4) drop_database ;;
            5) echo -e "${GREEN}Thank you for using Bash DBMS!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option!${NC}"; read -p "Press Enter..." ;;
        esac
    done
}
main
```

---

## Summary

This Bash DBMS provides:

* **File System as Database** → Directories & text files act like relational DB objects.
* **Full CRUD Support** → Databases and tables with validation.
* **Practical Learning Tool** → Teaches database concepts through Bash scripting.
* **User-Friendly Interface** → Menus, colors, clear error messages.
* **Robust Design** → Modular, validated, and error-handled.

 A compact yet powerful educational project that combines **database theory** with **advanced Bash scripting**.

---

# Bash DBMS – Function-by-Function Documentation

---

## Main Menu Functions

---

### 1. `create_database`

**Purpose:**
Create a new folder to represent a database.

**Code:**

```bash
create_database() {
    read -p "Enter database name: " dbname
    if [ -d "$dbname" ]; then
        echo -e "${RED}Error: Database already exists!${NC}"
    else
        mkdir "$dbname"
        echo -e "${GREEN}Database '$dbname' created successfully.${NC}"
    fi
}
```

**Explanation:**

* `read -p` → prompts the user inline: `"Enter database name:"`.
* `if [ -d "$dbname" ]` → checks if a directory exists (`-d` = directory).
* `echo -e` → `-e` enables color codes like `${RED}` and `${GREEN}`.
* `mkdir "$dbname"` → creates the directory (new database).

---

### 2. `list_databases`

**Purpose:**
Show all databases (directories).

**Code:**

```bash
list_databases() {
    echo "Available Databases:"
    ls -F | grep '/$' | sed 's#/##'
}
```

**Explanation:**

* `ls -F` → lists files/folders with symbols (`/` = directory).
* `grep '/$'` → filters only directories (lines ending with `/`).
* `sed 's#/##'` → removes the trailing `/` for clean display.

---

### 3. `connect_database`

**Purpose:**
Switch active DB and enter database menu.

**Code:**

```bash
connect_database() {
    read -p "Enter database name to connect: " dbname
    if [ -d "$dbname" ]; then
        current_database="$dbname"
        cd "$dbname"
        echo -e "${GREEN}Connected to '$dbname'.${NC}"
        show_database_menu
    else
        echo -e "${RED}Error: Database does not exist!${NC}"
    fi
}
```

**Explanation:**

* `if [ -d "$dbname" ]` → ensures the DB folder exists.
* `current_database="$dbname"` → stores DB name in global variable.
* `cd "$dbname"` → changes directory (enter database).
* `show_database_menu` → loads the Database Menu loop.

---

### 4. `drop_database`

**Purpose:**
Delete a database permanently.

**Code:**

```bash
drop_database() {
    read -p "Enter database name to drop: " dbname
    if [ -d "$dbname" ]; then
        rm -r "$dbname"
        echo -e "${GREEN}Database '$dbname' deleted successfully.${NC}"
    else
        echo -e "${RED}Error: Database does not exist!${NC}"
    fi
}
```

**Explanation:**

* `rm -r "$dbname"` → removes directory and all contents.

  * `-r` = recursive (required for directories).
* Error message shown if directory doesn’t exist.

---

---

## Database Menu Functions

---

### 1. `create_table`

**Purpose:**
Create a `.txt` file as a table with schema metadata.

**Code:**

```bash
create_table() {
    read -p "Enter table name: " tname
    if [ -f "$tname.txt" ]; then
        echo -e "${RED}Error: Table already exists!${NC}"
        return
    fi

    touch "$tname.txt"
    echo "# Table: $tname" >> "$tname.txt"

    read -p "Enter primary key column: " pk
    echo "# Primary Key: $pk" >> "$tname.txt"

    read -p "Enter number of columns: " n
    headers=()
    types=()

    for ((i=1; i<=n; i++)); do
        read -p "Enter column $i name: " cname
        read -p "Enter column $i type (int/str): " ctype
        headers+=("$cname")
        types+=("$ctype")
    done

    echo "${headers[*]}" | tr ' ' '|' >> "$tname.txt"
    echo "${types[*]}" | tr ' ' '|' >> "$tname.txt"

    echo -e "${GREEN}Table '$tname' created successfully.${NC}"
}
```

**Explanation:**

* `if [ -f "$tname.txt" ]` → checks if file already exists (`-f` = file).
* `touch "$tname.txt"` → creates empty file.
* `echo "..." >> file` → appends metadata lines.
* `headers+=("$cname")` → stores column names in array.
* `echo "${headers[*]}" | tr ' ' '|'` → joins array with `|` instead of spaces.
* Resulting schema looks like:

  ```
  # Table: users
  # Primary Key: id
  id|name|age
  int|str|int
  ```

---

### 2. `list_tables`

**Purpose:**
Show all tables in the database.

**Code:**

```bash
list_tables() {
    echo "Tables in '$current_database':"
    ls *.txt 2>/dev/null || echo "No tables found."
}
```

**Explanation:**

* `ls *.txt` → lists all `.txt` files (tables).
* `2>/dev/null` → suppress error if no files exist.
* `|| echo "No tables found."` → fallback message.

---

### 3. `drop_table`

**Purpose:**
Remove a table file.

**Code:**

```bash
drop_table() {
    read -p "Enter table name: " tname
    if [ -f "$tname.txt" ]; then
        rm "$tname.txt"
        echo -e "${GREEN}Table '$tname' deleted successfully.${NC}"
    else
        echo -e "${RED}Error: Table does not exist!${NC}"
    fi
}
```

**Explanation:**

* `rm "$tname.txt"` → deletes the table file.

---

### 4. `insert_into_table`

**Purpose:**
Add a new record (row) to a table.

**Code:**

```bash
insert_into_table() {
    read -p "Enter table name: " tname
    if [ ! -f "$tname.txt" ]; then
        echo -e "${RED}Error: Table does not exist!${NC}"
        return
    fi

    schema=$(sed -n '3p' "$tname.txt")
    types=$(sed -n '4p' "$tname.txt")
    IFS="|" read -ra columns <<< "$schema"
    IFS="|" read -ra ctypes <<< "$types"

    row=()
    for i in "${!columns[@]}"; do
        while true; do
            read -p "Enter value for ${columns[$i]}: " val
            if [[ "${ctypes[$i]}" == "int" && ! "$val" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Invalid: must be integer.${NC}"
            else
                row+=("$val")
                break
            fi
        done
    done

    echo "${row[*]}" | tr ' ' '|' >> "$tname.txt"
    echo -e "${GREEN}Row inserted successfully.${NC}"
}
```

**Explanation:**

* `sed -n '3p'` → get column headers (line 3).
* `sed -n '4p'` → get column types (line 4).
* `IFS="|" read -ra` → split headers/types into arrays.
* Regex: `[[ "$val" =~ ^[0-9]+$ ]]` → checks for integer input.
* `echo "${row[*]}" | tr ' ' '|'` → format row into `|` separated values.

---

### 5. `select_from_table`

**Purpose:**
View all records in a table.

**Code:**

```bash
select_from_table() {
    read -p "Enter table name: " tname
    if [ -f "$tname.txt" ]; then
        column -t -s "|" "$tname.txt"
    else
        echo -e "${RED}Error: Table does not exist!${NC}"
    fi
}
```

**Explanation:**

* `column -t -s "|"` → formats table neatly:

  * `-t` = create table format
  * `-s "|"` = split by `|`

---

### 6. `delete_from_table`

**Purpose:**
Remove a record from a table.

**Code:**

```bash
delete_from_table() {
    read -p "Enter table name: " tname
    if [ ! -f "$tname.txt" ]; then
        echo -e "${RED}Error: Table does not exist!${NC}"
        return
    fi

    read -p "Enter row number to delete: " rownum
    sed -i "${rownum}d" "$tname.txt"
    echo -e "${GREEN}Row deleted successfully.${NC}"
}
```

**Explanation:**

* `sed -i "${rownum}d" file` → deletes line at number `$rownum`.

---

### 7. `update_table`

**Purpose:**
Modify a row’s values.

**Code:**

```bash
update_table() {
    read -p "Enter table name: " tname
    if [ ! -f "$tname.txt" ]; then
        echo -e "${RED}Error: Table does not exist!${NC}"
        return
    fi

    read -p "Enter row number to update: " rownum
    oldrow=$(sed -n "${rownum}p" "$tname.txt")
    echo "Current row: $oldrow"

    schema=$(sed -n '3p' "$tname.txt")
    IFS="|" read -ra columns <<< "$schema"

    newrow=()
    for col in "${columns[@]}"; do
        read -p "Enter new value for $col (leave blank to keep): " val
        if [ -z "$val" ]; then
            newrow+=("$(echo "$oldrow" | cut -d'|' -f$((++idx)))")
        else
            newrow+=("$val")
        fi
    done

    sed -i "${rownum}s/.*/$(IFS="|"; echo "${newrow[*]}")/" "$tname.txt"
    echo -e "${GREEN}Row updated successfully.${NC}"
}
```

**Explanation:**

* `sed -n "${rownum}p"` → print specific row.
* `cut -d'|' -fN` → extract specific column value.
* `sed -i "${rownum}s/.*/newrow/"` → replace entire line.

---

### 8. `back_to_main_menu`

**Purpose:**
Return to main menu.

**Code:**

```bash
back_to_main_menu() {
    cd ..
    current_database=""
}
```

**Explanation:**

* `cd ..` → move up one directory (exit database).
* Reset `current_database`.


---

# Flow Diagrams – Bash DBMS

---

## 1. **System Overview**

```
+---------------------+
|   Bash DBMS Script  |
+----------+----------+
           |
           v
+---------------------+
|   Main Menu (User)  |
+----------+----------+
           |
           v
+---------------------+
|  Database Menu      |
| (when connected)    |
+---------------------+
```

---

## 2. **Main Menu Flow**

```
+----------------------+
|      Main Menu       |
+----------+-----------+
           |
    +------+------+------+------+
    |      |      |      |      |
    v      v      v      v      v
 Create   List   Connect  Drop  Exit
Database  DBs    to DB    DB    System
```

---

## 3. **Database Menu Flow**

```
+----------------------+
|    Database Menu     |
+----------+-----------+
           |
    +------+------+------+------+------+-------+------+------+
    |      |      |      |      |      |      |      |      |
    v      v      v      v      v      v      v      v      v
 Create   List   Drop  Insert  Select  Delete Update  Back
 Table    Tables Table   Row     Rows    Row   Row   (Main Menu)
```

---

## 4. **CRUD Operations on a Table**

### Create Table

```
User --> Define Table --> Columns + Types --> Save to file
```

### Insert Row

```
User --> Input Row --> Validate Types & PK --> Append to file
```

### Select From Table

```
User --> Choose Table --> Display Headers + Rows
```

### Update Row

```
User --> Enter PK --> Locate Row --> Edit Values --> Save Changes
```

### Delete Row

```
User --> Enter PK --> Locate Row --> Remove --> Save File
```

---

## 5. **Error Handling Flow**

```
        +-------------------+
        | User Input Action |
        +---------+---------+
                  |
                  v
        +-------------------+
        | Validation Check  |
        +---------+---------+
                  |
   +--------------+----------------+
   |                               |
   v                               v
 Valid Input                 Invalid Input
   |                               |
   v                               v
 Execute Operation          Show Error Message
   |                               |
   v                               v
   Done                        Return to Menu
```

---

## 6. **Full System Lifecycle**

```
Start --> Main Menu --> [Database Ops] --> Database Menu --> [Table Ops]
           |                                |
           +------------> Exit <------------+
```

---

### Collaborators 

## 1 . Yassen Mohamed Abdulhamid
## 2 . Mostafa Mohamed Abdullatif 
## 3 . Abdulrahman Rafat Ahmed
## 4 . Ahmed Atef Swefy
