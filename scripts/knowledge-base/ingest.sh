#!/bin/bash
# knowledge-base-ingest.sh - Ingest content into knowledge base
# Usage: ./ingest.sh <URL> [tags...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${SCRIPT_DIR}/../../data/knowledge-base.db"
PYTHON_VENV="${SCRIPT_DIR}/venv"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() { echo -e "${RED}❌ $1${NC}" >&2; exit 1; }
info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check if URL provided
if [ $# -lt 1 ]; then
    error "Usage: $0 <URL> [tags...]"
fi

URL="$1"
shift
TAGS="$@"

# Ensure Python venv exists
if [ ! -d "$PYTHON_VENV" ]; then
    info "Creating Python virtual environment..."
    python3 -m venv "$PYTHON_VENV"
    source "$PYTHON_VENV/bin/activate"
    pip install --upgrade pip > /dev/null 2>&1
    pip install youtube-transcript-api beautifulsoup4 requests PyPDF2 > /dev/null 2>&1
else
    source "$PYTHON_VENV/bin/activate"
fi

# Detect source type
detect_source_type() {
    local url="$1"
    if [[ "$url" =~ youtube\.com|youtu\.be ]]; then
        echo "youtube"
    elif [[ "$url" =~ twitter\.com|x\.com ]]; then
        echo "tweet"
    elif [[ "$url" =~ \.pdf$ ]]; then
        echo "pdf"
    else
        echo "article"
    fi
}

SOURCE_TYPE=$(detect_source_type "$URL")
info "Detected source type: $SOURCE_TYPE"

# Python ingestion script
python3 - << PYTHON_SCRIPT
import sys
import json
import re
import sqlite3
from datetime import datetime
from urllib.parse import urlparse, parse_qs

# Database connection
conn = sqlite3.connect('$DB_PATH')
cur = conn.cursor()

url = '''$URL'''
source_type = '''$SOURCE_TYPE'''
tags_str = '''$TAGS'''
tags = json.dumps(tags_str.split()) if tags_str.strip() else '[]'

def chunk_text(text, chunk_size=500):
    """Split text into ~500 word chunks"""
    words = text.split()
    chunks = []
    for i in range(0, len(words), chunk_size):
        chunk = ' '.join(words[i:i+chunk_size])
        chunks.append(chunk)
    return chunks

def generate_summary(text, max_length=200):
    """Generate a simple summary (first N chars)"""
    text = text.strip()
    if len(text) <= max_length:
        return text
    return text[:max_length].rsplit(' ', 1)[0] + '...'

def extract_youtube_id(url):
    """Extract YouTube video ID from URL"""
    if 'youtu.be/' in url:
        return url.split('youtu.be/')[1].split('?')[0]
    parsed = urlparse(url)
    if 'youtube.com' in parsed.netloc:
        return parse_qs(parsed.query).get('v', [None])[0]
    return None

def ingest_youtube(url):
    """Fetch YouTube transcript"""
    from youtube_transcript_api import YouTubeTranscriptApi
    
    video_id = extract_youtube_id(url)
    if not video_id:
        print("❌ Could not extract YouTube video ID", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Fetch transcript (try Spanish first, then English)
        api = YouTubeTranscriptApi()
        transcript_list = api.list(video_id)
        
        # Try to find Spanish or English transcript
        transcript = None
        for lang in ['es', 'en']:
            try:
                transcript = transcript_list.find_transcript([lang])
                break
            except:
                continue
        
        if not transcript:
            # Just get the first available
            transcript = next(iter(transcript_list))
        
        transcript_data = api.fetch(video_id, languages=[transcript.language_code])
        # Extract .text attribute from FetchedTranscriptSnippet objects
        content = ' '.join([segment.text for segment in transcript_data])
        
        # Try to get title from page
        import requests
        try:
            r = requests.get(url, timeout=10)
            title_match = re.search(r'<title>(.+?)</title>', r.text)
            title = title_match.group(1) if title_match else f"YouTube Video {video_id}"
            # Clean YouTube title
            title = re.sub(r' - YouTube$', '', title)
        except:
            title = f"YouTube Video {video_id}"
        
        return title, content
    except Exception as e:
        print(f"❌ Failed to fetch YouTube transcript: {e}", file=sys.stderr)
        sys.exit(1)

def ingest_article(url):
    """Fetch article content"""
    import requests
    from bs4 import BeautifulSoup
    
    try:
        headers = {'User-Agent': 'Mozilla/5.0 (compatible; KnowledgeBase/1.0)'}
        r = requests.get(url, headers=headers, timeout=15)
        r.raise_for_status()
        
        soup = BeautifulSoup(r.content, 'html.parser')
        
        # Extract title
        title = soup.find('title')
        title = title.get_text().strip() if title else urlparse(url).netloc
        
        # Remove script and style elements
        for script in soup(['script', 'style', 'nav', 'footer', 'header']):
            script.decompose()
        
        # Get text
        text = soup.get_text()
        # Clean up whitespace
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        content = ' '.join(chunk for chunk in chunks if chunk)
        
        return title, content
    except Exception as e:
        print(f"❌ Failed to fetch article: {e}", file=sys.stderr)
        sys.exit(1)

def ingest_pdf(url):
    """Fetch and extract PDF content"""
    import requests
    from PyPDF2 import PdfReader
    from io import BytesIO
    
    try:
        headers = {'User-Agent': 'Mozilla/5.0 (compatible; KnowledgeBase/1.0)'}
        r = requests.get(url, headers=headers, timeout=30)
        r.raise_for_status()
        
        pdf_file = BytesIO(r.content)
        reader = PdfReader(pdf_file)
        
        # Get title from metadata or filename
        title = reader.metadata.title if reader.metadata and reader.metadata.title else urlparse(url).path.split('/')[-1]
        
        # Extract text from all pages
        content = ''
        for page in reader.pages:
            content += page.extract_text() + ' '
        
        return title, content.strip()
    except Exception as e:
        print(f"❌ Failed to fetch PDF: {e}", file=sys.stderr)
        sys.exit(1)

def ingest_tweet(url):
    """Placeholder for tweet ingestion"""
    print("⚠️  Tweet ingestion not yet implemented. Treating as article.", file=sys.stderr)
    return ingest_article(url)

# Main ingestion logic
if source_type == 'youtube':
    title, content = ingest_youtube(url)
elif source_type == 'article':
    title, content = ingest_article(url)
elif source_type == 'pdf':
    title, content = ingest_pdf(url)
elif source_type == 'tweet':
    title, content = ingest_tweet(url)
else:
    print(f"❌ Unknown source type: {source_type}", file=sys.stderr)
    sys.exit(1)

# Generate summary
summary = generate_summary(content)

# Check if URL already exists
cur.execute("SELECT id FROM entries WHERE url = ?", (url,))
existing = cur.fetchone()

if existing:
    print(f"⚠️  URL already exists in database (ID: {existing[0]})", file=sys.stderr)
    sys.exit(1)

# Insert entry
cur.execute("""
    INSERT INTO entries (url, title, source_type, content_text, summary, tags)
    VALUES (?, ?, ?, ?, ?, ?)
""", (url, title, source_type, content, summary, tags))

entry_id = cur.lastrowid

# Create chunks
chunks = chunk_text(content)
for idx, chunk in enumerate(chunks):
    cur.execute("""
        INSERT INTO chunks (entry_id, chunk_text, chunk_index)
        VALUES (?, ?, ?)
    """, (entry_id, chunk, idx))

conn.commit()
conn.close()

# Output summary
print(f"✅ Ingested: {title}")
print(f"   Type: {source_type}")
print(f"   Chunks: {len(chunks)}")
print(f"   Summary: {summary}")
print(f"   ID: {entry_id}")

PYTHON_SCRIPT

deactivate
