import time
import os
import re

log_file = "logs/annonce_recommendation.log"
pattern = re.compile(r"Created Annonce ID: (\d+)")


def find_last_annonce_id(filepath):
    with open(filepath, 'rb') as f:
        f.seek(0, os.SEEK_END)
        filesize = f.tell()
        buffer = bytearray()
        block_size = 1024
        last_id = None

        while filesize > 0:
            read_size = min(block_size, filesize)
            f.seek(filesize - read_size)
            buffer = f.read(read_size) + buffer
            filesize -= read_size

            lines = buffer.decode(errors='ignore').splitlines()
            for line in reversed(lines):
                match = pattern.search(line)
                if match:
                    last_id = match.group(1)
                    return last_id

        return None

def tail_new_annonce_ids(filepath, last_known_id=None):
    with open(filepath, 'rb') as f:
        f.seek(0, os.SEEK_END)
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.1)
                continue

            try:
                decoded = line.decode()
            except UnicodeDecodeError:
                continue

            match = pattern.search(decoded)
            if match:
                annonce_id = match.group(1)
                if annonce_id != last_known_id:
                    print(f"New Annonce ID: {annonce_id}")
                    last_known_id = annonce_id

if __name__ == "__main__":
    last_id = find_last_annonce_id(log_file)
    if last_id:
        print("Last Annonce ID found:", last_id)
    else:
        print("No Annonce ID found in file yet.")

    tail_new_annonce_ids(log_file, last_known_id=last_id)