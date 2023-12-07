import json
import logging
from logging import Formatter

from app.config import LOG_LEVEL


class JsonFormatter(Formatter):
    def __init__(self):
        super().__init__()

    def format(self, record):
        json_record = {}
        json_record["message"] = record.getMessage()
        return json.dumps(json_record)


logger = logging.root
handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logger.handlers = [handler]
logger.setLevel(logging.getLevelName(LOG_LEVEL))
