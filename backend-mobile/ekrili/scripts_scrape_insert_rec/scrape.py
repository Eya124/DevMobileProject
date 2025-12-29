import json
import os
import time
import requests
import logging
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service
from selenium.common.exceptions import TimeoutException, NoSuchElementException, WebDriverException
from urllib.parse import urlparse

# Create logs directory if it doesn't exist
os.makedirs('logs', exist_ok=True)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/scrape.log'),
        logging.StreamHandler()
    ]
)

class TayaraScraper:
    def __init__(self):
        self.start_time = time.time()
        self.transaction_type_filter = "À Louer"
        self.allowed_types = [
            'Colocations', 'Maisons et Villas', 'Magasins, Commerces et Locaux industriels',
            'Locations de vacances', 'Appartements', 'Bureaux et Plateaux',
            'Autres Immobiliers', 'Terrains et Fermes'
        ]
        self.data_dir = "media/scraping_folder_data"
        self.driver = None
        self.wait = None
        self.scraped_data = {}
        self.max_retries = 3
        self.retry_delay = 60  # seconds between retries
        self.run_interval = 300  # 1 hour between full runs

    def _setup_driver(self):
        """Configure and initialize Chrome WebDriver"""
        options = webdriver.ChromeOptions()
        options.add_argument("--headless")
        options.add_argument("--disable-gpu")
        options.add_argument("--no-sandbox")
        options.add_argument("--window-size=1920,1080")
        options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
        
        # Disable images to speed up loading (except when we need them)
        prefs = {"profile.managed_default_content_settings.images": 2}
        options.add_experimental_option("prefs", prefs)
        
        service = Service(ChromeDriverManager().install())
        return webdriver.Chrome(service=service, options=options)

    def _load_previous_data(self):
        """Load previously scraped data from JSON files"""
        previous_data = {}
        if os.path.exists(self.data_dir):
            for folder in os.listdir(self.data_dir):
                folder_path = os.path.join(self.data_dir, folder)
                if os.path.isdir(folder_path):
                    json_file = os.path.join(folder_path, "data.json")
                    if os.path.exists(json_file):
                        try:
                            with open(json_file, 'r', encoding='utf-8') as f:
                                data = json.load(f)
                                previous_data[data["id"]] = data
                        except (json.JSONDecodeError, IOError) as e:
                            logging.error(f"Error loading {json_file}")
        return previous_data

    def _initialize(self):
        """Initialize or reinitialize the scraper"""
        try:
            if self.driver:
                self.driver.quit()
            
            self.driver = self._setup_driver()
            self.wait = WebDriverWait(self.driver, 30)
            self.scraped_data = self._load_previous_data()
            return True
        except Exception as e:
            logging.error(f"Initialization failed")
            return False

    def _is_duplicate(self, price, phone_number):
        """Check if listing with same price and phone exists"""
        return any(
            data.get("price") == price and data.get("phone_number") == phone_number
            for data in self.scraped_data.values()
        )

    def _get_listing_id(self, url):
        """Extract listing ID from URL"""
        parsed = urlparse(url)
        return parsed.path.split('/')[2] if len(parsed.path.split('/')) > 2 else "unknown"

    def _get_title(self):
        """Extract listing title"""
        try:
            title = self.wait.until(EC.presence_of_element_located(
            (By.TAG_NAME, "h1")
            )).text
            logging.info(f"Title: {title}")
            return title
        except Exception as e:
            logging.warning(f"Title not found")
            return ""

    def _get_type_and_localization(self):
        """Extract property type and location"""
        try:
            div = self.wait.until(EC.visibility_of_element_located(
                (By.XPATH, "//div[contains(@class, 'flex justify-between items-center mt-5 mb-8')]")
            ))
            parts = div.text.split('\n')
            return parts[0].strip() if parts else "", parts[1].strip() if len(parts) > 1 else ""
        except Exception as e:
            logging.warning(f"Type/location not found")
            return "", ""

    def _get_transaction_details(self):
        """Extract transaction type and room number"""
        try:
            ul = self.wait.until(EC.visibility_of_element_located(
                (By.XPATH, "//ul[contains(@class, 'grid gap-3 grid-cols-12')]")
            ))
            transaction = ul.find_element(By.XPATH, "./li[1]").text.split('\n')[1].strip()
            rooms = ul.find_element(By.XPATH, "./li[4]").text.split('\n')[1].strip()
            return transaction, rooms
        except Exception as e:
            logging.warning(f"Transaction details not found")
            # logging.warning(f"Transaction details not found")
            return "", ""

    def _get_price(self):
        """Extract property price"""
        try:
            price = self.driver.find_element(
                By.CSS_SELECTOR, ".font-bold.font-arabic.text-red-600.text-2xl"
            ).text.strip()
            logging.info(f"Price: {price}")
            return price
        except Exception as e:
            logging.warning(f"Price not found")
            return "0"

    def _get_description(self):
        """Extract property description"""
        try:
            desc = self.wait.until(EC.presence_of_element_located(
                (By.CSS_SELECTOR, "p.text-sm.text-start.text-gray-700.font-arabic")
            )).text.strip()
            logging.info(f"Description length: {len(desc)} chars")
            return desc
        except Exception as e:
            logging.warning(f"Description not found")
            return ""

    def _get_phone_number(self):
        """Extract seller's phone number"""
        try:
            buttons = self.wait.until(EC.presence_of_all_elements_located(
                (By.XPATH, "//button[contains(@aria-label, 'Afficher numéro')]")
            ))
            if len(buttons) >= 2:
                self.driver.execute_script("arguments[0].click();", buttons[1])
                phone = self.wait.until(EC.presence_of_element_located(
                    (By.XPATH, "//a[starts-with(@href, 'tel:')]")
                )).text.strip()
                logging.info(f"Phone: {phone}")
                return phone
            return ""
        except Exception as e:
            logging.warning(f"Phone not found")
            return ""

    def _download_images(self, listing_id):
        """Download property images"""
        try:
            folder = os.path.join(self.data_dir, listing_id)
            os.makedirs(folder, exist_ok=True)
            
            # Enable images just for this part
            self.driver.execute_script("""
                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                document.cookie = "profile.managed_default_content_settings.images=1";
            """)
            
            # Main image
            try:
                img = self.wait.until(EC.presence_of_element_located(
                    (By.CSS_SELECTOR, "div#item-caroussel-0 img:first-of-type")
                ))
                self._save_image(img.get_attribute("src"), folder, "main")
            except Exception as e:
                logging.warning(f"Main image not found")
            
            # Other images
            try:
                images_div = self.wait.until(EC.visibility_of_element_located(
                    (By.XPATH, "//div[contains(@class, 'flex flex-row content-start gap-2 flex-wrap')]")
                ))
                for idx, img in enumerate(images_div.find_elements(By.XPATH, ".//a/img"), 1):
                    self._save_image(img.get_attribute("src"), folder, f"image_{idx}")
            except Exception as e:
                logging.warning(f"Additional images not found")
                
        except Exception as e:
            logging.error(f"Error downloading images")

    def _save_image(self, url, folder, name):
        """Helper to download and save a single image"""
        if not url:
            return
            
        try:
            sanitized = "".join(c for c in name if c.isalnum() or c in ('_', '-'))
            path = os.path.join(folder, f"{sanitized}.jpg")
            
            if not os.path.exists(path):
                response = requests.get(url, stream=True, timeout=10)
                response.raise_for_status()
                with open(path, 'wb') as f:
                    for chunk in response.iter_content(1024):
                        f.write(chunk)
                logging.info(f"Saved image: {path}")
        except Exception as e:
            logging.warning(f"Failed to save image {url}")

    def _save_listing_data(self, listing_id, data):
        """Save listing data to JSON file"""
        try:
            folder = os.path.join(self.data_dir, listing_id)
            os.makedirs(folder, exist_ok=True)
            
            path = os.path.join(folder, 'data.json')
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            logging.info(f"Saved data for {listing_id}")
        except Exception as e:
            logging.error(f"Error saving data for {listing_id}")

    def _process_listing(self, url, category):
        """Process a single property listing"""
        listing_id = self._get_listing_id(url)
        logging.info(f"Processing {listing_id}: {url}")
        
        try:
            # Open in new tab
            self.driver.execute_script(f"window.open('{url}');")
            self.driver.switch_to.window(self.driver.window_handles[1])
            time.sleep(2)  # Brief pause for page load
            
            # Get listing details
            transaction, rooms = self._get_transaction_details()
            
            if transaction == self.transaction_type_filter:
                price = self._get_price()
                phone = self._get_phone_number()
                
                if not self._is_duplicate(price, phone):
                    title = self._get_title()
                    prop_type, location = self._get_type_and_localization()
                    desc = self._get_description()
                    
                    # Download images
                    self._download_images(listing_id)
                    
                    # Prepare and save data
                    data = {
                        "id": listing_id,
                        "url": url,
                        "title": title,
                        "description": desc,
                        "type": category,
                        "location": location,
                        "size": f"s+{rooms}" if rooms else "unknown",
                        "price": price,
                        "phone_number": phone,
                        "url": url,
                        "scraped_at": time.strftime("%Y-%m-%d %H:%M:%S")
                    }
                    
                    self._save_listing_data(listing_id, data)
                    self.scraped_data[listing_id] = data
                else:
                    logging.info("Skipping duplicate listing")
            else:
                logging.info(f"Skipping - not '{self.transaction_type_filter}'")
                
        except Exception as e:
            logging.error(f"Error processing {listing_id}")
        finally:
            # Clean up - close tab and switch back
            if len(self.driver.window_handles) > 1:
                self.driver.close()
                self.driver.switch_to.window(self.driver.window_handles[0])

    def _scrape_page(self):
        """Scrape a single page of listings"""
        try:
            base_url = "https://www.tayara.tn/ads/c/Immobilier/?page=1"
            self.driver.get(base_url)
            
            # Wait for listings to load
            try:
                container = self.wait.until(EC.presence_of_element_located(
                    (By.XPATH, "//div[contains(@class, 'relative') and contains(@class, '-z-40')]")
                ))
                listings = container.find_elements(By.TAG_NAME, "article")
                
                if not listings:
                    logging.warning("No listings found on page")
                    return False
                    
                logging.info(f"Found {len(listings)} listings")
                
                for listing in listings:
                    try:
                        text = listing.text
                        category = next((t for t in self.allowed_types if t in text), "")
                        link = listing.find_element(By.TAG_NAME, "a")
                        if link:
                            self._process_listing(link.get_attribute('href'), category)
                    except Exception as e:
                        logging.error(f"Error processing listing")
                        continue
                
                return True
                        
            except TimeoutException:
                logging.error("Timed out waiting for listings")
                return False
                
        except Exception as e:
            logging.error(f"Page scraping failed")
            return False

    def run(self):
        """Main execution with retry logic - restarts immediately after success"""
        while True:
            retry_count = 0
            success = False
            
            while retry_count < self.max_retries and not success:
                try:
                    logging.info(f"Starting scraping attempt {retry_count + 1}")
                    
                    if not self._initialize():
                        raise Exception("Failed to initialize scraper")
                    
                    success = self._scrape_page()
                    
                    if success:
                        elapsed = time.time() - self.start_time
                        logging.info(f"Completed successfully in {elapsed:.2f} seconds")
                        logging.info(f"Total processed: {len(self.scraped_data)}")
                        # Run insertion script
                        import subprocess
                        insert_result = subprocess.run(["python3", "scripts_scrape_insert_rec/insert_data_scraped_and_recommandation.py"])
                        if insert_result.returncode == 0:
                            logging.info("Data insertion completed successfully")
                        else:
                            raise Exception("Data insertion failed")
                    else:
                        raise Exception("Scraping attempt failed")
                        
                except Exception as e:
                    retry_count += 1
                    logging.error(f"Attempt {retry_count} failed")
                    
                    if retry_count < self.max_retries:
                        logging.info(f"Waiting {self.retry_delay} seconds before retry...")
                        time.sleep(self.retry_delay)
                    else:
                        logging.error("Max retries reached")
                        # Wait longer after complete failure before restarting
                        time.sleep(self.retry_delay * 2)
            
            # Clean up after each run
            if self.driver:
                self.driver.quit()
                self.driver = None
            
            # Only wait if we failed all retries
            if not success:
                logging.info(f"Waiting {self.run_interval} seconds before next run...")
                time.sleep(self.run_interval)
            else:
                logging.info("Restarting immediately for next run...")

if __name__ == "__main__":
    scraper = TayaraScraper()
    scraper.run()