import json
from pathlib import Path


# ============================================================
# BIS SAATHI — SAFE STANDARD DATABASE EXPANSION
# ============================================================
#
# Purpose:
#   Expand product_standards.json to 20+ standards while:
#   - preserving the existing database
#   - creating a backup before modification
#   - preventing duplicate IS numbers
#   - keeping the schema compatible with the current FastAPI RAG
#
# IMPORTANT:
#   This file intentionally does NOT invent detailed compliance
#   requirements. Where detailed certification information has not
#   been verified, certification is marked as "Verify with current
#   official BIS information".
#
# ============================================================


BASE_DIR = Path(__file__).resolve().parent

JSON_PATH = BASE_DIR / "product_standards.json"
BACKUP_PATH = BASE_DIR / "product_standards.backup.json"


# ============================================================
# ADDITIONAL BIS STANDARD RECORDS
# ============================================================

EXTRA_STANDARDS = [
    {
        "is_number": "IS 1489 (Part 1):2015",
        "product": "Portland Pozzolana Cement",
        "standard_title": (
            "Portland Pozzolana Cement — Specification: "
            "Part 1 Fly Ash Based"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for Portland "
            "Pozzolana Cement, Part 1, fly ash based."
        ),
        "keywords": [
            "cement",
            "portland pozzolana cement",
            "ppc",
            "fly ash cement",
            "fly ash based cement",
            "is 1489",
        ],
        "aliases": [
            "PPC",
            "pozzolana cement",
            "fly ash cement",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2015",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 1489 (Part 2):2015",
        "product": "Portland Pozzolana Cement",
        "standard_title": (
            "Portland Pozzolana Cement — Specification: "
            "Part 2 Calcined Clay Based"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for Portland "
            "Pozzolana Cement, Part 2, calcined clay based."
        ),
        "keywords": [
            "cement",
            "portland pozzolana cement",
            "ppc",
            "calcined clay cement",
            "is 1489",
        ],
        "aliases": [
            "PPC",
            "pozzolana cement",
            "calcined clay cement",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2015",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 455:2015",
        "product": "Portland Slag Cement",
        "standard_title": (
            "Portland Slag Cement — Specification"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for Portland "
            "slag cement."
        ),
        "keywords": [
            "cement",
            "portland slag cement",
            "psc",
            "slag cement",
            "is 455",
        ],
        "aliases": [
            "PSC",
            "slag cement",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2015",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 8042:2015",
        "product": "White Portland Cement",
        "standard_title": (
            "White Portland Cement — Specification"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for White "
            "Portland Cement."
        ),
        "keywords": [
            "cement",
            "white cement",
            "white portland cement",
            "is 8042",
        ],
        "aliases": [
            "white cement",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2015",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 4984:2016",
        "product": "Polyethylene Pipes for Water Supply",
        "standard_title": (
            "Polyethylene Pipes for Water Supply — Specification"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for polyethylene "
            "pipes used for water supply."
        ),
        "keywords": [
            "polyethylene pipe",
            "pe pipe",
            "hdpe pipe",
            "water supply pipe",
            "plastic pipe",
            "is 4984",
        ],
        "aliases": [
            "HDPE pipe",
            "PE pipe",
            "water pipe",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2016",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 13428:2024",
        "product": "Packaged Natural Mineral Water",
        "standard_title": (
            "Packaged Natural Mineral Water — Specification"
        ),
        "category": "Food & Water",
        "industry": "Food",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard product specification for "
            "packaged natural mineral water."
        ),
        "keywords": [
            "mineral water",
            "packaged natural mineral water",
            "bottled water",
            "natural mineral water",
            "is 13428",
        ],
        "aliases": [
            "mineral water",
            "bottled mineral water",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2024",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 14543:2024",
        "product": "Packaged Drinking Water",
        "standard_title": (
            "Packaged Drinking Water Other than Packaged "
            "Natural Mineral Water — Specification"
        ),
        "category": "Food & Water",
        "industry": "Food",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard product specification for "
            "packaged drinking water other than packaged "
            "natural mineral water."
        ),
        "keywords": [
            "packaged drinking water",
            "drinking water",
            "bottled drinking water",
            "water",
            "is 14543",
        ],
        "aliases": [
            "packaged water",
            "bottled drinking water",
        ],
        "source": "https://lims.bis.gov.in/home/search_is_number/?is_number__doc_no=14543",
        "revision_year": "2024",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 14625:2015",
        "product": "Plastic Feeding Bottles",
        "standard_title": (
            "Plastics Feeding Bottles — Specification"
        ),
        "category": "Consumer Products",
        "industry": "Consumer Products",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for plastics "
            "feeding bottles."
        ),
        "keywords": [
            "feeding bottle",
            "plastic feeding bottle",
            "baby bottle",
            "consumer product",
            "is 14625",
        ],
        "aliases": [
            "baby bottle",
            "feeding bottle",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2015",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 1293:2019",
        "product": "Plugs and Socket-Outlets",
        "standard_title": (
            "Plugs and Socket-Outlets for Household and "
            "Similar Purposes of Rated Voltage up to and "
            "Including 250 V and Rated Current up to and "
            "Including 16 A — Specification"
        ),
        "category": "Electrical Products",
        "industry": "Electrical",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for household "
            "and similar plugs and socket-outlets up to "
            "250 V and 16 A."
        ),
        "keywords": [
            "plug",
            "socket",
            "socket outlet",
            "electrical plug",
            "electrical socket",
            "is 1293",
        ],
        "aliases": [
            "electrical plug",
            "electrical socket",
            "power socket",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2019",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 13252 (Part 1):2010",
        "product": "Information Technology Equipment",
        "standard_title": (
            "Information Technology Equipment — Safety "
            "Part 1: General Requirements"
        ),
        "category": "Electrical Products",
        "industry": "Electronics & IT",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard covering safety requirements "
            "for information technology equipment, Part 1."
        ),
        "keywords": [
            "it equipment",
            "information technology equipment",
            "computer",
            "computer equipment",
            "electronics",
            "is 13252",
        ],
        "aliases": [
            "computer",
            "IT equipment",
            "computer equipment",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2010",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 10500:2012",
        "product": "Drinking Water",
        "standard_title": (
            "Drinking Water — Specification"
        ),
        "category": "Food & Water",
        "industry": "Water",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for drinking water."
        ),
        "keywords": [
            "drinking water",
            "water quality",
            "potable water",
            "water specification",
            "is 10500",
        ],
        "aliases": [
            "potable water",
            "water quality",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2012",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 1374:2024",
        "product": "Chicken Feeds",
        "standard_title": (
            "Chicken Feeds — Specification"
        ),
        "category": "Food & Agriculture",
        "industry": "Agriculture",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for chicken feeds."
        ),
        "keywords": [
            "chicken feed",
            "poultry feed",
            "animal feed",
            "feed",
            "is 1374",
        ],
        "aliases": [
            "poultry feed",
            "chicken feed",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2024",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 16415:2015",
        "product": "Composite Cement",
        "standard_title": (
            "Composite Cement — Specification"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for composite cement."
        ),
        "keywords": [
            "cement",
            "composite cement",
            "is 16415",
        ],
        "aliases": [
            "composite cement",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2015",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 18189:2023",
        "product": "Portland Calcined Clay Limestone Cement",
        "standard_title": (
            "Portland Calcined Clay Limestone Cement — "
            "Specification"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for Portland "
            "Calcined Clay Limestone Cement."
        ),
        "keywords": [
            "cement",
            "pcc lc",
            "calcined clay limestone cement",
            "portland calcined clay limestone cement",
            "is 18189",
        ],
        "aliases": [
            "PCCLC",
            "calcined clay limestone cement",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2023",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 16353:2015",
        "product": "Portland Cement Clinker",
        "standard_title": (
            "Portland Cement Clinker — Specification"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for Portland "
            "cement clinker."
        ),
        "keywords": [
            "cement clinker",
            "portland clinker",
            "clinker",
            "is 16353",
        ],
        "aliases": [
            "cement clinker",
            "clinker",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2015",
        "compliance_checklist": [],
    },
    {
        "is_number": "IS 16354:2015",
        "product": "Metakaolin",
        "standard_title": (
            "Metakaolin for Use in Cement, Cement Mortar "
            "and Concrete — Specification"
        ),
        "category": "Construction",
        "industry": "Construction",
        "certification": (
            "Verify with current official BIS information"
        ),
        "information": (
            "Indian Standard specification for metakaolin "
            "used in cement, cement mortar and concrete."
        ),
        "keywords": [
            "metakaolin",
            "cement",
            "concrete",
            "cement mortar",
            "is 16354",
        ],
        "aliases": [
            "metakaolin",
        ],
        "source": "https://standards.bis.gov.in/",
        "revision_year": "2015",
        "compliance_checklist": [],
    },
]


# ============================================================
# NORMALIZATION
# ============================================================

def normalize_is_number(value: str) -> str:
    """Create a stable comparison key for an IS number."""

    if not value:
        return ""

    value = str(value).lower()

    value = value.replace("–", "-")
    value = value.replace("—", "-")
    value = value.replace("_", " ")

    value = value.replace("-", " ")
    value = value.replace(":", " ")

    value = value.replace("(", " ")
    value = value.replace(")", " ")

    value = " ".join(value.split())

    return value.strip()


# ============================================================
# VALIDATION
# ============================================================

def validate_standard(item: dict) -> None:
    """Validate the minimum schema required by BIS Saathi."""

    required_fields = [
        "is_number",
        "product",
        "standard_title",
        "category",
        "industry",
        "certification",
        "information",
        "keywords",
        "source",
        "compliance_checklist",
    ]

    missing = [
        field
        for field in required_fields
        if field not in item
    ]

    if missing:
        raise ValueError(
            f"Standard {item.get('is_number')} is missing: "
            f"{', '.join(missing)}"
        )

    if not isinstance(item["keywords"], list):
        raise ValueError(
            f"{item['is_number']}: keywords must be a list."
        )

    if not isinstance(item["compliance_checklist"], list):
        raise ValueError(
            f"{item['is_number']}: compliance_checklist "
            f"must be a list."
        )


# ============================================================
# LOAD EXISTING DATABASE
# ============================================================

if not JSON_PATH.exists():
    raise FileNotFoundError(
        f"Could not find {JSON_PATH}"
    )


with open(JSON_PATH, "r", encoding="utf-8") as file:
    standards = json.load(file)


if not isinstance(standards, list):
    raise ValueError(
        "product_standards.json must contain a JSON list."
    )


# ============================================================
# VALIDATE EXISTING RECORDS
# ============================================================

for existing in standards:
    if not isinstance(existing, dict):
        raise ValueError(
            "Every record in product_standards.json "
            "must be an object."
        )

    if not existing.get("is_number"):
        raise ValueError(
            "An existing standard is missing is_number."
        )


# ============================================================
# CREATE BACKUP
# ============================================================

with open(BACKUP_PATH, "w", encoding="utf-8") as file:
    json.dump(
        standards,
        file,
        indent=2,
        ensure_ascii=False,
    )


# ============================================================
# INDEX EXISTING STANDARD NUMBERS
# ============================================================

existing_numbers = {
    normalize_is_number(
        item.get("is_number", "")
    )
    for item in standards
}


# ============================================================
# ADD NEW RECORDS
# ============================================================

added = []
skipped = []


for standard in EXTRA_STANDARDS:

    validate_standard(standard)

    key = normalize_is_number(
        standard["is_number"]
    )

    if not key:
        raise ValueError(
            "Encountered a standard with an empty IS number."
        )

    if key in existing_numbers:
        skipped.append(
            standard["is_number"]
        )
        continue

    standards.append(standard)

    existing_numbers.add(key)

    added.append(
        standard["is_number"]
    )


# ============================================================
# FINAL VALIDATION
# ============================================================

final_numbers = [
    normalize_is_number(
        item.get("is_number", "")
    )
    for item in standards
]

if len(final_numbers) != len(set(final_numbers)):
    raise ValueError(
        "Duplicate IS numbers detected after update."
    )


# ============================================================
# WRITE DATABASE
# ============================================================

with open(JSON_PATH, "w", encoding="utf-8") as file:
    json.dump(
        standards,
        file,
        indent=2,
        ensure_ascii=False,
    )


# ============================================================
# REPORT
# ============================================================

print()
print("=" * 60)
print("BIS SAATHI — STANDARD DATABASE UPDATE")
print("=" * 60)

print()
print(f"Previous standards : {len(standards) - len(added)}")
print(f"Added standards    : {len(added)}")
print(f"Skipped duplicates : {len(skipped)}")
print(f"Total standards    : {len(standards)}")

print()

if added:
    print("Added:")
    for number in added:
        print(f"  + {number}")

if skipped:
    print()
    print("Already present:")
    for number in skipped:
        print(f"  = {number}")

print()
print(f"Backup : {BACKUP_PATH}")
print(f"Database: {JSON_PATH}")

print()

if len(standards) >= 20:
    print("SUCCESS: BIS Saathi now has 20+ standard records.")
else:
    print(
        "WARNING: Database contains fewer than 20 records."
    )

print()
print("=" * 60)