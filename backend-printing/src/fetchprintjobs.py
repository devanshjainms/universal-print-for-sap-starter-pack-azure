"""cron job that fetch print jobs from SAP
"""

import logging
from src.helper.backend_print import BackendPrint


def setup_logging():
    logging.basicConfig(level=logging.INFO)


def fetch_print_jobs() -> None:
    logging.info("Python timer trigger function started.")
    try:
        backend_print = BackendPrint(logger=logging, log_tag="FetchPrintItems")
        logging.info("BackendPrint instance created.")
        backend_print.fetch_print_items_from_sap()
        logging.info("fetch_print_items_from_sap method called.")
    except Exception as e:
        logging.error(f"An error occurred: {e}")


if __name__ == "__main__":
    setup_logging()
    fetch_print_jobs()
