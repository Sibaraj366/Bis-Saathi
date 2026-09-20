"""
BIS Saathi - RAG V2 Vector Engine

Uses:
- Gemini Embeddings
- NumPy cosine similarity
- Local JSON persistence

This module is intentionally independent from main.py so the
existing BIS Saathi v1.3.0 retrieval system remains untouched.
"""

from __future__ import annotations

import json
import math
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

import numpy as np
from dotenv import load_dotenv
from google import genai
from google.genai import types


# -------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent
KNOWLEDGE_DIR = BASE_DIR / "knowledge"
VECTOR_DIR = BASE_DIR / "vector_store"

PRODUCT_STANDARDS_FILE = KNOWLEDGE_DIR / "product_standards.json"
BIS_KNOWLEDGE_FILE = KNOWLEDGE_DIR / "bis_knowledge.json"
VECTOR_STORE_FILE = VECTOR_DIR / "bis_vectors.json"

VECTOR_DIR.mkdir(parents=True, exist_ok=True)


# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

load_dotenv(BASE_DIR / ".env")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip()

# Gemini's current embedding model.
EMBEDDING_MODEL = "gemini-embedding-001"

# 768 dimensions gives a good balance between quality and local storage.
EMBEDDING_DIMENSIONS = 768


# -------------------------------------------------------------------
# Gemini client
# -------------------------------------------------------------------

_client: Optional[genai.Client] = None


def get_gemini_client() -> genai.Client:
    """
    Create the Gemini client lazily.

    The API key remains backend-only and is read from .env.
    """
    global _client

    if _client is None:
        if not GEMINI_API_KEY:
            raise RuntimeError(
                "GEMINI_API_KEY is missing from backend/.env"
            )

        _client = genai.Client(api_key=GEMINI_API_KEY)

    return _client


# -------------------------------------------------------------------
# Text helpers
# -------------------------------------------------------------------

def clean_text(value: Any) -> str:
    """
    Convert a value into clean searchable text.
    """
    if value is None:
        return ""

    text = str(value)

    text = re.sub(r"\s+", " ", text)
    return text.strip()


def normalise_is_number(value: Any) -> str:
    """
    Normalize IS numbers for metadata matching.
    """
    text = clean_text(value).lower()

    text = text.replace("–", "-")
    text = text.replace("—", "-")
    text = text.replace("_", " ")

    text = re.sub(r"\s+", " ", text)

    return text.strip()


def build_document_text(item: Dict[str, Any]) -> str:
    """
    Convert a BIS knowledge record into a rich retrieval document.

    Metadata is intentionally included in the embedding text so that
    questions such as:

        "cement standard"

        "PVC cable 6.6 kV"

        "IS 269"

    have enough semantic context.
    """

    fields = [
        ("IS Number", item.get("is_number")),
        ("Standard", item.get("standard")),
        ("Title", item.get("title")),
        ("Product", item.get("product")),
        ("Product Name", item.get("product_name")),
        ("Category", item.get("category")),
        ("Industry", item.get("industry")),
        ("Description", item.get("description")),
        ("Scope", item.get("scope")),
        ("Certification", item.get("certification")),
        ("Certification Requirement", item.get("certification_requirement")),
        ("Revision Year", item.get("revision_year")),
        ("Aliases", item.get("aliases")),
        ("Source", item.get("source")),
    ]

    parts: List[str] = []

    for label, value in fields:
        if value is None:
            continue

        if isinstance(value, list):
            value = ", ".join(clean_text(v) for v in value)

        text = clean_text(value)

        if text:
            parts.append(f"{label}: {text}")

    checklist = item.get("compliance_checklist")

    if isinstance(checklist, list):
        checklist_text = []

        for entry in checklist:
            if isinstance(entry, dict):
                name = clean_text(entry.get("item"))
                description = clean_text(entry.get("description"))

                if name and description:
                    checklist_text.append(f"{name}: {description}")
                elif name:
                    checklist_text.append(name)
            else:
                checklist_text.append(clean_text(entry))

        if checklist_text:
            parts.append(
                "Compliance Checklist: "
                + " | ".join(checklist_text)
            )

    return "\n".join(parts)


# -------------------------------------------------------------------
# Knowledge loading
# -------------------------------------------------------------------

def load_json_file(path: Path) -> Any:
    """
    Load JSON safely.
    """
    if not path.exists():
        return []

    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def load_product_standards() -> List[Dict[str, Any]]:
    """
    Load product_standards.json.

    Supports either:
        [...]
    or:
        {"standards": [...]}
    """
    data = load_json_file(PRODUCT_STANDARDS_FILE)

    if isinstance(data, list):
        return data

    if isinstance(data, dict):
        for key in (
            "standards",
            "product_standards",
            "items",
            "data",
        ):
            value = data.get(key)

            if isinstance(value, list):
                return value

    return []


