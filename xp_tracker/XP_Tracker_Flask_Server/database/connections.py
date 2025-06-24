import mysql.connector
from contextlib import contextmanager

class DatabaseConnection:
    """
    A class to handle the connection to the video game database in MYSQL.

    This class manages the process of establishing and disconnecting from the database. 
    It also provides a method to retrieve the connection object for executing queries.

    Attributes:
        host (str): The database host 
        user (str): The database user 
        password (str): The password for the user 
        database (str): The name of the database to connect to 
        connection (mysql.connector.connection): The MySQL database connection object

    Methods:
        db_connect(): Establishes a connection to the MySQL database.
        db_disconnect(): Closes the connection to the MySQL database.
        get_connection(): Returns the MySQL database connection object.
    """
    def __init__(self, host, user, password, database):
        """
        Initializes the Connection object with given database connection details.

        Parameters:
            host: The database host 
            user: The database user 
            password: The password for the user 
            database: The name of the database to connect to 
        """
        self.host = host
        self.user = user
        self.password = password
        self.database = database
        self.connection = None

    def db_connect(self):
        """
        Connects to the MYSQL video games database
        """
        try:
            self.connection = mysql.connector.connect(
                host=self.host,
                user=self.user,
                passwd=self.password,
                database=self.database
            )    
        except mysql.connector.Error as err:
            print(f"Error connecting to MySQL: {err}")
            self.connection = None
    
    def db_disconnect(self):
        """
        Disconnects from the MYSQL video games database
        """
        if self.connection and self.connection.is_connected():
            self.connection.close()
    
    @contextmanager
    def connection_handler(self):
        """
        Context manager to handle the connection to the MySQL database.
        """
        self.db_connect()
        try:
            yield self.connection
        finally:
            self.db_disconnect()