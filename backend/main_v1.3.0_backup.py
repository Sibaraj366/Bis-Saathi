import os
import json
import re
import uuid
from io import BytesIO
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from pydantic import BaseModel
from pypdf import PdfReader


# ============================================================
# ENVIRONMENT
# ============================================================

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise RuntimeError("GEMINI_API_KEY is not configured in .env")

client = genai.Client(api_key=api_key)


# ============================================================
# LOAD BIS KNOWLEDGE
# ============================================================

def load_json(filename: str):
    with open(
        BASE_DIR / "knowledge" / filename,
        encoding="utf-8",
    ) as file:
        return json.load(file)


bis_knowledge = load_json("bis_knowledge.json")
product_standards = load_json("product_standards.json")


# ============================================================
# DOCUMENT STORAGE
# ============================================================

document_store: dict[str, dict[str, Any]] = {}


# ============================================================
# SUPPORTED LANGUAGES
# ============================================================

SUPPORTED_LANGUAGES = {
    "english": "English",
    "en": "English",

    "hindi": "Hindi",
    "hi": "Hindi",
    "हिंदी": "Hindi",

    "marathi": "Marathi",
    "mr": "Marathi",
    "मराठी": "Marathi",
}


# ============================================================
# TEXT NORMALIZATION
# ============================================================

def normalize_text(value: str) -> str:
    value = str(value or "").lower()

    value = value.replace("–", "-")
    value = value.replace("—", "-")
    value = value.replace("_", " ")

    value = re.sub(
        r"\s+",
        " ",
        value,
    )

    return value.strip()


# ============================================================
# LANGUAGE NORMALIZATION
# ============================================================

def normalize_language(
    value: str | None,
) -> str:

    if not value:
        return "English"

    normalized = normalize_text(value)

    return SUPPORTED_LANGUAGES.get(
        normalized,
        "English",
    )


# ============================================================
# GEMINI LANGUAGE INSTRUCTIONS
# ============================================================

def language_instruction(
    language: str,
) -> str:

    if language == "Hindi":

        return """
RESPONSE LANGUAGE: Hindi

Write the answer in clear, natural Hindi
using Devanagari script.

Keep IS numbers, technical identifiers,
product names, official names and URLs accurate.

Do not translate URLs or IS numbers.
"""

    if language == "Marathi":

        return """
RESPONSE LANGUAGE: Marathi

Write the answer in clear, natural Marathi
using Devanagari script.

Keep IS numbers, technical identifiers,
product names, official names and URLs accurate.

Do not translate URLs or IS numbers.
"""

    return """
RESPONSE LANGUAGE: English

Write the answer in clear, simple English.

Keep IS numbers, technical identifiers,
product names, official names and URLs accurate.
"""


# ============================================================
# STOP WORDS
# ============================================================

STOP_WORDS = {
    "the",
    "and",
    "for",
    "with",
    "what",
    "which",
    "how",
    "does",
    "this",
    "that",
    "from",
    "about",
    "into",
    "are",
    "is",
    "can",
    "you",
    "please",
    "tell",
    "me",
    "give",
    "get",
    "want",
    "need",
    "show",
    "explain",
    "standard",
    "standards",
    "bis",

    "का",
    "के",
    "की",
    "और",
    "में",
    "से",
    "यह",
    "क्या",
    "कैसे",
    "है",
    "को",

    "आणि",
    "मध्ये",
    "काय",
    "कसे",
    "आहे",
    "ही",
    "चा",
    "ची",
    "चे",
}


# ============================================================
# PRODUCT ALIASES
# ============================================================

PRODUCT_ALIASES = {

    "cement": [
        "cement",
        "सीमेंट",
        "सिमेंट",
    ],

    "pvc cable": [
        "pvc cable",
        "pvc cables",
        "pvc insulated cable",
        "pvc insulated cables",
        "electric cable",
        "electric cables",
        "electrical cable",
        "electrical cables",
        "electric wire",
        "electric wires",
        "wire",
        "wires",
        "cable",
        "cables",
        "पीवीसी केबल",
        "केबल",
    ],

    "polyethylene pipe": [
        "polyethylene pipe",
        "polyethylene pipes",
        "pe pipe",
        "pe pipes",
        "plastic pipe",
        "plastic pipes",
        "water supply pipe",
        "water supply pipes",
    ],

    "packaged water": [
        "packaged drinking water",
        "packaged natural mineral water",
        "packaged water",
        "bottled water",
        "drinking water",
        "पैकेज्ड ड्रिंकिंग वाटर",
        "पेयजल",
    ],

    "feeding bottle": [
        "feeding bottle",
        "feeding bottles",
        "baby bottle",
        "baby bottles",
        "plastic feeding bottle",
        "plastic feeding bottles",
    ],

    "plug socket": [
        "plug",
        "plugs",
        "socket",
        "sockets",
        "socket outlet",
        "socket outlets",
        "plug and socket",
        "plugs and socket outlets",
    ],

    "information technology equipment": [
        "information technology equipment",
        "it equipment",
        "computer equipment",
        "information technology",
    ],

    "chicken feed": [
        "chicken feed",
        "chicken feeds",
        "poultry feed",
        "poultry feeds",
        "feed for chickens",
    ],

    "cement clinker": [
        "cement clinker",
        "portland cement clinker",
        "clinker",
    ],

    "metakaolin": [
        "metakaolin",
    ],
}


# ============================================================
# PRODUCT FAMILIES
# ============================================================

