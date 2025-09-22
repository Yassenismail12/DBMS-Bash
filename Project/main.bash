#!/bin/bash

# تعريف المتغيرات العامة
current_database=""
script_dir=$(pwd) # بيجيب المسار الحالي بتاع السكريبت

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# بيشغل الموديولز بتاعت القوائم
source main_menu.bash
source db_menu.bash

# دي الوظيفة الرئيسية اللي بتشغل البرنامج
main() {
    echo -e "${GREEN}Welcome to Bash DBMS!${NC}"
    echo "Team 2 Bash DBMS."
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
                echo -e "${GREEN}Thank you for using Bash DBMS!${NC}"
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

# بيبدأ البرنامج
main