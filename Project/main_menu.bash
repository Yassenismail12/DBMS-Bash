#!/bin/bash

# الموديول ده فيه كل الوظائف الخاصة بالقائمة الرئيسية.
# لازم يشتغل في السكريبت الرئيسي.

# بيظهر القائمة الرئيسية
show_main_menu() {
    clear
    echo "=================================="
    echo "             Main Menu            "
    echo "=================================="
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"
    echo "=================================="
    echo -n "Please select an option (1-5): "
}

# بننشاء داتا بيز 
create_database() {
    echo ""
    echo -e "${BLUE}Creating New DB....${NC}"
    echo -n "Enter database name: "
    read db_name

    # بيشيك لو اسم الداتا بيز فاضي
    if [ -z "$db_name" ]; then
        echo -e "${RED}Error: Database name cannot be empty!${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # بيشيك لو الفولدر بتاع الداتا بيز موجود قبل كده
    if [ -d "$script_dir/$db_name" ]; then
        echo -e "${RED}Error: Database '$db_name' already exists!${NC}"
    else
        mkdir "$script_dir/$db_name"
        echo -e "${GREEN}Database '$db_name' created successfully!${NC}"
    fi

    read -p "Press Enter to continue..."
}

# بيعرض كل الداتا بيز الموجوده
list_databases() {
    echo ""
    echo -e "${BLUE}Available Databases:${NC}"
    echo "===================="

    db_count=0
    # بيلف على كل الفولدرات اللي في المسار الحالي
    for dir in */; do
        if [ -d "$dir" ]; then
            db_count=$((db_count + 1))
            echo "$db_count. ${dir%/}" # بيشيل الشرطة المايلة الزيادة اللي بتظهر في الآخر
        fi
    done

    # بيشيك لو مفيش أي داتا بيز موجودة
    if [ $db_count -eq 0 ]; then
        echo "No databases found!"
    fi

    read -p "Press Enter to continue..."
}

# بيوصل لداتا بيز موجودة
connect_database() {
    echo ""
    list_databases
    echo -e "${BLUE}Connect to Database:${NC}"
    echo -n "Enter database name: "
    read db_name

    # بيشيك لو اسم الداتا بيز فاضي
    if [ -z "$db_name" ]; then
        echo -e "${RED}Error: Database name cannot be empty!${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # بيشيك لو الداتا بيز موجودة
    if [ -d "$script_dir/$db_name" ]; then
        current_database="$db_name"
        echo -e "${GREEN}Connected to database '$db_name'${NC}"
        read -p "Press Enter to continue..."

        # بيظهر قائمة الداتا بيز لحد ما المستخدم يرجع للقائمة الرئيسية
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

# بيمسح داتا بيز
drop_database() {
    echo ""
    list_databases
    echo -e "${BLUE}Drop Database:${NC}"
    echo -n "Enter database name to delete: "
    read db_name

    # بيشيك لو الداتا بيز موجودة
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
