# Knowledge Base vs Project Documents: Complete Guide

## Overview

Archon has **TWO different document systems** that serve different purposes. This document clarifies the differences and shows how they work together.

---

## System 1: Knowledge Base (Global Searchable Knowledge)

### Purpose
A **global, searchable repository** of technical documentation, code examples, and other knowledge sources that can be shared across multiple projects.

### How it Works
- **Storage**: `archon_sources` + `archon_crawled_pages` tables
- **Processing**: Text chunking (5000 chars) + embedding generation + code extraction
- **Searchable**: Via RAG (Retrieval Augmented Generation) semantic search
- **API Endpoint**: `POST /api/documents/upload`
- **MCP Tools**:
  - `rag_search_knowledge_base(query)` - Semantic search
  - `rag_search_code_examples(query)` - Code-specific search
  - `rag_get_available_sources()` - List all sources
  - `rag_list_pages_for_source(source_id)` - Browse source structure
  - `rag_read_full_page(page_id or url)` - Read full page content

### Use Cases
- Upload technical documentation (APIs, frameworks, libraries)
- Crawl websites (docs.python.org, react.dev, etc.)
- Store code examples for reference
- Build a searchable knowledge repository

### File Types Supported
- PDF (`.pdf`)
- Word Documents (`.docx`, `.doc`)
- HTML (`.html`, `.htm`)
- Markdown (`.md`, `.markdown`)
- Text (`.txt`, `.rst`)

### Upload Example (Browser)
1. Go to "Knowledge" tab in UI
2. Click "Upload Document"
3. Select file and configure metadata
4. Document is processed: text extracted → chunked → embedded → stored

### Upload Example (API)
```bash
curl -X POST http://localhost:8181/api/documents/upload \
  -F "file=@/path/to/document.pdf" \
  -F "knowledge_type=technical" \
  -F "extract_code_examples=true" \
  -F "tags=[\"python\",\"api\"]"
```

### What Gets Stored
- **Source metadata** in `archon_sources` table
- **Document chunks** with embeddings in `archon_crawled_pages` table
- **Code examples** (if enabled) in separate table
- **Full-text searchable** via semantic similarity

---

## System 2: Project Documents (Project Metadata)

### Purpose
**Structured documentation tied to specific projects** - specs, design docs, notes, PRPs, API references, guides.

### How it Works
- **Storage**: `archon_projects.docs` JSONB field (in project row itself)
- **Processing**: None - stored as structured JSON metadata
- **NOT Searchable**: No embeddings, no chunking, no RAG
- **API Endpoint**: `POST /api/projects/{project_id}/docs`
- **MCP Tools**:
  - `find_documents(project_id)` - List project docs
  - `manage_document(action, project_id, ...)` - Create/update/delete

### Use Cases
- Project specifications (SDD, BDD, TDD)
- Design documents
- Meeting notes
- PRPs (Pull Request Proposals)
- API documentation specific to this project
- Project guides

### Document Types
- `spec` - Specifications
- `design` - Design documents
- `note` - Meeting notes, general notes
- `prp` - Pull Request Proposals
- `api` - API documentation
- `guide` - How-to guides

### Create Example (API)
```bash
curl -X POST http://localhost:8181/api/projects/{project_id}/docs \
  -H "Content-Type: application/json" \
  -d '{
    "document_type": "spec",
    "title": "Authentication Spec",
    "content": {"sections": ["overview", "requirements"]},
    "tags": ["auth", "security"],
    "author": "AI IDE Agent"
  }'
```

### What Gets Stored
- **JSON object** in the `docs` array field of `archon_projects` table
- **Metadata only**: title, type, tags, author, status, version
- **Structured content**: Flexible JSON content field
- **No embeddings**: Cannot be semantically searched

---

## The Connection: Linking Knowledge Sources to Projects

### ✅ YES, You Can Link Them!

There is a **third system** that connects knowledge base sources to projects:

### Junction Table: `archon_project_sources`

This table links knowledge sources to projects with two categories:
- **Technical sources**: Technical documentation, API references
- **Business sources**: Business requirements, product specs

### How to Link (API)

#### When Creating a Project
```bash
curl -X POST http://localhost:8181/api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Auth System",
    "description": "Authentication and authorization",
    "technical_sources": ["source-uuid-1", "source-uuid-2"],
    "business_sources": ["source-uuid-3"]
  }'
```

#### When Updating a Project
```bash
curl -X PUT http://localhost:8181/api/projects/{project_id} \
  -H "Content-Type: application/json" \
  -d '{
    "technical_sources": ["source-uuid-1", "source-uuid-2"],
    "business_sources": ["source-uuid-3"]
  }'
```