def load_general_knowledge() -> List[Dict[str, Any]]:
    """
    Load bis_knowledge.json.

    Supports either:
        [...]
    or:
        {"knowledge": [...]}
    """
    data = load_json_file(BIS_KNOWLEDGE_FILE)

    if isinstance(data, list):
        return data

    if isinstance(data, dict):
        for key in (
            "knowledge",
            "entries",
            "items",
            "data",
        ):
            value = data.get(key)

            if isinstance(value, list):
                return value

    return []


# -------------------------------------------------------------------
# Record conversion
# -------------------------------------------------------------------

def standard_record_to_rag_record(
    item: Dict[str, Any],
    index: int,
) -> Dict[str, Any]:
    """
    Convert a product standard into a RAG record.
    """

    is_number = (
        item.get("is_number")
        or item.get("standard")
        or item.get("is")
        or ""
    )

    product = (
        item.get("product")
        or item.get("product_name")
        or item.get("title")
        or ""
    )

    category = (
        item.get("category")
        or "Indian Standard"
    )

    industry = (
        item.get("industry")
        or ""
    )

    source = (
        item.get("source")
        or ""
    )

    revision_year = (
        item.get("revision_year")
        or ""
    )

    text = build_document_text(item)

    return {
        "id": f"standard-{index}-{normalise_is_number(is_number)}",
        "record_type": "product_standard",
        "is_number": clean_text(is_number),
        "product": clean_text(product),
        "category": clean_text(category),
        "industry": clean_text(industry),
        "revision_year": clean_text(revision_year),
        "source": clean_text(source),
        "text": text,
        "metadata": {
            "is_number": clean_text(is_number),
            "product": clean_text(product),
            "category": clean_text(category),
            "industry": clean_text(industry),
            "revision_year": clean_text(revision_year),
            "source": clean_text(source),
        },
        "original": item,
    }


def knowledge_record_to_rag_record(
    item: Dict[str, Any],
    index: int,
) -> Dict[str, Any]:
    """
    Convert a general BIS knowledge entry into a RAG record.
    """

    title = (
        item.get("title")
        or item.get("name")
        or item.get("topic")
        or f"BIS Knowledge {index}"
    )

    source = item.get("source") or item.get("url") or ""

    text = build_document_text(item)

    if not text:
        text = json.dumps(
            item,
            ensure_ascii=False,
            indent=2,
        )

    return {
        "id": f"knowledge-{index}-{clean_text(title).lower().replace(' ', '-')}",
        "record_type": "bis_knowledge",
        "is_number": "",
        "product": "",
        "category": "BIS General Knowledge",
        "industry": "",
        "revision_year": "",
        "source": clean_text(source),
        "text": text,
        "metadata": {
            "title": clean_text(title),
            "category": "BIS General Knowledge",
            "source": clean_text(source),
        },
        "original": item,
    }


def build_rag_records() -> List[Dict[str, Any]]:
    """
    Build the complete RAG corpus from local BIS knowledge files.
    """

    records: List[Dict[str, Any]] = []

    standards = load_product_standards()

    for index, item in enumerate(standards):
        if isinstance(item, dict):
            records.append(
                standard_record_to_rag_record(
                    item,
                    index,
                )
            )

    knowledge = load_general_knowledge()

    for index, item in enumerate(knowledge):
        if isinstance(item, dict):
            records.append(
                knowledge_record_to_rag_record(
                    item,
                    index,
                )
            )

    return records


# -------------------------------------------------------------------
# Gemini embeddings
# -------------------------------------------------------------------

def embed_texts(
    texts: List[str],
) -> List[List[float]]:
    """
    Generate Gemini embeddings for multiple texts.

    The current Gemini SDK supports passing a list of contents to
    embed_content().
    """

    if not texts:
        return []

    client = get_gemini_client()

    result = client.models.embed_content(
        model=EMBEDDING_MODEL,
        contents=texts,
        config=types.EmbedContentConfig(
            output_dimensionality=EMBEDDING_DIMENSIONS,
        ),
    )

    embeddings: List[List[float]] = []

    for embedding in result.embeddings:
        values = getattr(embedding, "values", None)

        if values is None:
            raise RuntimeError(
                "Gemini embedding response did not contain values."
            )

        embeddings.append(
            [float(value) for value in values]
        )

    return embeddings


def embed_query(text: str) -> List[float]:
    """
    Generate one embedding for a user query.
    """

    embeddings = embed_texts([text])

    if not embeddings:
        raise RuntimeError(
            "No embedding was returned for the query."
        )

    return embeddings[0]


# -------------------------------------------------------------------
# Vector persistence
# -------------------------------------------------------------------

