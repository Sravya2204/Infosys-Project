# app.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from sentence_transformers import SentenceTransformer
import pandas as pd
import numpy as np
import ast

# -----------------------------
# 1. Load Data & Model
# -----------------------------
CSV_PATH = r"C:\Users\chand\OneDrive\Documents\Infosys_springboard\output\task4\output\phase2_transcript_embeddings.csv"

df = pd.read_csv(CSV_PATH)
# Convert embedding from string to list
df['clean_transcript_embedding'] = df['clean_transcript_embedding'].apply(ast.literal_eval)

# Load embedding model
model = SentenceTransformer('all-MiniLM-L6-v2')

# -----------------------------
# 2. VideoSearchEngine Class
# -----------------------------
class VideoSearchEngine:
    def __init__(self, df, embedding_col='clean_transcript_embedding'):
        self.df = df
        self.embedding_col = embedding_col
        self.embeddings = np.array(df[embedding_col].to_list())
    
    def search(self, query: str, top_k: int = 5):
    # Embed query
        q_emb = model.encode(query, convert_to_numpy=True, normalize_embeddings=True)

    
    # Cosine similarity
        sims = np.dot(self.embeddings, q_emb) / (np.linalg.norm(self.embeddings, axis=1) * np.linalg.norm(q_emb))
    
    # Get top K results
        top_indices = sims.argsort()[::-1][:top_k]
        results = self.df.iloc[top_indices].copy()
        results['similarity'] = sims[top_indices]
    
    # Return only required fields
        output = []
        for rank, row in enumerate(results.itertuples(), start=1):
            output.append({
                "rank": rank,
                "video_title": row.title,
                "youtube_link": f"https://www.youtube.com/watch?v={row.video_id}",
                "channel_name": getattr(row, 'channel_title', ''),  # Use channel_title column
                "similarity": row.similarity
            })
        return output


# Initialize search engine
search_engine = VideoSearchEngine(df)

# -----------------------------
# 3. FastAPI Setup
# -----------------------------
app = FastAPI(title="Video Semantic Search API", version="1.0")

# Request body model
class SearchRequest(BaseModel):
    query: str
    top_k: int = 5

# Endpoint
@app.post("/search")
def search_videos(request: SearchRequest):
    try:
        results = search_engine.search(request.query, request.top_k)
        return {"query": request.query, "top_k": request.top_k, "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Root endpoint
@app.get("/")
def root():
    return {"message": "Video Semantic Search API is running. Use POST /search to query."}