PRODUCT_FAMILIES = {

    "cement": [
        "cement",
        "सीमेंट",
        "सिमेंट",
    ],

    "pvc cable": [
        "cable",
        "cables",
        "wire",
        "wires",
        "केबल",
    ],

    "polyethylene pipe": [
        "polyethylene pipe",
        "polyethylene pipes",
        "pe pipe",
        "pe pipes",
        "plastic pipe",
        "plastic pipes",
    ],

    "packaged water": [
        "packaged drinking water",
        "packaged natural mineral water",
        "packaged water",
        "bottled water",
        "drinking water",
        "पैकेज्ड ड्रिंकिंग वाटर",
        "पेयजल",
    ],

    "feeding bottle": [
        "feeding bottle",
        "feeding bottles",
        "baby bottle",
        "baby bottles",
        "plastic feeding bottle",
        "plastic feeding bottles",
    ],

    "plug socket": [
        "plug",
        "plugs",
        "socket",
        "sockets",
        "socket outlet",
        "socket outlets",
    ],

    "information technology equipment": [
        "information technology equipment",
        "it equipment",
        "computer equipment",
        "information technology",
    ],

    "chicken feed": [
        "chicken feed",
        "chicken feeds",
        "poultry feed",
        "poultry feeds",
    ],

    "cement clinker": [
        "cement clinker",
        "portland cement clinker",
        "clinker",
    ],

    "metakaolin": [
        "metakaolin",
    ],
}


# ============================================================
# TOKENIZATION
# ============================================================

def tokenize(
    text: str,
) -> set[str]:

    return {
        word

        for word in re.findall(
            r"[a-zA-Z0-9\u0900-\u097F]+",
            normalize_text(text),
        )

        if len(word) > 2
        and word not in STOP_WORDS
    }


# ============================================================
# IS NUMBER NORMALIZATION
# ============================================================

def normalize_is_number(
    value: str,
) -> str:

    value = normalize_text(value)

    value = value.replace(
        "-",
        " ",
    )

    value = value.replace(
        ":",
        " ",
    )

    value = re.sub(
        r"\(\s*part\s*",
        " part ",
        value,
    )

    value = re.sub(
        r"\s*\)",
        "",
        value,
    )

    value = re.sub(
        r"\s+",
        " ",
        value,
    )

    return value.strip()


# ============================================================
# EXTRACT IS NUMBERS
# ============================================================

def extract_is_numbers(
    question: str,
) -> list[str]:

    patterns = [

        # IS 1554 (Part 1):1988
        r"\bis\s*[-:]?\s*(\d{2,6})\s*"
        r"\(\s*part\s*(\d+)\s*\)\s*"
        r"[:\-]?\s*(\d{4})\b",

        # IS 269:2015
        # IS-269:2015
        # IS 269 2015
        r"\bis\s*[-:]?\s*(\d{2,6})\s*"
        r"[:\-]?\s*(\d{4})\b",
    ]

    found = []

    for pattern in patterns:

        for match in re.finditer(
            pattern,
            question or "",
            flags=re.IGNORECASE,
        ):

            groups = match.groups()

            if len(groups) == 3:

                value = (
                    f"is {groups[0]} "
                    f"part {groups[1]} "
                    f"{groups[2]}"
                )

            else:

                value = (
                    f"is {groups[0]} "
                    f"{groups[1]}"
                )

            value = normalize_is_number(value)

            if value not in found:
                found.append(value)

    return found


# ============================================================
# BUILD SEARCH TEXT
# ============================================================

def item_search_text(
    item: dict,
) -> str:

    return " ".join(
        [
            str(item.get("topic", "")),
            str(item.get("content", "")),
            str(item.get("product", "")),
            str(item.get("standard_title", "")),
            str(item.get("is_number", "")),

            " ".join(
                map(
                    str,
                    item.get(
                        "keywords",
                        [],
                    ),
                )
            ),

            " ".join(
                map(
                    str,
                    item.get(
                        "aliases",
                        [],
                    ),
                )
            ),

            str(item.get("industry", "")),
            str(item.get("category", "")),
        ]
    )


# ============================================================
# PRODUCT FAMILY DETECTION
# ============================================================

def detect_product_family(
    question: str,
) -> str | None:

    text = normalize_text(question)

    # Specific phrases first.
    family_order = [
        "information technology equipment",
        "packaged water",
        "polyethylene pipe",
        "feeding bottle",
        "plug socket",
        "cement clinker",
        "pvc cable",
        "chicken feed",
        "metakaolin",
        "cement",
    ]

    for family in family_order:

        aliases = PRODUCT_ALIASES.get(
            family,
            [],
        )

        if any(
            normalize_text(alias) in text
            for alias in aliases
        ):
            return family

    return None


# ============================================================
# PRODUCT FAMILY MATCH
# ============================================================

def item_matches_product_family(
    item: dict,
    family: str,
) -> bool:

    aliases = PRODUCT_FAMILIES.get(
        family,
        [],
    )

    item_text = normalize_text(
        " ".join(
            [
                str(item.get("product", "")),
                str(item.get("standard_title", "")),

                " ".join(
                    map(
                        str,
                        item.get(
                            "aliases",
                            [],
                        ),
                    )
                ),

                " ".join(
                    map(
                        str,
                        item.get(
                            "keywords",
                            [],
                        ),
                    )
                ),
            ]
        )
    )

    return any(
        normalize_text(alias) in item_text
        for alias in aliases
    )


