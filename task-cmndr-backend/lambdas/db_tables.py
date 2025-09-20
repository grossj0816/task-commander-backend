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
                cursor.execute("CREATE TABLE IF NOT EXISTS ```")
                

    

    return{
        "statusCode": 200,
        "body": json.dumps({"Success": "Database creation process has completed. Double check if you tables were added correctly.")      
    }