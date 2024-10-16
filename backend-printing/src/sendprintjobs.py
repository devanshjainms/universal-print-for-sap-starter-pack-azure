"""Cron job that uploads a document to Microsoft Universal Print
"""

import logging
from src.helper.backend_print import BackendPrint


def setup_logging():
    logging.basicConfig(level=logging.INFO)


def send_print_jobs() -> None:
    logging.info("Python timer trigger function started.")
    try:
        backend_print = BackendPrint(logger=logging, log_tag="SendPrintJobs")
        logging.info("BackendPrint instance created.")
        backend_print.send_print_items_to_universal_print()
        logging.info("send_print_items_to_universal_print method called.")
    except Exception as e:
        logging.error(f"An error occurred: {e}")


if __name__ == "__main__":
    setup_logging()
    send_print_jobs()
