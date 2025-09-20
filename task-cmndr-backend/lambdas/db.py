# This is NOT a lambda handler file. This file stores our DbUtils class.
import mysql.connector

class DbUtils:
    connection = None
    host = None
    db_name = None
    username = None
    password = None


    # constructor
    def __init__(self, host, db_name, username, password):
        self.connection = None
        self.host = host
        self.db_name = db_name
        self.username = username
        self.password = password

    
    # db connection is created here...
    def __enter__(self):
        if self.connection == None:
            self.connection = mysql.connector.connect(host=self.host, database=self.db_name, user=self.username, password=self.password)
            print('CONNECTION CREATED...')
            return self.connection

    # db connection is terminated here...
    def __exit__(self, exc_type, exc_value, exc_tb):
        if self.connection != None:
            self.connection.close()
            print('CONNECTION CLOSED...')