def save_vector_store(
    records: List[Dict[str, Any]],
    embeddings: List[List[float]],
) -> None:
    """
    Persist the RAG records and vectors locally.
    """

    if len(records) != len(embeddings):
        raise ValueError(
            "Record count and embedding count do not match."
        )

    payload = {
        "version": "2.0.0",
        "embedding_model": EMBEDDING_MODEL,
        "embedding_dimensions": EMBEDDING_DIMENSIONS,
        "records": [],
    }

    for record, embedding in zip(records, embeddings):
        payload["records"].append(
            {
                **record,
                "embedding": embedding,
            }
        )

    with VECTOR_STORE_FILE.open(
        "w",
        encoding="utf-8",
    ) as file:
        json.dump(
            payload,
            file,
            ensure_ascii=False,
            indent=2,
        )


def load_vector_store() -> Optional[Dict[str, Any]]:
    """
    Load the persisted vector store.
    """

    if not VECTOR_STORE_FILE.exists():
        return None

    with VECTOR_STORE_FILE.open(
        "r",
        encoding="utf-8",
    ) as file:
        return json.load(file)


# -------------------------------------------------------------------
# Index building
# -------------------------------------------------------------------

def build_index() -> Dict[str, Any]:
    """
    Rebuild the complete local vector index.

    This should be run whenever the BIS knowledge JSON files change.
    """

    records = build_rag_records()

    if not records:
        raise RuntimeError(
            "No BIS knowledge records were found."
        )

    texts = [
        record["text"]
        for record in records
    ]

    embeddings = embed_texts(texts)

    save_vector_store(
        records,
        embeddings,
    )

    return {
        "success": True,
        "records": len(records),
        "embedding_model": EMBEDDING_MODEL,
        "embedding_dimensions": EMBEDDING_DIMENSIONS,
        "vector_store": str(VECTOR_STORE_FILE),
    }


# -------------------------------------------------------------------
# Similarity
# -------------------------------------------------------------------

def cosine_similarity(
    query_vector: List[float],
    document_vector: List[float],
) -> float:
    """
    Calculate cosine similarity using NumPy.
    """

    query = np.asarray(
        query_vector,
        dtype=np.float32,
    )

    document = np.asarray(
        document_vector,
        dtype=np.float32,
    )

    query_norm = np.linalg.norm(query)
    document_norm = np.linalg.norm(document)

    if query_norm == 0 or document_norm == 0:
        return 0.0

    return float(
        np.dot(query, document)
        / (query_norm * document_norm)
    )


# -------------------------------------------------------------------
# Metadata filtering
# -------------------------------------------------------------------

def metadata_matches(
    record: Dict[str, Any],
    filters: Optional[Dict[str, Any]],
) -> bool:
    """
    Apply optional metadata filters before semantic ranking.
    """

    if not filters:
        return True

    metadata = record.get("metadata", {})

    is_number_filter = clean_text(
        filters.get("is_number")
    ).lower()

    if is_number_filter:
        record_is = normalise_is_number(
            metadata.get("is_number")
            or record.get("is_number")
        )

        wanted_is = normalise_is_number(
            is_number_filter
        )

        if wanted_is not in record_is and record_is not in wanted_is:
            return False

    product_filter = clean_text(
        filters.get("product")
    ).lower()

    if product_filter:
        product = clean_text(
            metadata.get("product")
            or record.get("product")
        ).lower()

        if product_filter not in product:
            return False

    category_filter = clean_text(
        filters.get("category")
    ).lower()

    if category_filter:
        category = clean_text(
            metadata.get("category")
            or record.get("category")
        ).lower()

        if category_filter not in category:
            return False

    industry_filter = clean_text(
        filters.get("industry")
    ).lower()

    if industry_filter:
        industry = clean_text(
            metadata.get("industry")
            or record.get("industry")
        ).lower()

        if industry_filter not in industry:
            return False

    return True


# -------------------------------------------------------------------
# Semantic retrieval
# -------------------------------------------------------------------

def semantic_search(
    query: str,
    top_k: int = 5,
    filters: Optional[Dict[str, Any]] = None,
) -> List[Dict[str, Any]]:
    """
    Retrieve semantically similar BIS records.

    Returns records with:
    - similarity score
    - metadata
    - original BIS record
    - source
    """

    store = load_vector_store()

    if not store:
        return []

    records = store.get("records", [])

    if not records:
        return []

    query_vector = embed_query(query)

    results: List[Dict[str, Any]] = []

    for record in records:
        if not metadata_matches(
            record,
            filters,
        ):
            continue

        embedding = record.get("embedding")

        if not embedding:
            continue

        similarity = cosine_similarity(
            query_vector,
            embedding,
        )

        result = {
            "id": record.get("id"),
            "score": round(
                similarity,
                6,
            ),
            "record_type": record.get(
                "record_type"
            ),
            "is_number": record.get(
                "is_number"
            ),
            "product": record.get(
                "product"
            ),
            "category": record.get(
                "category"
            ),
            "industry": record.get(
                "industry"
            ),
            "revision_year": record.get(
                "revision_year"
            ),
            "source": record.get(
                "source"
            ),
            "text": record.get(
                "text"
            ),
            "original": record.get(
                "original"
            ),
        }

        results.append(result)

    results.sort(
        key=lambda item: item["score"],
        reverse=True,
    )

    return results[:max(1, top_k)]


