import json
import od
from mysql.connector import Error
from db import DbUtils


def create_task_cmndr_db_tables(event, context):
    host = os.environ.get('HOST')
    db_name = os.environ.get('DATABASE_NAME')
    username = os.environ.get('USERNAME')
    password = os.environ.get('PASSWORD')


    try:
        with DbUtils(host,dn_name, username, password) as db:
            if db.is_connected():
                db_info = db.get_server_info()
                print("Connected to MySQL Server version:", db_info)

                cursor = db.cursor()
                cursor.execute("CREATE TABLE IF NOT EXISTS `users`(`userId` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,`firstName` VARCHAR(75),`lastName` VARCHAR(150),`active` BOOLEAN,`createdBy` VARCHAR(100),`createdDate` DATETIME(0),`lastModifiedBy` VARCHAR(100),`lastModifiedDate` DATETIME(0))")
                cursor.execute("CREATE TABLE IF NOT EXISTS `new_tasks`(`nTaskId` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,`userId` INT NOT NULL,`title` VARCHAR(75),`description` VARCHAR(150),`completed` BOOLEAN,`createdBy` VARCHAR(100),`createdDate` DATETIME(0),`lastModifiedBy` VARCHAR(100),`lastModifiedDate` DATETIME(0), FOREIGN KEY(`userId`) REFERENCES `users`(`userId`))")
                cursor.execute("CREATE TABLE IF NOT EXISTS `archived_tasks`(`setId` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,courseId INT NOT NULL,`setName` VARCHAR(175),`active` BOOLEAN,`createdBy` VARCHAR(100),`createdDate` DATETIME(0),`lastModifiedBy` VARCHAR(100)`lastModifiedDate` DATETIME(0), FOREIGN KEY(`userId`) REFERENCES `users`(`userId`))")
                print("Table creation has been completed.")
        except Error as e:
            print('Error while connecting to MySQL...', e)
    
    return{
        "statusCode": 200,
        "body": json.dumps({'Success': 'Database table creation process has been completed. Double check if all tables have been created properly...'})
    }