# ============================================================
# PRODUCT ALIAS BONUS
# ============================================================

def alias_bonus(
    question: str,
    item: dict,
) -> int:

    question_normalized = normalize_text(
        question
    )

    item_text = normalize_text(
        item_search_text(item)
    )

    bonus = 0

    product = normalize_text(
        item.get(
            "product",
            "",
        )
    )

    if (
        product
        and product in question_normalized
    ):
        bonus += 10

    for aliases in PRODUCT_ALIASES.values():

        question_has_alias = any(
            normalize_text(alias)
            in question_normalized
            for alias in aliases
        )

        item_has_alias = any(
            normalize_text(alias)
            in item_text
            for alias in aliases
        )

        if (
            question_has_alias
            and item_has_alias
        ):
            bonus += 6

    return bonus


# ============================================================
# GENERAL ITEM SCORING
# ============================================================

def score_item(
    question: str,
    item: dict,
) -> int:

    question_normalized = normalize_text(
        question
    )

    question_tokens = tokenize(
        question
    )

    item_text = normalize_text(
        item_search_text(item)
    )

    item_tokens = tokenize(
        item_text
    )

    overlap = len(
        question_tokens
        & item_tokens
    )

    score = overlap * 2

    score += alias_bonus(
        question,
        item,
    )

    field_weights = [
        ("product", 10),
        ("standard_title", 6),
        ("topic", 4),
        ("industry", 4),
        ("category", 3),
    ]

    for field, weight in field_weights:

        value = normalize_text(
            item.get(
                field,
                "",
            )
        )

        if (
            value
            and value in question_normalized
        ):
            score += weight

    # Strong product-family guard.
    family = detect_product_family(
        question
    )

    if family:

        if item_matches_product_family(
            item,
            family,
        ):
            score += 12

        else:
            # Prevent generic terms such as "electrical"
            # from pulling unrelated electrical products.
            score -= 20

    return score


# ============================================================
# GENERAL BIS KNOWLEDGE RETRIEVAL
# ============================================================

def retrieve_bis_knowledge(
    question: str,
    top_k: int = 4,
):

    ranked = [
        (
            score_item(
                question,
                item,
            ),
            item,
        )

        for item in bis_knowledge
    ]

    ranked.sort(
        key=lambda value: value[0],
        reverse=True,
    )

    return [
        item

        for score, item in ranked

        if score > 0
    ][:top_k]


# ============================================================
# EXACT STANDARD RETRIEVAL
# ============================================================

def retrieve_standard_by_is_number(
    question: str,
    top_k: int = 3,
):

    requested_numbers = extract_is_numbers(
        question
    )

    if not requested_numbers:
        return []

    results = []

    for item in product_standards:

        item_number = normalize_is_number(
            item.get(
                "is_number",
                "",
            )
        )

        if any(
            item_number == requested
            for requested in requested_numbers
        ):

            if item not in results:
                results.append(item)

    return results[:top_k]


# ============================================================
# PRODUCT STANDARD RETRIEVAL
# ============================================================

def extract_voltage_range(question: str) -> tuple[float | None, str | None]:
    """
    Extract a user-mentioned voltage and normalize it to volts.

    Examples:
      1100 V -> 1100
      1.1 kV -> 1100
      6.6 kV -> 6600
      11 kV -> 11000
    """
    text = normalize_text(question)

    pattern = re.compile(
        r"(?<![\d.])(\d+(?:\.\d+)?)\s*(kv|v)\b",
        re.IGNORECASE,
    )

    matches = list(pattern.finditer(text))

    if not matches:
        return None, None

    # Prefer kV when both a converted and an explicit value appear.
    match = matches[0]
    value = float(match.group(1))
    unit = match.group(2).lower()

    volts = value * 1000 if unit == "kv" else value

    return volts, f"{value:g} {unit.upper()}"


def standard_voltage_range(item: dict) -> tuple[float | None, float | None]:
    """
    Read a standard's voltage scope from its title/product/information text.

    This is intentionally conservative. Only the cable standards currently
    represented in the BIS Saathi knowledge base are assigned explicit ranges.
    Unknown standards are left unconstrained.
    """
    is_number = normalize_is_number(
        item.get("is_number", "")
    )

    title = normalize_text(
        item.get("standard_title", "")
    )

    combined = f"{is_number} {title}"

    # IS 694:2010 — up to and including 1100 V.
    if "is 694 2010" == is_number:
        return 0.0, 1100.0

    # IS 1554 Part 1:1988 — up to and including 1100 V.
    if "is 1554 part 1 1988" == is_number:
        return 0.0, 1100.0

    # IS 1554 Part 2:1988 — 3.3 kV to 11 kV.
    if "is 1554 part 2 1988" == is_number:
        return 3300.0, 11000.0

    # Conservative fallback: try to recognize a range from the title.
    lower_upper = re.search(
        r"from\s+(\d+(?:\.\d+)?)\s*kv\s+up\s+to\s+and\s+including\s+(\d+(?:\.\d+)?)\s*kv",
        combined,
        flags=re.IGNORECASE,
    )

    if lower_upper:
        return (
            float(lower_upper.group(1)) * 1000,
            float(lower_upper.group(2)) * 1000,
        )

    upper_v = re.search(
        r"(?:up\s+to|upto)\s+and\s+including\s+(\d+(?:\.\d+)?)\s*v",
        combined,
        flags=re.IGNORECASE,
    )

    if upper_v:
        return 0.0, float(upper_v.group(1))

    upper_kv = re.search(
        r"(?:up\s+to|upto)\s+and\s+including\s+(\d+(?:\.\d+)?)\s*kv",
        combined,
        flags=re.IGNORECASE,
    )

    if upper_kv:
        return 0.0, float(upper_kv.group(1)) * 1000

    return None, None