### How to Get Source IDs

Use MCP tool or API:
```bash
# Via MCP
rag_get_available_sources()

# Via API
curl http://localhost:8181/api/knowledge/sources
```

This returns all knowledge sources with their IDs, titles, and metadata.

### ⚠️ Gap: MCP Tools Don't Expose This Yet!

**Current Issue**: The MCP `manage_project` tool does NOT support `technical_sources` or `business_sources` parameters.

**Workaround**: Use the API directly (via curl or Python script) or modify the MCP tool.

---

## Complete Workflow Example

### Scenario: Building an Authentication System

#### Step 1: Upload Technical Knowledge
```bash
# Upload OAuth 2.0 spec
curl -X POST http://localhost:8181/api/documents/upload \
  -F "file=@oauth2-spec.pdf" \
  -F "knowledge_type=technical"

# Returns: { "progressId": "prog-123", "source_id": "source-oauth" }
```

#### Step 2: Create Project with Linked Sources
```bash
curl -X POST http://localhost:8181/api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Auth System",
    "description": "OAuth 2.0 implementation",
    "technical_sources": ["source-oauth"]
  }'
```

#### Step 3: Add Project Documentation
```bash
curl -X POST http://localhost:8181/api/projects/{project_id}/docs \
  -H "Content-Type: application/json" \
  -d '{
    "document_type": "spec",
    "title": "Auth Implementation Spec",
    "content": {
      "overview": "We will implement OAuth 2.0",
      "requirements": ["Token validation", "Refresh tokens"]
    }
  }'
```

#### Step 4: Search Knowledge Base
```bash
# Via MCP tool
rag_search_knowledge_base(query="OAuth token refresh")

# Returns relevant chunks from uploaded OAuth spec
```

---

## Summary Table

| Feature | Knowledge Base | Project Documents | Source Linking |
|---------|---------------|-------------------|----------------|
| **Table** | `archon_sources` + `archon_crawled_pages` | `archon_projects.docs` (JSONB) | `archon_project_sources` |
| **Scope** | Global | Project-specific | Junction table |
| **Searchable** | ✅ Yes (RAG/embeddings) | ❌ No | N/A |
| **Processing** | ✅ Chunking + embeddings | ❌ Stored as-is | N/A |
| **File Upload** | ✅ Yes | ❌ No | N/A |
| **API Endpoint** | `/api/documents/upload` | `/api/projects/{id}/docs` | `/api/projects` (create/update) |
| **MCP Support** | ✅ `rag_*` tools | ✅ `find_documents`, `manage_document` | ❌ Not exposed yet |
| **Use Case** | Shared knowledge repository | Project-specific docs | Link knowledge to projects |

---

## Recommendations

### For Adding Knowledge Documents (File-Based)
✅ **Use Knowledge Base Upload**
- `POST /api/documents/upload`
- Gets embeddings, searchable, reusable across projects
- Link to projects using `technical_sources` or `business_sources`

### For Adding Project Documentation (Structured)
✅ **Use Project Documents**
- `POST /api/projects/{id}/docs`
- Metadata storage, versioned, project-scoped
- No embeddings needed

### For Linking Existing Knowledge to Projects
✅ **Use Source Linking**
- Get source IDs: `GET /api/knowledge/sources`
- Link via: `PUT /api/projects/{id}` with `technical_sources` array

---

## Script: Upload Document from Path

For local development, use this helper script:

**Location**: `/Users/vmks/†perDeumAdAstra/08_AI-automation-server/Archon/scripts/upload_document.sh`

**Usage**:
```bash
./scripts/upload_document.sh /path/to/doc.pdf '["ai","docs"]' technical true
```

This reads the file and calls the existing API endpoint - no backend changes needed!

---

## Future Enhancement: File Path Upload Endpoint

### Proposed: `POST /api/documents/upload-from-path`

**Benefits**:
- No file transfer over HTTP for local files
- Better for large files
- Server-side file validation
- Could be exposed via MCP tool

**Parameters**:
```json
{
  "file_path": "/workspace/docs/spec.pdf",
  "knowledge_type": "technical",
  "tags": ["spec", "auth"],
  "extract_code_examples": true
}
```

**Implementation**: ~2-3 hours
- Add endpoint in `knowledge_api.py`
- Read file from disk with security validation
- Reuse existing `_perform_upload_with_progress()` pipeline
- Add MCP tool wrapper

**Security Considerations**:
- Path traversal prevention
- File size limits
- Extension whitelist
- Restrict to specific directories only
