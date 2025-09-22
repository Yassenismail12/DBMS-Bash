#!/bin/bash

# الموديول ده فيه كل الوظائف الخاصة بقائمة الداتا بيز.
# لازم يشتغل في السكريبت الرئيسي.
check=0
# بيظهر قائمة الداتا بيز
show_database_menu() {
    clear
    echo "======================================"
    echo "      Current DB : $current_database  "
    echo "======================================"
    echo "1. Create Table"
    echo "2. List Tables"
    echo "3. Drop Table"
    echo "4. Insert into Table"
    echo "5. Select From Table"
    echo "6. Delete From Table"
    echo "7. Update Table"
    echo "8. Back to Main Menu"
    echo "======================================"
    echo -n "Please select an option (1-8): "
}

# بيعمل الجدول جديد
create_table() {
    echo ""
    echo -e "${BLUE} Table in : $current_database${NC}"
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
        while true ; do
            echo -n "Column $i name: "
            read col_name
            if [[ " ${column_names[@]} " =~ " $col_name " ]]; then
                echo -e "${RED}Error: Column name '$col_name' already exists!${NC}"
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

# بيظهر كل الجداول العندي
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

# بيمسح الجدول
drop_table() {
    list_tables
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

# بيدخل بيانات في جدول
insert_into_table() {
    list_tables
    
    # تحقق لو مفيش أي جداول
    if [ $check -eq 1 ]; then
        echo -e "${RED}No tables available to insert data!${NC}"
        read -p "Press Enter to continue..."
        return
    fi

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

    # الهيدر والأنواع والبرايمري كي
    headers=$(sed -n '3p' "$table_file")
    types=$(sed -n '4p' "$table_file")
    primary_key=$(sed -n '2p' "$table_file" | cut -d':' -f2 | xargs)

    IFS='|' read -ra header_array <<< "$headers"
    IFS='|' read -ra type_array <<< "$types"

    while true; do
        echo ""
        echo "Enter data for each column:"

        row_data=()
        # إدخال البيانات لكل عمود
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
                    if [ -n "$value" ]; then
                        break
                    else
                        echo -e "${RED}Error: Value cannot be empty!${NC}"
                    fi
                fi
            done
            row_data+=("$value")
        done

        # التحقق من البرايمري كي
        if [ -n "$primary_key" ]; then
            pk_index=-1
            for ((i=0; i<${#header_array[@]}; i++)); do
                if [ "${header_array[i]}" = "$primary_key" ]; then
                    pk_index=$i
                    break
                fi
            done

            if [ $pk_index -ge 0 ]; then
                pk_value="${row_data[pk_index]}"
                if grep -qE "(^|\\|)$pk_value(\\||$)" "$table_file"; then
                    echo -e "${RED}Error: Primary key '$pk_value' already exists!${NC}"
                    read -p "Press Enter to continue..."
                    return
                fi
            fi
        fi

        # بناء السطر
        row_string=$(IFS='|'; echo "${row_data[*]}")
        echo "$row_string" >> "$table_file"

        echo -e "${GREEN}Data inserted successfully!${NC}"

        echo -n "Insert more? (y/n): "
        read additional
        if [[ "$additional" != "y" && "$additional" != "Y" ]]; then
            break
        fi
    done

    read -p "Press Enter to continue..."
}
 

# بيعرض الداتا من الجدول
# بيعرض الداتا من الجدول
select_from_table() {
        list_tables
        echo ""
        echo -e "${BLUE}Select Data from Table${NC}"
        echo -n "Enter table name: "
    while true; do  
        read table_name
        table_file="$script_dir/$current_database/$table_name.txt"
        if [ ! -f "$table_file" ]; then
            echo -e "${RED}Table '$table_name' does not exist!${NC}"
            echo -n "Try again !: "
            continue
        else 
            break   
        fi
    done
    while true; do
        headers=$(sed -n '3p' "$table_file")

        echo ""
        echo "How do you want to display the data?"
        echo "1) Show all rows"
        echo "2) Show specific range of rows"
        echo -n "Choose an option: "
        read choice

        case $choice in
            1)
                echo ""
                echo -e "${YELLOW}All Data:${NC}"
                echo "$headers"
                tail -n +5 "$table_file" | nl -w2 -s". "
                ;;
            2)
                echo -n "Enter start row number: "
                read start
                echo -n "Enter end row number: "
                read end

                if ! [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ && $start -le $end ]]; then
                    echo -e "${RED}Invalid range!${NC}"
                    return
                fi

                echo ""
                echo -e "${YELLOW}Rows $start to $end:${NC}"
                echo "$headers"
                tail -n +5 "$table_file" | sed -n "${start},${end}p" | nl -w2 -s". "
                ;;
            *)
                echo -e "${RED}Invalid choice!${NC}"
                ;;
        esac
        
        read -p "Press Enter to continue..."
        echo -n "Insert more? (y/n): "
        read additional
        if [[ "$additional" != "y" && "$additional" != "Y" ]]; then
            break
        fi

    done 
}

# بيمسح الداتا من الجدول
delete_from_table() {
    while true; do
        list_tables
        
        if [ $check -eq 1 ]; then
            echo -e "${RED}No tables available to delete data from!${NC}"
            read -p "Press Enter to continue..."
            return
        fi

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
        echo "Available rows:"
        tail -n +5 "$table_file" | cat -n

        echo ""
        echo -n "Enter row number to delete (0 to cancel): "
        read row_to_delete

        # تحقق أن الإدخال مش فاضي
        if [ -z "$row_to_delete" ]; then
            echo -e "${RED}Error: No row selected!${NC}"
            read -p "Press Enter to continue..."
            return
        fi

        # لو المستخدم اختار 0 يلغي العملية
        if [ "$row_to_delete" = "0" ]; then
            echo "Delete operation cancelled."
            read -p "Press Enter to continue..."
            return
        fi

        # الرقم الحقيقي للصف داخل الملف
        row_to_del=$((row_to_delete + 4))

        # تحقق من صلاحية الرقم
        total_rows=$(wc -l < "$table_file")
        if ! [[ "$row_to_delete" =~ ^[0-9]+$ ]] || [ "$row_to_del" -lt 5 ] || [ "$row_to_del" -gt "$total_rows" ]; then
            echo -e "${RED}Error: Invalid row number!${NC}"
            read -p "Press Enter to continue..."
            return
        fi

        # مسح الصف
        sed -i "${row_to_del}d" "$table_file"

        echo -e "${GREEN}Row deleted successfully!${NC}"
        read -p "Press Enter to continue..."
        list_tables
        echo -n "Insert more? (y/n): "
        read additional
        if [[ "$additional" != "y" && "$additional" != "Y" ]]; then
            break
        fi
    done

}

# بيحدث الداتا في الجدول
update_table() {
    while true; do
        list_tables
        echo ""
        echo -e "${BLUE}Update Data in Table${NC}"
        echo -n "Enter table name: "
        read table_name

        table_file="$script_dir/$current_database/$table_name.txt"

        if [ ! -f "$table_file" ]; then
            echo -e "${RED}Error: Table '$table_name' does not exist!${NC}"
            read -p "Press Enter to continue..."
            continue
        fi

        echo ""
        echo "Current data in table:"
        # بيعرض الهيدرز 
        headers=$(sed -n '3p' "$table_file")
        echo -e "${BLUE}$headers${NC}"
        echo "=================================="

        row_num=1
        # بيعرض الداتا الحالية عشان المستخدم يشوفها
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

        #    بيفالديت رقم الرو
        total_rows=$(tail -n +5 "$table_file" | grep -c .)
        if ! [[ "$row_to_update" =~ ^[0-9]+$ ]] || [ "$row_to_update" -lt 1 ] || [ "$row_to_update" -gt "$total_rows" ]; then
            echo -e "${RED}Error: Invalid row number!${NC}"
            read -p "Press Enter to continue..."
            continue
        fi

        # بيجيب الهيدرز و التايبز من الفايل
        headers=$(sed -n '3p' "$table_file")
        types=$(sed -n '4p' "$table_file")

        IFS='|' read -ra header_array <<< "$headers"
        IFS='|' read -ra type_array <<< "$types"

        # بيجيب السطر اللي المستخدم اختاره عشان يتحدث
        old_row=$(tail -n +5 "$table_file" | sed -n "${row_to_update}p")
        IFS='|' read -ra old_data <<< "$old_row"

        echo ""
        echo "Enter new data (press Enter to keep current value):"

        new_row_data=()
        # بيلف على كل كولم علشان ياخد الداتا الجديدة
        for ((i=0; i<${#header_array[@]}; i++)); do
            while true; do
                echo -n "${header_array[i]} (${type_array[i]}) [current: ${old_data[i]}]: "
                read value

                # لو القيمة فاضية بنسيب القيمة القديمة
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
        # بيبني الرو الجديد
        for ((i=0; i<${#new_row_data[@]}; i++)); do
            if [ $i -eq 0 ]; then
                new_row_string="${new_row_data[i]}"
            else
                new_row_string="$new_row_string|${new_row_data[i]}"
            fi
        done

        temp_file="/tmp/dbms_temp.txt"

        # بيكتب أول 4 سطور في الفايل مؤقت
        head -4 "$table_file" > "$temp_file"

        current_row=1
        # بيمسح الرو القديم وبيدخل الرو الجديد في الفايل المؤقت
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

        # بيستبدل الفايل الأصلي بالفايل المؤقت اللي  الاتحدث
        mv "$temp_file" "$table_file"

        echo -e "${GREEN}Row updated successfully!${NC}"
        read -p "Press Enter to continue..."
        tail -n +5 "$table_file" | nl -w2 -s". "
        echo -n "Update more? (y/n): "
        read additional
        if [[ "$additional" != "y" && "$additional" != "Y" ]]; then
            break
        fi
    done
}
