"""Classify changed repository paths for GitHub Actions CI routing."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import PurePosixPath


DOC_ROOT_FILES = {
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "README.md",
    "SECURITY.md",
    "USER_GUIDE.md",
}


def is_documentation_path(path: str) -> bool:
    normalized = path.replace("\\", "/").lstrip("./")
    return (
        normalized in DOC_ROOT_FILES
        or normalized.startswith("docs/")
        or normalized.startswith("docs_site/")
        or PurePosixPath(normalized).suffix.lower() in {".md", ".mdx"}
    )


def classify(paths: list[str]) -> dict[str, bool]:
    normalized = [path.strip() for path in paths if path.strip()]
    return {
        "app_changed": not normalized
        or any(not is_documentation_path(path) for path in normalized),
        "docs_site_changed": any(
            path.replace("\\", "/").lstrip("./").startswith("docs_site/")
            for path in normalized
        ),
    }


def changed_paths(base: str, head: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", base, head],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.splitlines()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", required=True)
    args = parser.parse_args()
    result = classify(changed_paths(args.base, args.head))
    for name, enabled in result.items():
        print(f"{name}={str(enabled).lower()}")


if __name__ == "__main__":
    main()