# -------------------------------------------------------------------
# Hybrid retrieval
# -------------------------------------------------------------------

def keyword_score(
    query: str,
    record: Dict[str, Any],
) -> float:
    """
    Small lexical score used alongside semantic similarity.

    This helps exact IS numbers and exact product names remain strong.
    """

    query_text = clean_text(query).lower()

    if not query_text:
        return 0.0

    searchable = " ".join(
        [
            clean_text(record.get("is_number")),
            clean_text(record.get("product")),
            clean_text(record.get("category")),
            clean_text(record.get("industry")),
            clean_text(record.get("text")),
        ]
    ).lower()

    query_tokens = set(
        re.findall(
            r"[a-z0-9]+",
            query_text,
        )
    )

    record_tokens = set(
        re.findall(
            r"[a-z0-9]+",
            searchable,
        )
    )

    if not query_tokens:
        return 0.0

    overlap = len(
        query_tokens.intersection(record_tokens)
    )

    return overlap / len(query_tokens)


def hybrid_search(
    query: str,
    top_k: int = 5,
    filters: Optional[Dict[str, Any]] = None,
) -> List[Dict[str, Any]]:
    """
    Combine semantic similarity with keyword matching.

    Semantic score:
        75%

    Keyword score:
        25%

    This makes the retrieval more robust for both natural-language
    questions and exact identifiers such as IS 269:2015.
    """

    store = load_vector_store()

    if not store:
        return []

    records = store.get("records", [])

    if not records:
        return []

    query_vector = embed_query(query)

    results: List[Dict[str, Any]] = []

    for record in records:
        if not metadata_matches(
            record,
            filters,
        ):
            continue

        embedding = record.get("embedding")

        if not embedding:
            continue

        semantic = cosine_similarity(
            query_vector,
            embedding,
        )

        lexical = keyword_score(
            query,
            record,
        )

        combined = (
            semantic * 0.75
            + lexical * 0.25
        )

        results.append(
            {
                "id": record.get("id"),
                "score": round(
                    combined,
                    6,
                ),
                "semantic_score": round(
                    semantic,
                    6,
                ),
                "keyword_score": round(
                    lexical,
                    6,
                ),
                "record_type": record.get(
                    "record_type"
                ),
                "is_number": record.get(
                    "is_number"
                ),
                "product": record.get(
                    "product"
                ),
                "category": record.get(
                    "category"
                ),
                "industry": record.get(
                    "industry"
                ),
                "revision_year": record.get(
                    "revision_year"
                ),
                "source": record.get(
                    "source"
                ),
                "text": record.get(
                    "text"
                ),
                "original": record.get(
                    "original"
                ),
            }
        )

    results.sort(
        key=lambda item: item["score"],
        reverse=True,
    )

    return results[:max(1, top_k)]


# -------------------------------------------------------------------
# Utility functions
# -------------------------------------------------------------------

def vector_store_exists() -> bool:
    return VECTOR_STORE_FILE.exists()


def vector_store_info() -> Dict[str, Any]:
    """
    Return basic information about the local vector store.
    """

    store = load_vector_store()

    if not store:
        return {
            "exists": False,
            "records": 0,
        }

    return {
        "exists": True,
        "records": len(
            store.get("records", [])
        ),
        "embedding_model": store.get(
            "embedding_model"
        ),
        "embedding_dimensions": store.get(
            "embedding_dimensions"
        ),
        "path": str(
            VECTOR_STORE_FILE
        ),
    }


# -------------------------------------------------------------------
# Command-line execution
# -------------------------------------------------------------------

if __name__ == "__main__":
    print()
    print("=" * 60)
    print("BIS Saathi RAG V2 - Vector Index Builder")
    print("=" * 60)
    print()

    print("Building BIS vector index...")
    print()

    result = build_index()

    print("SUCCESS")
    print()
    print(f"Records: {result['records']}")
    print(
        f"Embedding model: "
        f"{result['embedding_model']}"
    )
    print(
        f"Dimensions: "
        f"{result['embedding_dimensions']}"
    )
    print(
        f"Vector store: "
        f"{result['vector_store']}"
    )

    print()
    print("=" * 60)