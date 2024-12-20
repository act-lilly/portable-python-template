from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import socket

# Initialize logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this to restrict origins if necessary
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

# Utility function to find an available port
def find_available_port(start_port=5000):
    port = start_port
    while True:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            if sock.connect_ex(("127.0.0.1", port)) != 0:
                return port
            port += 1

# Basic route
@app.get("/")
async def read_root():
    return {"message": "Hello, World!"}

# Run the app with Uvicorn
if __name__ == "__main__":
    import uvicorn

    host = "127.0.0.1"
    port = 5000
    available_port = find_available_port(port)

    if available_port != port:
        logger.warning(f"Port {port} is in use. Switching to available port {available_port}.")

    uvicorn.run(app, host=host, port=available_port)
