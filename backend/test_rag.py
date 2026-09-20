from rag_engine import hybrid_search


TEST_QUESTIONS = [
    "Which BIS standard applies to cement?",
    "I manufacture PVC electrical cables for 6.6 kV. Which standard should I check?",
    "What is IS 269:2015?",
    "What BIS standard applies to packaged drinking water?",
    "What is the BIS certification process?",
]


def main():
    print()
    print("=" * 70)
    print("BIS Saathi RAG V2 - Semantic Retrieval Test")
    print("=" * 70)

    for number, question in enumerate(
        TEST_QUESTIONS,
        start=1,
    ):
        print()
        print("-" * 70)
        print(f"TEST {number}")
        print(f"Question: {question}")
        print("-" * 70)

        try:
            results = hybrid_search(
                question,
                top_k=5,
            )

            if not results:
                print("No results found.")
                continue

            for rank, result in enumerate(
                results,
                start=1,
            ):
                print()
                print(
                    f"{rank}. "
                    f"{result.get('is_number') or result.get('product') or result.get('category')}"
                )

                print(
                    f"   Combined score: "
                    f"{result.get('score')}"
                )

                print(
                    f"   Semantic score: "
                    f"{result.get('semantic_score')}"
                )

                print(
                    f"   Keyword score: "
                    f"{result.get('keyword_score')}"
                )

                print(
                    f"   Product: "
                    f"{result.get('product')}"
                )

                print(
                    f"   Source: "
                    f"{result.get('source')}"
                )

        except Exception as exc:
            print()
            print("RAG TEST ERROR")
            print(
                f"{type(exc).__name__}: {exc}"
            )

    print()
    print("=" * 70)
    print("RAG V2 TEST COMPLETE")
    print("=" * 70)


if __name__ == "__main__":
    main()