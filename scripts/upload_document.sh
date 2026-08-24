#!/bin/bash
# Upload a document to Archon knowledge base from file path
# Usage: ./upload_document.sh /path/to/document.pdf [tags] [knowledge_type]

set -e

# Configuration
ARCHON_API="http://localhost:8181"

# Arguments
FILE_PATH="$1"
TAGS="${2:-[]}"  # Default: empty array
KNOWLEDGE_TYPE="${3:-technical}"  # Default: technical
EXTRACT_CODE="${4:-true}"  # Default: true

# Validation
if [ -z "$FILE_PATH" ]; then
    echo "Error: File path required"
    echo "Usage: $0 <file_path> [tags_json] [knowledge_type] [extract_code]"
    echo "Example: $0 /path/to/doc.pdf '[\"ai\",\"docs\"]' technical true"
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi

# Upload
echo "📤 Uploading: $FILE_PATH"
echo "   Tags: $TAGS"
echo "   Knowledge type: $KNOWLEDGE_TYPE"
echo "   Extract code: $EXTRACT_CODE"
echo ""

RESPONSE=$(curl -s -X POST "$ARCHON_API/api/documents/upload" \
  -F "file=@$FILE_PATH" \
  -F "tags=$TAGS" \
  -F "knowledge_type=$KNOWLEDGE_TYPE" \
  -F "extract_code_examples=$EXTRACT_CODE")

echo "Response:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

# Extract progress ID if successful
PROGRESS_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('progressId', ''))" 2>/dev/null)

if [ -n "$PROGRESS_ID" ]; then
    echo ""
    echo "✅ Upload started! Progress ID: $PROGRESS_ID"
    echo "   Monitor at: $ARCHON_API/api/progress/$PROGRESS_ID"
fi
