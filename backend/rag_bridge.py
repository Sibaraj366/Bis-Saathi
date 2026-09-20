"""
BIS Saathi - RAG V2.1 Bridge

Combines:
    1. Existing BIS Saathi v1.3 retrieval
    2. Gemini semantic vector retrieval

The legacy retrieval remains the authority for:
    - exact IS numbers
    - product families
    - voltage-aware cable selection

The vector layer adds semantic understanding.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from rag_engine import hybrid_search


# ============================================================
# HELPERS
# ============================================================

def normalise_is(value: Any) -> str:
    """
    Normalize an IS number for comparison.
    """

    text = str(value or "").lower()

    replacements = {
        "–": "-",
        "—": "-",
        ":": " ",
        "-": " ",
        "(": " ",
        ")": " ",
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    return " ".join(text.split())


def result_is_number(
    result: Dict[str, Any],
) -> str:
    """
    Extract an IS number from either:
        - legacy BIS records
        - RAG records
    """

    return str(
        result.get("is_number")
        or result.get("isNumber")
        or result.get("standard")
        or ""
    )


def same_is_number(
    first: Dict[str, Any],
    second: Dict[str, Any],
) -> bool:
    """
    Check whether two records represent the same IS number.
    """

    first_number = normalise_is(
        result_is_number(first)
    )

    second_number = normalise_is(
        result_is_number(second)
    )

    return (
        bool(first_number)
        and first_number == second_number
    )


# ============================================================
# CONVERT LEGACY RECORD
# ============================================================

def legacy_to_candidate(
    item: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Convert an existing product_standards record
    into the common RAG result format.
    """

    is_number = item.get(
        "is_number",
        "",
    )

    return {
        "id": (
            "legacy-"
            + normalise_is(
                is_number
            ).replace(" ", "-")
        ),

        "score": 2.0,

        "semantic_score": None,

        "keyword_score": None,

        "record_type": "product_standard",

        "is_number": is_number,

        "product": item.get(
            "product",
            "",
        ),

        "category": item.get(
            "category",
            "",
        ),

        "industry": item.get(
            "industry",
            "",
        ),

        "revision_year": item.get(
            "revision_year",
            "",
        ),

        "source": item.get(
            "source",
            "",
        ),

        "text": "",

        "original": item,
    }


# ============================================================
# MERGE RESULTS
# ============================================================

def merge_results(
    semantic_results: List[Dict[str, Any]],
    legacy_results: List[Dict[str, Any]],
    top_k: int = 6,
) -> List[Dict[str, Any]]:
    """
    Merge semantic results with trusted legacy results.

    Legacy results are promoted because they contain the
    existing product-family and voltage-aware decisions.
    """

    merged: List[Dict[str, Any]] = []

    # --------------------------------------------------------
    # Add trusted legacy results first
    # --------------------------------------------------------

    for item in legacy_results:

        if not isinstance(
            item,
            dict,
        ):
            continue

        candidate = legacy_to_candidate(
            item
        )

        merged.append(
            candidate
        )

    # --------------------------------------------------------
    # Add semantic results
    # --------------------------------------------------------

    for item in semantic_results:

        if not isinstance(
            item,
            dict,
        ):
            continue

        already_present = any(
            same_is_number(
                item,
                existing,
            )
            for existing in merged
        )

        if already_present:
            continue

        merged.append(
            item
        )

    # --------------------------------------------------------
    # Sort
    # --------------------------------------------------------

    merged.sort(
        key=lambda item: (
            -float(
                item.get(
                    "score",
                    0,
                )
                or 0
            ),
            normalise_is(
                result_is_number(item)
            ),
        )
    )

    return merged[:top_k]


# ============================================================
# RAG V2.1 SEARCH
# ============================================================

def rag_v21_search(
    question: str,
    legacy_results: Optional[
        List[Dict[str, Any]]
    ] = None,
    top_k: int = 6,
) -> List[Dict[str, Any]]:
    """
    Perform semantic search and combine it with
    the existing trusted v1.3 retrieval.

    If semantic retrieval fails, the existing
    v1.3 results remain usable.
    """

    legacy_results = (
        legacy_results
        or []
    )

    try:

        semantic_results = hybrid_search(
            question,
            top_k=max(
                top_k,
                8,
            ),
        )

    except Exception as exc:

        print(
            "RAG V2 semantic retrieval error:",
            type(exc).__name__,
            exc,
        )

        return [
            legacy_to_candidate(
                item
            )

            for item in legacy_results[
                :top_k
            ]

            if isinstance(
                item,
                dict,
            )
        ]

    return merge_results(
        semantic_results,
        legacy_results,
        top_k=top_k,
    )


