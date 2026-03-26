#!/usr/bin/env python3
"""
Generate and store vector embeddings for knowledge base chunks.
Uses Gemini embedding model (gemini-embedding-001).
"""

import sqlite3
import requests
import struct
import sys
import time
import os
from pathlib import Path
from typing import List, Tuple

# Configuration
DB_PATH = Path(__file__).parent.parent.parent / "data" / "knowledge-base.db"
GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY")
GEMINI_EMBED_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent"
BATCH_SIZE = 10
RETRY_DELAY = 2  # seconds


def get_api_key() -> str:
    """Get Google API key from environment or .env file."""
    if GEMINI_API_KEY:
        return GEMINI_API_KEY
    
    # Try loading from .env files
    env_paths = [
        Path.home() / ".openclaw" / ".env",
        Path(__file__).parent.parent.parent / ".env"
    ]
    
    for env_path in env_paths:
        if env_path.exists():
            with open(env_path) as f:
                for line in f:
                    if line.startswith("GOOGLE_API_KEY="):
                        return line.split("=", 1)[1].strip().strip('"').strip("'")
    
    raise ValueError("GOOGLE_API_KEY not found in environment or .env files")


def generate_embedding(text: str, api_key: str, retry_count: int = 0) -> List[float]:
    """Generate embedding for a single text using Gemini API."""
    headers = {"Content-Type": "application/json"}
    data = {
        "content": {
            "parts": [{"text": text}]
        }
    }
    
    url = f"{GEMINI_EMBED_URL}?key={api_key}"
    
    try:
        response = requests.post(url, headers=headers, json=data, timeout=30)
        response.raise_for_status()
        result = response.json()
        return result["embedding"]["values"]
    
    except requests.exceptions.RequestException as e:
        if retry_count < 3:
            # Handle rate limits with exponential backoff
            wait_time = RETRY_DELAY * (2 ** retry_count)
            print(f"⚠️  API error, retrying in {wait_time}s... ({e})", file=sys.stderr)
            time.sleep(wait_time)
            return generate_embedding(text, api_key, retry_count + 1)
        else:
            raise Exception(f"Failed to generate embedding after 3 retries: {e}")


def serialize_embedding(embedding: List[float]) -> bytes:
    """Convert embedding vector to binary format for SQLite BLOB storage."""
    # Store as array of float32
    return struct.pack(f"{len(embedding)}f", *embedding)


def deserialize_embedding(blob: bytes) -> List[float]:
    """Convert binary BLOB back to embedding vector."""
    num_floats = len(blob) // 4
    return list(struct.unpack(f"{num_floats}f", blob))


def get_chunks_without_embeddings(db_path: Path) -> List[Tuple[int, str]]:
    """Fetch all chunks that don't have embeddings yet."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT id, chunk_text 
        FROM chunks 
        WHERE embedding IS NULL
        ORDER BY id
    """)
    
    chunks = cursor.fetchall()
    conn.close()
    
    return chunks


def update_chunk_embedding(db_path: Path, chunk_id: int, embedding: bytes):
    """Store embedding for a specific chunk."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        UPDATE chunks 
        SET embedding = ? 
        WHERE id = ?
    """, (embedding, chunk_id))
    
    conn.commit()
    conn.close()


def main():
    """Generate embeddings for all chunks without them."""
    print("🔍 Knowledge Base Embedding Generator")
    print("=" * 50)
    
    # Validate API key
    try:
        api_key = get_api_key()
        print(f"✅ API key loaded")
    except ValueError as e:
        print(f"❌ {e}", file=sys.stderr)
        sys.exit(1)
    
    # Get chunks to process
    chunks = get_chunks_without_embeddings(DB_PATH)
    total = len(chunks)
    
    if total == 0:
        print("✨ All chunks already have embeddings!")
        return
    
    print(f"📊 Found {total} chunks without embeddings")
    print(f"⚙️  Batch size: {BATCH_SIZE}")
    print()
    
    # Process in batches
    processed = 0
    failed = []
    
    for i in range(0, total, BATCH_SIZE):
        batch = chunks[i:i + BATCH_SIZE]
        batch_num = (i // BATCH_SIZE) + 1
        total_batches = (total + BATCH_SIZE - 1) // BATCH_SIZE
        
        print(f"📦 Batch {batch_num}/{total_batches} ({len(batch)} chunks)...")
        
        for chunk_id, chunk_text in batch:
            try:
                processed += 1
                print(f"  [{processed}/{total}] Embedding chunk {chunk_id}...", end=" ", flush=True)
                
                # Generate embedding
                embedding = generate_embedding(chunk_text, api_key)
                
                # Serialize and store
                blob = serialize_embedding(embedding)
                update_chunk_embedding(DB_PATH, chunk_id, blob)
                
                print(f"✅ ({len(embedding)} dims)")
                
                # Small delay to avoid rate limits
                time.sleep(0.1)
                
            except Exception as e:
                print(f"❌")
                print(f"    Error: {e}", file=sys.stderr)
                failed.append((chunk_id, str(e)))
        
        # Delay between batches
        if i + BATCH_SIZE < total:
            time.sleep(1)
    
    # Summary
    print()
    print("=" * 50)
    print(f"✅ Processed: {processed - len(failed)}/{total}")
    
    if failed:
        print(f"❌ Failed: {len(failed)}")
        print("\nFailed chunks:")
        for chunk_id, error in failed:
            print(f"  - Chunk {chunk_id}: {error}")
        sys.exit(1)
    else:
        print("🎉 All embeddings generated successfully!")


if __name__ == "__main__":
    main()
