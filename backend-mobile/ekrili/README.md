
# Ekri

Ekri is a web application that helps users find locations of various types of houses and provides personalized recommendations based on their search history. The system analyzes users' previous searches to suggest the most relevant house listings and locations.

## Features

- **Location-based Search**: Find houses based on location, including city, neighborhood, or specific area.
- **Type of Houses**: Search for various types of houses, such as apartments, villas, or townhouses.
- **Search History Tracking**: Keeps track of the user's past searches to improve future recommendations.
- **Personalized Recommendations**: Uses your search history to suggest the most relevant houses and locations based on your preferences.
- **Filter Options**: Filter search results by price, number of bedrooms, amenities, and more.
- **Interactive Map**: Visualize the location of houses on an interactive map.

## Installation

Follow these steps to set up the project on your local machine:



### Prerequisites

1. **Install Git**  
   ```bash
   sudo apt install git -y
   ```

2. **Install Python 3 and pip**  
   ```bash
   sudo apt install python3 -y
   sudo apt install python3-pip -y
   ```

<!-- 3. **Install Google Chrome**  
   ```bash
   wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
   sudo apt install ./google-chrome-stable_current_amd64.deb -->
   ```






### 2. Install Dependencies

1. Install required Python dependencies:  
   ```bash
   pip install -r req.txt
   ```

   If you encounter issues, you can use the script to install dependencies:
   ```bash
   chmod +x install_deps.sh
   ./install_deps.sh
   ```



2. Configure MySQL Database:
   ```bash
   python3 setup_postgres.py
   python3 manage.py init_database
   docker-compose up -d
   ```

   ```

### 3. Running the Project

#### 3.1 Run the Backend

In the root project folder, run the backend:
```bash
python3 manage.py runserver 0.0.0.0:8111
```
*(To find the port, check the `.env` file in the `frontend` folder.)*

##### create super admin
python3 manage.py create_super_admin -e 'email' -p "admin" -fn "admin" -ln "admin"

#### visit API 
http://172.24.162.10:8111/swagger/