def voltage_compatibility_score(
    question: str,
    item: dict,
) -> int:
    """
    Score a standard against an explicitly requested voltage.

    Compatible ranges receive a strong bonus. Standards whose known range
    cannot contain the requested voltage receive a strong penalty.
    """
    voltage, _ = extract_voltage_range(question)

    if voltage is None:
        return 0

    minimum, maximum = standard_voltage_range(item)

    if minimum is None and maximum is None:
        return 0

    if (
        (minimum is None or voltage >= minimum)
        and (maximum is None or voltage <= maximum)
    ):
        return 35

    return -60


def retrieve_product_standards(
    question: str,
    top_k: int = 5,
):
    family = detect_product_family(
        question
    )

    candidates = product_standards

    if family:

        family_candidates = [
            item

            for item in product_standards

            if item_matches_product_family(
                item,
                family,
            )
        ]

        # Only apply the hard family filter when
        # it produces valid candidates.
        if family_candidates:
            candidates = family_candidates

    ranked = [
        (
            score_item(
                question,
                item,
            )
            + voltage_compatibility_score(
                question,
                item,
            ),
            item,
        )

        for item in candidates
    ]

    ranked.sort(
        key=lambda value: (
            -value[0],
            normalize_text(
                value[1].get(
                    "is_number",
                    "",
                )
            ),
        )
    )

    voltage, _ = extract_voltage_range(question)

    # When the user explicitly provides a voltage and the knowledge base
    # contains known voltage-scoped candidates, return only compatible
    # standards. This prevents lower-voltage standards from being surfaced
    # for higher-voltage cable questions.
    if voltage is not None:
        compatible = [
            item
            for score, item in ranked
            if score > 0
            and (
                standard_voltage_range(item) == (None, None)
                or (
                    (
                        standard_voltage_range(item)[0] is None
                        or voltage >= standard_voltage_range(item)[0]
                    )
                    and (
                        standard_voltage_range(item)[1] is None
                        or voltage <= standard_voltage_range(item)[1]
                    )
                )
            )
        ]

        if compatible:
            return compatible[:top_k]

    return [
        item

        for score, item in ranked

        if score > 0
    ][:top_k]


# ============================================================
# COMBINE STANDARD RESULTS
# ============================================================

def combine_standard_results(
    exact,
    related,
    top_k: int = 5,
):

    results = []

    for item in list(exact) + list(related):

        if item not in results:
            results.append(item)

    return results[:top_k]


# ============================================================
# INTENT DETECTION
# ============================================================

def detect_intent(
    question: str,
) -> str:

    question_normalized = normalize_text(
        question
    )

    if extract_is_numbers(question):
        return "standard_lookup"

    compliance_words = [
        "compliance",
        "comply",
        "certification",
        "licence",
        "license",
        "mandatory",
        "requirement",
        "requirements",
        "अनुपालन",
        "प्रमाणीकरण",
        "प्रमाणपत्र",
        "आवश्यकता",
        "प्रमाणन",
    ]

    if any(
        word in question_normalized
        for word in compliance_words
    ):
        return "compliance"

    service_words = [
        "service",
        "services",
        "apply",
        "renew",
        "registration",
        "complaint",
        "सेवा",
        "आवेदन",
        "नवीनीकरण",
        "शिकायत",
    ]

    if any(
        word in question_normalized
        for word in service_words
    ):
        return "bis_service"

    standard_words = [
        "standard",
        "standards",
        "is number",
        "indian standard",
        "मानक",
        "आईएस",
    ]

    if any(
        word in question_normalized
        for word in standard_words
    ):
        return "standard_search"

    # Product name alone can imply a standard-search request.
    if detect_product_family(question):
        return "standard_search"

    return "general_bis"


# ============================================================
# FORMAT STANDARD
# ============================================================

def format_standard(
    item: dict,
) -> str:

    checklist = (
        item.get(
            "compliance_checklist"
        )
        or []
    )

    checklist_text = "\n".join(
        f"- {entry}"
        for entry in checklist
    )

    if not checklist_text:
        checklist_text = "Not provided"

    return (
        f"Product: "
        f"{item.get('product', '')}\n"

        f"IS Number: "
        f"{item.get('is_number', '')}\n"

        f"Standard Title: "
        f"{item.get('standard_title', '')}\n"

        f"Certification Status: "
        f"{item.get('certification', '')}\n"

        f"Information: "
        f"{item.get('information', '')}\n"

        f"Compliance Checklist:\n"
        f"{checklist_text}\n"

        f"Official BIS Source: "
        f"{item.get('source', '')}"
    )


# ============================================================
# SOURCE COLLECTION
# ============================================================

def collect_sources(
    *groups,
):

    sources = []

    for group in groups:

        for item in group or []:

            source = item.get(
                "source"
            )

            if (
                source
                and source not in sources
            ):
                sources.append(source)

    return sources


# ============================================================
# BUILD CHAT RETRIEVAL CONTEXT
# ============================================================

