import time

# Helper functions for populating db 

def save_progress(current_game_id):
    """
    Save the current game ID to a progress file so that the process can resume later.
    """
    retries = 5
    for i in range(retries):
        try:
            #print ("Saved",current_game_id)
            with open("progress.txt", "w") as f:
                f.write(str(current_game_id))  # Store the last processed IGDB game ID
            break  # If successful, break out of the loop
        except PermissionError:
            if i < retries - 1:  # If not the last retry, wait and try again
                print(f"Permission denied, retrying... ({i+1}/{retries})")
                time.sleep(1)  # Delay for 1 second before retrying
            else:
                print("Failed to save progress after multiple attempts.")
                raise  # Reraise the exception if all retries fail

def load_progress():
    """
    Load the last processed game ID from the progress file.
    Returns None if no progress file exists.
    """
    try:
        with open("progress.txt", "r") as f:
            return int(f.read())  # Return the last saved game ID
    except FileNotFoundError:
        return None  # No progress file, return None to start from the beginning
    



    

