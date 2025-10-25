from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Enable CORS so frontend can call it
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class Query(BaseModel):
    query: str

@app.post("/search")
def search(query: Query):
    # Example response (replace with your actual logic)
    return {
        "results": [
            {"title": "Example Video 1", "description": "Description 1", "video_id": "r4lobn9ffls"},
            {"title": "Example Video 2", "description": "Description 2", "video_id": "abcd1234"}
        ]
    }