def build_chat_context(
    question: str,
):

    exact = retrieve_standard_by_is_number(
        question,
        top_k=3,
    )

    related = retrieve_product_standards(
        question,
        top_k=5,
    )

    general = retrieve_bis_knowledge(
        question,
        top_k=4,
    )

    standards = combine_standard_results(
        exact,
        related,
        top_k=6,
    )

    sections = []

    if exact:

        sections.append(
            "EXACT BIS STANDARD MATCHES:\n"
            +
            "\n\n".join(
                format_standard(item)
                for item in exact
            )
        )

    extra = [
        item

        for item in related

        if item not in exact
    ]

    if extra:

        sections.append(
            "RELATED BIS PRODUCT STANDARDS:\n"
            +
            "\n\n".join(
                format_standard(item)
                for item in extra
            )
        )

    if general:

        general_text = "\n\n".join(
            (
                f"Topic: "
                f"{item.get('topic', '')}\n"

                f"Information: "
                f"{item.get('content', '')}\n"

                f"Official BIS Source: "
                f"{item.get('source', '')}"
            )

            for item in general
        )

        sections.append(
            "GENERAL BIS INFORMATION:\n"
            +
            general_text
        )

    if sections:

        context = "\n\n".join(
            sections
        )

    else:

        context = (
            "No directly matching information "
            "was found in the current BIS "
            "knowledge base."
        )

    return (
        exact,
        extra,
        general,
        standards,
        context,
    )


# ============================================================
# FASTAPI APPLICATION
# ============================================================

app = FastAPI(
    title="BIS Saathi API",

    description=(
        "Backend API for the BIS Saathi "
        "AI assistant"
    ),

    version="1.3.0",
)


# ============================================================
# REQUEST MODELS
# ============================================================

class ChatRequest(BaseModel):

    message: str

    language: str = "English"


class ComplianceRequest(BaseModel):

    product: str

    language: str = "English"


class DocumentQuestionRequest(BaseModel):

    document_id: str

    question: str

    language: str = "English"


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,

    allow_origins=["*"],

    allow_credentials=True,

    allow_methods=["*"],

    allow_headers=["*"],
)


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():

    return {
        "app": "BIS Saathi",

        "status": "running",

        "message": (
            "BIS Saathi backend is working"
        ),

        "version": "1.3.0",
    }


# ============================================================
# HEALTH
# ============================================================

@app.get("/api/health")
def health():

    return {
        "status": "healthy",

        "service": "bis-saathi-api",

        "version": "1.3.0",
    }


# ============================================================
# CHAT API
# ============================================================

@app.post("/api/chat")
def chat(
    request: ChatRequest,
):

    question = request.message.strip()

    language = normalize_language(
        request.language
    )

    if not question:

        return {
            "answer": (
                "Please enter a question "
                "about BIS standards, "
                "certification or services."
            ),

            "sources": [],

            "intent": "general_bis",

            "retrievalMode": "NO DIRECT MATCH",

            "matchedStandards": [],
        }

    # --------------------------------------------------------
    # Detect intent
    # --------------------------------------------------------

    intent = detect_intent(
        question
    )

    # --------------------------------------------------------
    # Retrieve BIS information
    # --------------------------------------------------------

    (
        exact,
        extra,
        general,
        standards,
        context,
    ) = build_chat_context(
        question
    )

    # --------------------------------------------------------
    # Retrieval mode
    # --------------------------------------------------------

    if exact:

        retrieval_mode = (
            "EXACT STANDARD"
        )

    elif extra:

        retrieval_mode = (
            "PRODUCT STANDARD"
        )

    elif general:

        retrieval_mode = (
            "GENERAL BIS"
        )

    else:

        retrieval_mode = (
            "NO DIRECT MATCH"
        )

    # --------------------------------------------------------
    # Gemini prompt
    # --------------------------------------------------------

    prompt = f"""
You are BIS Saathi, an AI assistant specialized
in the Bureau of Indian Standards (BIS).

{language_instruction(language)}

Your job is to help Indian consumers,
manufacturers, businesses and industries
understand BIS standards, certification
and BIS services.

USER INTENT:
{intent}

RETRIEVAL MODE:
{retrieval_mode}

The following information was retrieved
from the BIS Saathi knowledge base.

Use it as the primary evidence.

STRICT GROUNDING RULES:

1. Exact IS-number matches have the
   highest priority.

2. Product-specific records have the
   next priority.

3. General BIS information is supplementary.

4. Never invent:
   - IS numbers
   - standard titles
   - licence numbers
   - QCO requirements
   - fees
   - testing requirements
   - legal obligations
   - application procedures

5. Never infer mandatory BIS certification
   from a keyword match alone.

6. Use only checklist items explicitly
   present in retrieved records.

7. If the knowledge base is insufficient,
   clearly say so.

8. When information is insufficient,
   tell the user to verify the current
   official BIS source.

9. If multiple standards are relevant,
   explain the difference rather than
   silently selecting one.

10. Do not mention an unrelated standard
    merely because it shares generic words
    such as electrical, product, equipment,
    or specification.

11. For product-specific questions,
    prefer standards whose product,
    title, aliases or keywords belong
    to the same detected product family.

12. If the user provides an explicit voltage, prefer only standards whose
    documented voltage range contains that voltage. Do not present a lower-
    voltage standard as applicable to a higher-voltage product.

13. Keep the answer practical and concise.

13. Mention the exact IS number whenever
    an exact standard was retrieved.

14. Answer only in the selected language.

15. Do not translate IS numbers.

16. Do not translate official URLs.

17. Do not pretend that general knowledge
    came from BIS if it was not retrieved.

PREFERRED STRUCTURE FOR AN EXACT STANDARD:

**BIS Standard**
[IS number]

**Product**
[product/title]

**Certification**
[status if available]

**What it means**
[simple explanation]

**Key Information**
[grounded information]

**Compliance Checklist**
[only when available]

**Official Source**
[official source URL]

For general questions,
use a natural structure.

RETRIEVED BIS INFORMATION:

{context}

USER QUESTION:

{question}
"""

    # --------------------------------------------------------
    # Gemini
    # --------------------------------------------------------

    try:

        response = client.models.generate_content(
            model="gemini-3.5-flash-lite",
            contents=prompt,
        )

        answer = (
            response.text
            or
            "I could not generate an answer. "
            "Please try again."
        )

    except Exception as exc:

        print(
            "Gemini chat error:",
            type(exc).__name__,
            exc,
        )

        return {

            "answer": (
                "The AI service could not "
                "generate a response right now. "
                "Please try again."
            ),

            "sources": collect_sources(
                general,
                exact,
                extra,
            ),

            "intent": intent,

            "retrievalMode": retrieval_mode,

            "matchedStandards": [],
        }

    # --------------------------------------------------------
    # Return
    # --------------------------------------------------------

    return {

        "answer": answer,

        "sources": collect_sources(
            general,
            exact,
            extra,
        ),

        "intent": intent,

        "retrievalMode": retrieval_mode,

        "matchedStandards": [

            {
                "isNumber": item.get(
                    "is_number",
                    "",
                ),

                "title": item.get(
                    "standard_title",
                    "",
                ),

                "product": item.get(
                    "product",
                    "",
                ),

                "source": item.get(
                    "source",
                    "",
                ),
            }

            for item in standards
        ],
    }


