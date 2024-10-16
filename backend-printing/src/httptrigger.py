"""Http trigger that uploads a document to microsoft universal print
"""

import logging
from src.helper.backend_print import BackendPrint
from fastapi import FastAPI, Request, HTTPException, Depends

app = FastAPI(
    title="Universal Print Service",
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def get_logger():
    return logger


@app.get("/")
async def root():
    return {"message": "Hello World"}


async def process_request(request: Request, log_tag: str, process_function):
    try:
        logger.info("Python HTTP trigger function processed a request.")
        body = await request.json()
        response = process_function(body)
        return response
    except Exception as e:
        logger.error(f"Error processing request in {log_tag}: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")


@app.get("/validator")
async def validator(request: Request, logger=Depends(get_logger)):
    return await process_request(
        request,
        "Validator",
        lambda body: BackendPrint(logger=logger, log_tag="Validator").validation_engine(
            body
        ),
    )


@app.get("/uploaddocumenttoup")
async def upload_document_to_up(request: Request, logger=Depends(get_logger)):
    return await process_request(
        request,
        "UploadDocumentToUP",
        lambda body: BackendPrint(
            logger=logger, log_tag="UploadDocumentToUP"
        ).upload_document_to_universal_print(body),
    )


@app.get("/health")
async def health_check():
    return {"status": "healthy"}
