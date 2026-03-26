#!/usr/bin/env python3
"""
Semantic search for knowledge base using vector embeddings.
Supports pure semantic, FTS5, and hybrid modes.
"""

import sqlite3
import sys
import os
import argparse
import struct
import numpy as np
from pathlib import Path
from typing import List, Tuple
from embed import get_api_key, generate_embedding, deserialize_embedding

# Configuration
DB_PATH = Path(__file__).parent.parent.parent / "data" / "knowledge-base.db"
DEFAULT_LIMIT = 5


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Calculate cosine similarity between two vectors."""
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


def semantic_search(query: str, limit: int = DEFAULT_LIMIT) -> List[Tuple[int, str, str, str, float]]:
    """
    Perform semantic search using vector similarity.
    Returns: [(chunk_id, chunk_text, entry_title, entry_url, similarity_score), ...]
    """
    # Generate query embedding
    api_key = get_api_key()
    query_embedding = np.array(generate_embedding(query, api_key))
    
    # Fetch all chunks with embeddings
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT c.id, c.chunk_text, e.title, e.url, c.embedding
        FROM chunks c
        JOIN entries e ON c.entry_id = e.id
        WHERE c.embedding IS NOT NULL
    """)
    
    results = []
    for chunk_id, chunk_text, title, url, embedding_blob in cursor.fetchall():
        # Deserialize embedding
        chunk_embedding = np.array(deserialize_embedding(embedding_blob))
        
        # Calculate similarity
        score = cosine_similarity(query_embedding, chunk_embedding)
        results.append((chunk_id, chunk_text, title, url, score))
    
    conn.close()
    
    # Sort by similarity (highest first)
    results.sort(key=lambda x: x[4], reverse=True)
    
    return results[:limit]


def fts_search(query: str, limit: int = DEFAULT_LIMIT) -> List[Tuple[int, str, str, str]]:
    """
    Perform FTS5 full-text search.
    Returns: [(chunk_id, chunk_text, entry_title, entry_url), ...]
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT c.id, c.chunk_text, e.title, e.url
        FROM entries_fts fts
        JOIN entries e ON fts.rowid = e.id
        JOIN chunks c ON c.entry_id = e.id
        WHERE entries_fts MATCH ?
        ORDER BY rank
        LIMIT ?
    """, (query, limit))
    
    results = cursor.fetchall()
    conn.close()
    
    return results


def hybrid_search(query: str, limit: int = DEFAULT_LIMIT, semantic_weight: float = 0.7) -> List[Tuple[int, str, str, str, float]]:
    """
    Combine semantic and FTS5 search with weighted scoring.
    Returns: [(chunk_id, chunk_text, entry_title, entry_url, combined_score), ...]
    """
    # Get semantic results
    semantic_results = semantic_search(query, limit=limit * 2)
    semantic_scores = {r[0]: r[4] for r in semantic_results}  # chunk_id -> score
    
    # Get FTS results
    fts_results = fts_search(query, limit=limit * 2)
    fts_scores = {r[0]: 1.0 for r in fts_results}  # Binary: present or not
    
    # Combine scores
    all_chunk_ids = set(semantic_scores.keys()) | set(fts_scores.keys())
    combined = []
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    for chunk_id in all_chunk_ids:
        # Normalize scores (semantic already 0-1, FTS is binary)
        sem_score = semantic_scores.get(chunk_id, 0.0)
        fts_score = fts_scores.get(chunk_id, 0.0)
        
        # Weighted combination
        combined_score = (semantic_weight * sem_score) + ((1 - semantic_weight) * fts_score)
        
        # Get chunk details
        cursor.execute("""
            SELECT c.chunk_text, e.title, e.url
            FROM chunks c
            JOIN entries e ON c.entry_id = e.id
            WHERE c.id = ?
        """, (chunk_id,))
        
        chunk_text, title, url = cursor.fetchone()
        combined.append((chunk_id, chunk_text, title, url, combined_score))
    
    conn.close()
    
    # Sort by combined score
    combined.sort(key=lambda x: x[4], reverse=True)
    
    return combined[:limit]


def format_results(results: List[Tuple], mode: str):
    """Pretty-print search results."""
    if not results:
        print("❌ No results found")
        return
    
    print(f"\n🔍 Search Results ({mode} mode)")
    print("=" * 80)
    
    for i, result in enumerate(results, 1):
        chunk_id, chunk_text, title, url = result[:4]
        score = result[4] if len(result) > 4 else None
        
        print(f"\n[{i}] {title}")
        print(f"    URL: {url}")
        if score is not None:
            print(f"    Score: {score:.4f}")
        print(f"    Chunk ID: {chunk_id}")
        print(f"    Text: {chunk_text[:200]}...")
        print()


def main():
    parser = argparse.ArgumentParser(description="Semantic search for knowledge base")
    parser.add_argument("query", nargs="+", help="Search query")
    parser.add_argument("--mode", choices=["semantic", "fts", "hybrid"], default="semantic",
                        help="Search mode (default: semantic)")
    parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT,
                        help=f"Number of results (default: {DEFAULT_LIMIT})")
    parser.add_argument("--weight", type=float, default=0.7,
                        help="Semantic weight for hybrid mode (default: 0.7)")
    
    args = parser.parse_args()
    query = " ".join(args.query)
    
    try:
        if args.mode == "semantic":
            results = semantic_search(query, limit=args.limit)
        elif args.mode == "fts":
            results = fts_search(query, limit=args.limit)
        else:  # hybrid
            results = hybrid_search(query, limit=args.limit, semantic_weight=args.weight)
        
        format_results(results, args.mode)
    
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
