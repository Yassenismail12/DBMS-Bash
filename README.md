                                                       ***Bash Database Management System
                                                            ====================== 


show_main_menu()
=================

Display the Main Functions of the Datebases


---------------------------------------------------------------------

show_database_menu()
=================

Display the Main Functions of tables of the connected Datebase  

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
