from fastapi import FastAPI, UploadFile, File, Query
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import os

# Create FastAPI app instance (only once)
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins (for development)
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)

BASE_UPLOAD_DIR = "uploads"
os.makedirs(BASE_UPLOAD_DIR, exist_ok=True)


@app.post("/upload/{project_id}")
async def upload_file(project_id: str, file: UploadFile = File(...)):
    project_dir = os.path.join(BASE_UPLOAD_DIR, project_id)
    os.makedirs(project_dir, exist_ok=True)

    file_path = os.path.join(project_dir, file.filename)

    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)

    return {"filename": file.filename}


@app.get("/files/{project_id}")
def get_file(project_id: str):
    project_dir = os.path.join(BASE_UPLOAD_DIR, project_id)

    if not os.path.exists(project_dir) or not os.path.isdir(project_dir):
        return {"error": "Project directory not found"}

    files = os.listdir(project_dir)

    if not files:
        return {"error": "No file found in the project directory"}
    if len(files) > 1:
        return {"error": "Multiple files found in the project directory"}

    file_path = os.path.join(project_dir, files[0])
    return FileResponse(file_path, media_type="application/pdf")


@app.delete("/files/{project_id}/{filename}")
def delete_file(project_id: str, filename: str):
    file_path = os.path.join(BASE_UPLOAD_DIR, project_id, filename)
    if os.path.exists(file_path):
        os.remove(file_path)
        return {"status": "deleted"}
    return {"error": "File not found"}