# ============================================================
# STANDARDS API
# ============================================================

@app.get("/api/standards")
def get_standards(
    query: str = "",
    category: str = "",
    industry: str = "",
):

    query_text = normalize_text(
        query
    )

    category_text = normalize_text(
        category
    )

    industry_text = normalize_text(
        industry
    )

    results = []

    for item in product_standards:

        if category_text:

            item_category = normalize_text(
                item.get(
                    "category",
                    "",
                )
            )

            if category_text not in item_category:
                continue

        if industry_text:

            item_industry = normalize_text(
                item.get(
                    "industry",
                    "",
                )
            )

            if industry_text not in item_industry:
                continue

        if query_text:

            score = score_item(
                query_text,
                item,
            )

            if score <= 0:
                continue

        else:

            score = 1

        results.append(
            {
                "is_number": item.get(
                    "is_number",
                    "",
                ),

                "product": item.get(
                    "product",
                    "",
                ),

                "standard_title": item.get(
                    "standard_title",
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

                "certification": item.get(
                    "certification",
                    "",
                ),

                "information": item.get(
                    "information",
                    "",
                ),

                "source": item.get(
                    "source",
                    "",
                ),

                "revision_year": item.get(
                    "revision_year"
                ),

                "aliases": item.get(
                    "aliases",
                    [],
                ),

                "_score": score,
            }
        )

    results.sort(
        key=lambda item: (
            -item["_score"],
            item.get(
                "is_number",
                "",
            ),
        )
    )

    for item in results:
        item.pop(
            "_score",
            None,
        )

    return {
        "success": True,

        "count": len(results),

        "standards": results,
    }


# ============================================================
# STANDARD DETAIL API
# ============================================================

@app.get(
    "/api/standards/{is_number:path}"
)
def get_standard_by_number(
    is_number: str,
):

    requested = normalize_is_number(
        is_number
    )

    for item in product_standards:

        item_number = normalize_is_number(
            item.get(
                "is_number",
                "",
            )
        )

        if item_number == requested:

            return {
                "success": True,

                "standard": item,
            }

    return {
        "success": False,

        "message": (
            "Standard not found in the "
            "current BIS Saathi knowledge base."
        ),

        "standard": None,
    }


# ============================================================
# COMPLIANCE API
# ============================================================

@app.post("/api/compliance")
def compliance(
    request: ComplianceRequest,
):

    product = request.product.strip()

    language = normalize_language(
        request.language
    )

    if not product:

        return {
            "success": False,

            "message": (
                "Please enter a product name."
            ),

            "standard": None,

            "summary": None,

            "checklist": [],

            "sources": [],
        }

    # --------------------------------------------------------
    # Exact match
    # --------------------------------------------------------

    exact = retrieve_standard_by_is_number(
        product,
        top_k=3,
    )

    # --------------------------------------------------------
    # Product match
    # --------------------------------------------------------

    related = retrieve_product_standards(
        product,
        top_k=5,
    )

    # --------------------------------------------------------
    # Combine
    # --------------------------------------------------------

    matched = combine_standard_results(
        exact,
        related,
        top_k=5,
    )

    # --------------------------------------------------------
    # No match
    # --------------------------------------------------------

    if not matched:

        messages = {

            "English":
                (
                    "No directly matching BIS "
                    "standard was found in the "
                    "current knowledge base. "
                    "Please verify the applicable "
                    "standard on the official "
                    "BIS website."
                ),

            "Hindi":
                (
                    "वर्तमान ज्ञान आधार में सीधे "
                    "मेल खाने वाला BIS मानक नहीं "
                    "मिला। कृपया आधिकारिक BIS "
                    "वेबसाइट पर लागू मानक सत्यापित करें।"
                ),

            "Marathi":
                (
                    "सध्याच्या ज्ञान आधारात थेट "
                    "जुळणारे BIS मानक सापडले नाही. "
                    "कृपया अधिकृत BIS वेबसाइटवर "
                    "लागू मानकाची पडताळणी करा."
                ),
        }

        return {

            "success": False,

            "message": messages[
                language
            ],

            "standard": None,

            "summary": None,

            "checklist": [],

            "sources": [],
        }

    # --------------------------------------------------------
    # Select strongest match
    # --------------------------------------------------------

    standard = matched[0]

    # --------------------------------------------------------
    # Checklist only from BIS data
    # --------------------------------------------------------

    checklist = list(
        standard.get(
            "compliance_checklist"
        )
        or []
    )

    # --------------------------------------------------------
    # Gemini compliance explanation
    # --------------------------------------------------------

    prompt = f"""
You are BIS Saathi,
an AI assistant for BIS compliance guidance.

{language_instruction(language)}

USER PRODUCT:

{product}

RETRIEVED BIS RECORD:

{format_standard(standard)}

Give a short practical explanation
based ONLY on this retrieved BIS record.

IMPORTANT:

Do not invent requirements.

Do not invent fees.

Do not invent testing requirements.

Do not invent licence numbers.

Do not invent government rules.

Do not add checklist items.

Do not claim mandatory status unless
the retrieved record supports it.

Mention the exact IS number.

Tell the user to verify current
official BIS requirements before making
a final compliance decision.

Keep the explanation to 3-5 short sentences.
"""

    try:

        response = client.models.generate_content(
            model="gemini-3.5-flash-lite",
            contents=prompt,
        )

        summary = (
            response.text
            or
            "Compliance information is available "
            "from the retrieved BIS standard."
        )

    except Exception as exc:

        print(
            "Gemini compliance error:",
            type(exc).__name__,
            exc,
        )

        summary = (
            "The standard was matched successfully, "
            "but an AI explanation could not be "
            "generated. Please review the official "
            "BIS source."
        )

    source = standard.get(
        "source"
    )

    return {

        "success": True,

        "message": (
            "BIS compliance information generated."
        ),

        "standard": {

            "product": standard.get(
                "product",
                "",
            ),

            "isNumber": standard.get(
                "is_number",
                "",
            ),

            "title": standard.get(
                "standard_title",
                "",
            ),

            "certification": standard.get(
                "certification",
                "",
            ),

            "information": standard.get(
                "information",
                "",
            ),
        },

        "summary": summary,

        "checklist": checklist,

        "sources": (
            [source]
            if source
            else []
        ),
    }


# ============================================================
# DOCUMENT CHUNKING
# ============================================================

def make_document_chunks(
    text: str,
    page_texts: list[str],
    chunk_size: int = 1800,
    overlap: int = 250,
):

    chunks = []

    for page_number, page_text in enumerate(
        page_texts,
        start=1,
    ):

        clean = re.sub(
            r"\s+",
            " ",
            page_text or "",
        ).strip()

        if not clean:
            continue

        start = 0

        while start < len(clean):

            end = min(
                start + chunk_size,
                len(clean),
            )

            chunks.append(
                {
                    "page": page_number,
                    "text": clean[
                        start:end
                    ],
                }
            )

            if end >= len(clean):
                break

            start = max(
                0,
                end - overlap,
            )

    if not chunks and text:

        clean = re.sub(
            r"\s+",
            " ",
            text,
        ).strip()

        step = (
            chunk_size - overlap
        )

        for start in range(
            0,
            len(clean),
            step,
        ):

            chunks.append(
                {
                    "page": None,

                    "text": clean[
                        start:
                        start + chunk_size
                    ],
                }
            )

    return chunks


# ============================================================
# DOCUMENT RETRIEVAL
# ============================================================

def retrieve_document_chunks(
    question: str,
    chunks: list[dict],
    top_k: int = 6,
):

    question_tokens = tokenize(
        question
    )

    ranked = []

    for chunk in chunks:

        chunk_tokens = tokenize(
            chunk["text"]
        )

        overlap = len(
            question_tokens
            & chunk_tokens
        )

        phrase_bonus = 0

        if (
            normalize_text(question)
            in
            normalize_text(
                chunk["text"]
            )
        ):
            phrase_bonus = 4

        score = (
            overlap * 3
            + phrase_bonus
        )

        ranked.append(
            (
                score,
                chunk,
            )
        )

    ranked.sort(
        key=lambda value: value[0],
        reverse=True,
    )

    useful = [
        chunk

        for score, chunk in ranked

        if score > 0
    ][:top_k]

    if useful:
        return useful

    return chunks[:top_k]


# ============================================================
# DOCUMENT UPLOAD
# ============================================================

@app.post(
    "/api/document/upload"
)
async def upload_document(
    file: UploadFile = File(...),
):

    filename = (
        file.filename
        or
        "document.pdf"
    )

    # --------------------------------------------------------
    # PDF validation
    # --------------------------------------------------------

    if not filename.lower().endswith(
        ".pdf"
    ):

        return {

            "success": False,

            "message": (
                "Only PDF files are supported."
            ),

            "documentId": None,

            "filename": filename,

            "pages": 0,
        }

    # --------------------------------------------------------
    # Read file
    # --------------------------------------------------------

    file_bytes = await file.read()

    if not file_bytes:

        return {

            "success": False,

            "message": (
                "The uploaded PDF is empty."
            ),

            "documentId": None,

            "filename": filename,

            "pages": 0,
        }

    # --------------------------------------------------------
    # Extract PDF text
    # --------------------------------------------------------

    try:

        reader = PdfReader(
            BytesIO(file_bytes)
        )

        page_texts = []

        for page in reader.pages:

            page_text = (
                page.extract_text()
                or ""
            )

            page_texts.append(
                page_text.strip()
            )

        pages = len(
            page_texts
        )

    except Exception as exc:

        print(
            "PDF extraction error:",
            type(exc).__name__,
            exc,
        )

        return {

            "success": False,

            "message": (
                "Could not read the PDF. "
                "Please upload a valid PDF file."
            ),

            "documentId": None,

            "filename": filename,

            "pages": 0,
        }

    # --------------------------------------------------------
    # Combine extracted text
    # --------------------------------------------------------

    extracted_text = "\n\n".join(
        page
        for page in page_texts
        if page
    ).strip()

    if not extracted_text:

        return {

            "success": False,

            "message": (
                "The PDF contains no readable text. "
                "Scanned PDFs will need OCR support."
            ),

            "documentId": None,

            "filename": filename,

            "pages": pages,
        }

    # --------------------------------------------------------
    # Create chunks
    # --------------------------------------------------------

    chunks = make_document_chunks(
        extracted_text,
        page_texts,
    )

    # --------------------------------------------------------
    # Document ID
    # --------------------------------------------------------

    document_id = str(
        uuid.uuid4()
    )

    # --------------------------------------------------------
    # Store document
    # --------------------------------------------------------

    document_store[
        document_id
    ] = {

        "filename": filename,

        "pages": pages,

        "text": extracted_text,

        "page_texts": page_texts,

        "chunks": chunks,
    }

    # --------------------------------------------------------
    # Return
    # --------------------------------------------------------

    return {

        "success": True,

        "message": (
            "PDF uploaded and processed successfully."
        ),

        "documentId": document_id,

        "filename": filename,

        "pages": pages,

        "textLength": len(
            extracted_text
        ),

        "chunks": len(
            chunks
        ),
    }


# ============================================================
# DOCUMENT QUESTION
# ============================================================

@app.post(
    "/api/document/ask"
)
def ask_document(
    request: DocumentQuestionRequest,
):

    language = normalize_language(
        request.language
    )

    question = (
        request.question.strip()
    )

    # --------------------------------------------------------
    # Validate question
    # --------------------------------------------------------

    if not question:

        return {

            "success": False,

            "message": (
                "Please enter a question."
            ),

            "answer": "",
        }

    # --------------------------------------------------------
    # Find document
    # --------------------------------------------------------

    document = document_store.get(
        request.document_id
    )

    if not document:

        return {

            "success": False,

            "message": (
                "Document not found. "
                "Please upload the PDF again."
            ),

            "answer": "",
        }

    # --------------------------------------------------------
    # Retrieve relevant chunks
    # --------------------------------------------------------

    retrieved_chunks = (
        retrieve_document_chunks(
            question,
            document["chunks"],
            top_k=6,
        )
    )

    # --------------------------------------------------------
    # Build context
    # --------------------------------------------------------

    context_parts = []

    for chunk in retrieved_chunks:

        page = chunk.get(
            "page"
        )

        text = chunk.get(
            "text",
            "",
        )

        if page:

            context_parts.append(
                f"[Page {page}] {text}"
            )

        else:

            context_parts.append(
                text
            )

    context = "\n\n".join(
        context_parts
    )

    # --------------------------------------------------------
    # Page references
    # --------------------------------------------------------

    referenced_pages = sorted(
        {
            chunk["page"]

            for chunk in retrieved_chunks

            if chunk.get("page")
            is not None
        }
    )

    # --------------------------------------------------------
    # Gemini document prompt
    # --------------------------------------------------------

    prompt = f"""
You are BIS Saathi,
answering a question from an uploaded document.

{language_instruction(language)}

Answer ONLY from the retrieved document passages.

Do not use outside knowledge
to fill missing information.

If the answer is not supported,
say that the uploaded document
does not provide enough information.

Do not invent legal or compliance
requirements.

When useful, mention the supporting
page number.

DOCUMENT:

{document["filename"]}

RETRIEVED DOCUMENT PASSAGES:

{context}

USER QUESTION:

{question}
"""

    # --------------------------------------------------------
    # Gemini
    # --------------------------------------------------------

    try:

        response = client.models.generate_content(
            model="gemini-3.5-flash-lite",
            contents=prompt,
        )

        answer = (
            response.text
            or
            "I could not generate an answer "
            "from the document."
        )

    except Exception as exc:

        print(
            "Gemini document error:",
            type(exc).__name__,
            exc,
        )

        return {

            "success": False,

            "message": (
                "The AI service could not answer "
                "the document question right now."
            ),

            "answer": "",

            "filename": document[
                "filename"
            ],
        }

    # --------------------------------------------------------
    # Return document answer
    # --------------------------------------------------------

    return {

        "success": True,

        "message": (
            "Answer generated from relevant "
            "document passages."
        ),

        "answer": answer,

        "filename": document[
            "filename"
        ],

        "pages": referenced_pages,

        "retrievedChunks": len(
            retrieved_chunks
        ),
    }