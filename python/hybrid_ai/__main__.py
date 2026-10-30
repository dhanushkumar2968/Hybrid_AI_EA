"""Run the local-only inference API."""

import uvicorn


def main() -> None:
    uvicorn.run(
        "hybrid_ai.service:app",
        host="127.0.0.1",
        port=8765,
        reload=False,
        access_log=False,
    )


if __name__ == "__main__":
    main()