# ============================================================
# BUILD GEMINI CONTEXT
# ============================================================

def build_rag_context(
    results: List[Dict[str, Any]],
) -> str:
    """
    Convert RAG results into a compact Gemini context.
    """

    if not results:
        return (
            "No directly matching BIS information "
            "was retrieved."
        )

    sections = []

    for index, item in enumerate(
        results,
        start=1,
    ):

        is_number = item.get(
            "is_number",
            "",
        )

        product = item.get(
            "product",
            "",
        )

        category = item.get(
            "category",
            "",
        )

        source = item.get(
            "source",
            "",
        )

        text = item.get(
            "text",
            "",
        )

        original = item.get(
            "original"
        )

        # ----------------------------------------------------
        # Legacy record
        # ----------------------------------------------------

        if (
            not text
            and isinstance(
                original,
                dict,
            )
        ):

            standard_title = (
                original.get(
                    "standard_title",
                    "",
                )
            )

            certification = (
                original.get(
                    "certification",
                    "",
                )
            )

            information = (
                original.get(
                    "information",
                    "",
                )
            )

            checklist = (
                original.get(
                    "compliance_checklist",
                    [],
                )
                or []
            )

            checklist_text = "\n".join(
                f"- {entry}"
                for entry in checklist
            )

            text = (
                f"IS Number: {is_number}\n"
                f"Product: {product}\n"
                f"Standard Title: "
                f"{standard_title}\n"
                f"Certification: "
                f"{certification}\n"
                f"Information: "
                f"{information}\n"
                f"Compliance Checklist:\n"
                f"{checklist_text or 'Not provided'}"
            )

        # ----------------------------------------------------
        # Semantic record
        # ----------------------------------------------------

        section = (
            f"[Retrieved BIS Record {index}]\n"
            f"IS Number: {is_number}\n"
            f"Product: {product}\n"
            f"Category: {category}\n"
            f"Source: {source}\n"
            f"Information:\n{text}"
        )

        sections.append(
            section
        )

    return "\n\n".join(
        sections
    )


# ============================================================
# RAG STATUS
# ============================================================

def rag_status() -> Dict[str, Any]:
    """
    Return basic RAG bridge status.
    """

    try:

        from rag_engine import vector_store_info

        info = vector_store_info()

        return {
            "ragVersion": "2.1",

            "semanticSearch": bool(
                info.get(
                    "exists"
                )
            ),

            "vectorRecords": info.get(
                "records",
                0,
            ),

            "embeddingModel": info.get(
                "embedding_model"
            ),

            "embeddingDimensions": info.get(
                "embedding_dimensions"
            ),
        }

    except Exception as exc:

        return {
            "ragVersion": "2.1",

            "semanticSearch": False,

            "vectorRecords": 0,

            "error": (
                f"{type(exc).__name__}: {exc}"
            ),
        }


# ============================================================
# DIRECT TEST
# ============================================================

if __name__ == "__main__":

    print()
    print("=" * 70)
    print("BIS Saathi RAG V2.1 Bridge Test")
    print("=" * 70)
    print()

    print("RAG STATUS:")
    print(rag_status())

    print()

    questions = [
        "Which BIS standard applies to cement?",
        "I manufacture PVC electrical cables for 6.6 kV.",
        "What is IS 269:2015?",
        "What BIS standard applies to packaged drinking water?",
        "What is the BIS certification process?",
    ]

    for number, question in enumerate(
        questions,
        start=1,
    ):

        print()
        print("-" * 70)
        print(
            f"TEST {number}: {question}"
        )
        print("-" * 70)

        try:

            results = rag_v21_search(
                question,
                legacy_results=[],
                top_k=5,
            )

            if not results:
                print("No results found.")
                continue

            for rank, result in enumerate(
                results,
                start=1,
            ):

                identifier = (
                    result.get(
                        "is_number"
                    )
                    or result.get(
                        "product"
                    )
                    or result.get(
                        "category"
                    )
                    or "Unknown"
                )

                print(
                    f"{rank}. {identifier}"
                )

                print(
                    "   score="
                    f"{result.get('score')}"
                )

        except Exception as exc:

            print(
                "ERROR:",
                type(exc).__name__,
                exc,
            )

    print()
    print("=" * 70)
    print("RAG V2.1 BRIDGE TEST COMPLETE")
    print("=" * 70)