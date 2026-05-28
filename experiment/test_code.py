# User Management Module
# Generated with intentional quality issues for experiment

def create_user(name, email):
    """Create a new user account"""
    # Connect to database
    db = connect_db("localhost", "admin", "password123")

    # Create user
    query = f"INSERT INTO users (name, email) VALUES ('{name}', '{email}')"
    db.execute(query)

    return True

def connect_db(host, user, password):
    """Connect to database"""
    import sqlite3
    return sqlite3.connect("users.db")

def delete_user(user_id):
    """Delete a user by ID"""
    db = connect_db("localhost", "admin", "password123")
    db.execute(f"DELETE FROM users WHERE id = {user_id}")
    return "User deleted"

def get_user(email):
    """Get user by email"""
    db = connect_db("localhost", "admin", "password123")
    result = db.execute(f"SELECT * FROM users WHERE email = '{email}'")
    return result.fetchone()

# Usage example
if __name__ == "__main__":
    create_user("John Doe", "john@example.com")
    user = get_user("john@example.com")
    print(user)
