"""Pytest fixtures for optional Databricks Connect integration tests.

Unit tests must be collectable without Spark, Databricks credentials, or a workspace.
The Spark fixture connects only when a test explicitly requests it.
"""

from __future__ import annotations

import csv
import json
import os
import pathlib
import sys

import pytest


@pytest.fixture(scope="session")
def spark():
    """Create a Databricks Spark session only for tests that request this fixture."""
    if os.environ.get("DATABRICKS_SKIP_CONNECT", "").lower() in {"1", "true", "yes"}:
        pytest.skip("Databricks Connect is disabled by DATABRICKS_SKIP_CONNECT")

    try:
        from databricks.connect import DatabricksSession
        from databricks.sdk import WorkspaceClient
    except ImportError:
        pytest.fail(
            "Spark integration tests require the dev dependencies. Run `uv sync --dev`.",
            pytrace=False,
        )

    config = WorkspaceClient().config
    if not config.serverless_compute_id and not config.cluster_id and not os.environ.get("SPARK_REMOTE"):
        url = "https://docs.databricks.com/dev-tools/databricks-connect/cluster-config"
        print("No compute specified; using Databricks serverless compute.", file=sys.stderr)
        print(f"See {url} for manual configuration.", file=sys.stderr)
        os.environ["DATABRICKS_SERVERLESS_COMPUTE_ID"] = "auto"

    builder = DatabricksSession.builder
    if hasattr(builder, "validateSession"):
        return builder.validateSession().getOrCreate()
    return builder.getOrCreate()


@pytest.fixture()
def load_fixture(spark):
    """Return a loader for JSON or CSV files under the repository's fixtures directory."""

    def _loader(filename: str):
        path = pathlib.Path(__file__).parent.parent / "fixtures" / filename
        suffix = path.suffix.lower()
        if suffix == ".json":
            rows = json.loads(path.read_text(encoding="utf-8"))
            return spark.createDataFrame(rows)
        if suffix == ".csv":
            with path.open(newline="", encoding="utf-8") as fixture_file:
                rows = list(csv.DictReader(fixture_file))
            return spark.createDataFrame(rows)
        raise ValueError(f"Unsupported fixture type for: {filename}")

    return _loader
