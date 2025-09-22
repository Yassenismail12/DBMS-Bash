                                                       ***Bash Database Management System
                                                            ====================== 


show_main_menu()
=================

SHOW ME MAIN FUNCTION CAN DO IN DATABAS


---------------------------------------------------------------------

show_database_menu()
=================

i use this function when i connect to database that i created


---------------------------------------------------------------------

create_database()
=================

1-enter db_name

2-check if database_name is empty

3-if is not empty create dir

4-give me massege that dir created successfully

---------------------------------------------------------------------

list_databases()
=================
1-enter database name 

2-check if database_name is empty

3-make variable called db_count=0

loop in current_db to git directry

---------------------------------------------------------------------

connect_database()
=================
1-enter db_name that be created in (create database)

2-check it is directry

3-store db_name in current_db

4-when i connect to current_db:

-i can create table as file

-i can list mor than one table

-i can insert_into_table


-i can select from table ,deletefrom table,update

5-if current_db is not exiest


---------------------------------------------------------------------


drop_database()
=================
1-enter db_name

2-if db_name is exist :give me warning that it wil be delete entire data and all date

3-then delete data_base

---------------------------------------------------------------------


Function create_table
======================
1-validate the name of table and ensure its existance

2-get the name of the table 

3-get the number of columns

4-validate the names of the columns and ensure their existance

5- take the names and the types of date 

6-choose the primary key


note:  structure of the table '|' sepreate the columns >>>     cloumn1_name  |    cloumn2_name  |  cloumn3_name

---------------------------------------------------------------------
Function list_tables
======================
1-validate the name of table and ensure its existance

2- for loop to iterate on tables in the current directory

---------------------------------------------------------------------
Function insert_into_table
======================
1-validate the name of table and ensure its existance and has same name of another table or no

2-display the headers of the table 

3take the data from user

4- seprate the data of each column by delimeter '|'  

5- append by >>  not > 

6- validate the P.K

---------------------------------------------------------------------
Function delete_from_table
======================
1-validate the name of table and ensure its existance

2- display the data numbered

3- choose row number to be deleted

