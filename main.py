import sys
import os
import logging
import time
import traceback
import requests
import hashlib

from io import BytesIO
from waveshare_epd import epd7in3f
from PIL import Image,ImageDraw,ImageFont

logging.basicConfig(level=logging.INFO)

last_sha256 = None

logging.info(f'Initializing e-paper display')
logging.info(f'Image URL: {os.getenv("IMAGE_URL")}')
logging.info(f'Refresh interval: {os.getenv("REFRESH_INTERVAL", 60)}')

epd = epd7in3f.EPD()
epd.init()

def update_loop():
    global last_sha256
    # get url from env
    url = os.getenv('IMAGE_URL')
    image_data = requests.get(url).content

    sha256 = hashlib.sha256(image_data).hexdigest()
    if sha256 == last_sha256:
        return

    logging.info(f'Updating image, sha256: {sha256}')
    image = Image.open(BytesIO(image_data))
    image = image.resize((800, 480))
    last_sha256 = sha256
    # convert to bmp
    converted_buffer = BytesIO()
    image.save(converted_buffer, format='BMP')
    converted_image = Image.open(converted_buffer)
    epd.display(epd.getbuffer(converted_image))

def draw_exception(exception):
    image = Image.new('RGB', (epd.width, epd.height), epd.WHITE)
    draw = ImageDraw.Draw(image)
    draw.text((5, 0), 'Error:', fill = epd.RED)
    draw.text((5, 20), str(exception),  fill = epd.RED)
    epd.display(epd.getbuffer(image))

while True:
    try:
        while True:
            update_loop()
            time.sleep(
                int(os.getenv('REFRESH_INTERVAL', 60))
            )
    except IOError as e:
        logging.error(e)
        draw_exception(e)
        time.sleep(240)

    except KeyboardInterrupt:
        logging.info("ctrl + c:")
        epd7in3f.epdconfig.module_exit()
        exit()

    except Exception as e:
        logging.error(e)
        traceback.print_exc()
        draw_exception(e)
        time.sleep(240)