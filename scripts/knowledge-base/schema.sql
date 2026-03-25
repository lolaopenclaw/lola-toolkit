-- Knowledge Base Schema
-- SQLite database for personal knowledge management

-- Main entries table
CREATE TABLE IF NOT EXISTS entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    source_type TEXT NOT NULL CHECK(source_type IN ('article', 'youtube', 'tweet', 'pdf')),
    content_text TEXT,
    summary TEXT,
    tags TEXT, -- JSON array
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Content chunks for RAG
CREATE TABLE IF NOT EXISTS chunks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL,
    chunk_text TEXT NOT NULL,
    chunk_index INTEGER NOT NULL,
    embedding BLOB, -- For future vector embeddings
    FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

-- FTS5 virtual table for full-text search
CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
    title,
    content_text,
    summary,
    tags,
    content=entries,
    content_rowid=id
);

-- Triggers to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS entries_ai AFTER INSERT ON entries BEGIN
    INSERT INTO entries_fts(rowid, title, content_text, summary, tags)
    VALUES (new.id, new.title, new.content_text, new.summary, new.tags);
END;

CREATE TRIGGER IF NOT EXISTS entries_ad AFTER DELETE ON entries BEGIN
    DELETE FROM entries_fts WHERE rowid = old.id;
END;

CREATE TRIGGER IF NOT EXISTS entries_au AFTER UPDATE ON entries BEGIN
    UPDATE entries_fts SET 
        title = new.title,
        content_text = new.content_text,
        summary = new.summary,
        tags = new.tags
    WHERE rowid = new.id;
END;

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_entries_source_type ON entries(source_type);
CREATE INDEX IF NOT EXISTS idx_entries_created_at ON entries(created_at);
CREATE INDEX IF NOT EXISTS idx_chunks_entry_id ON chunks(entry_id);
