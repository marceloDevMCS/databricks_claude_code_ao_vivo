"""Testes offline do pipeline: rodam sem Spark, sem credencial e sem workspace.

Cobrem a classe de erro que o `bundle deploy` NAO pega: o deploy fica verde e o
pipeline so quebra quando roda -- ou pior, roda no ambiente errado.

DESCOBERTA DINAMICA (importante para o workshop): nada aqui depende de o agente ter
escolhido um nome de arquivo especifico. O recurso de pipeline e achado varrendo
`resources/*.yml`, e o SQL e achado varrendo `src/**/*.sql`. Assim, se a IA gerar
`pipelines.yml` em vez de `bakehouse_pipeline.yml`, os testes continuam valendo.
"""

import json
import re
from pathlib import Path

import pytest
import yaml

REPO = Path(__file__).resolve().parent.parent
LAYERS = ("bronze", "silver", "gold")

PLACEHOLDER = re.compile(r"\$\{([a-zA-Z_][\w.]*)\}")
CREATE = re.compile(
    r"CREATE\s+OR\s+(?:REFRESH|REPLACE)\s+(?:STREAMING\s+TABLE|MATERIALIZED\s+VIEW)\s+([^\s(;]+)",
    re.IGNORECASE,
)
SCHEMA_RESOURCE = re.compile(r"resources\.schemas\.(\w+)\.name")


# --------------------------------------------------------------------------- descoberta


def _pipeline() -> dict:
    """Primeiro recurso de pipeline declarado em resources/*.yml."""
    for yml in sorted((REPO / "resources").glob("*.yml")):
        doc = yaml.safe_load(yml.read_text()) or {}
        pipelines = (doc.get("resources") or {}).get("pipelines") or {}
        for spec in pipelines.values():
            return spec or {}
    raise AssertionError("nenhum recurso 'pipelines:' encontrado em resources/*.yml")


SQL_FILES = sorted((REPO / "src").rglob("*.sql"))
CONFIG = _pipeline().get("configuration") or {}


def ids(p: Path) -> str:
    return str(p.relative_to(REPO))


def resolve_camada(token: str) -> str | None:
    """'${silver_schema}' | 'silver' -> 'silver'. Devolve None se nao for uma camada."""
    chave = token.strip("${}").strip('`"')
    valor = str(CONFIG.get(chave, chave))
    achado = SCHEMA_RESOURCE.search(valor)
    if achado:
        valor = achado.group(1)
    valor = valor.strip("${}").removesuffix("_schema")
    return valor if valor in LAYERS else None


# --------------------------------------------------------------------------- testes


def test_existe_sql_para_o_pipeline_carregar():
    assert SQL_FILES, "nenhum .sql em src/ -- o pipeline nao tem o que carregar"


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_sql_utf8_sem_bom(sql):
    """BOM no primeiro byte vira caractere SQL e pode quebrar o parser na posição 0."""
    assert not sql.read_bytes().startswith(b"\xef\xbb\xbf"), "remova o BOM UTF-8 deste arquivo SQL"


def test_as_tres_camadas_existem_como_schema_do_bundle():
    """O desenho do workshop: o schema E a camada, declarada como recurso do bundle."""
    declarados = set()
    for yml in sorted((REPO / "resources").glob("*.yml")):
        doc = yaml.safe_load(yml.read_text()) or {}
        declarados |= set((doc.get("resources") or {}).get("schemas") or {})
    faltando = set(LAYERS) - {s.lower() for s in declarados}
    assert not faltando, f"schemas nao declarados como recurso do bundle: {faltando}"


def test_catalogo_e_injetado_por_ambiente_sem_valores_hardcoded():
    """O mesmo bundle deve receber o catalogo escolhido no ambiente que o executa."""
    doc = yaml.safe_load((REPO / "databricks.yml").read_text(encoding="utf-8")) or {}
    catalog = (doc.get("variables") or {}).get("catalog") or {}
    assert "default" not in catalog, "catalog deve vir de BUNDLE_VAR_catalog"

    for target, config in (doc.get("targets") or {}).items():
        value = ((config or {}).get("variables") or {}).get("catalog")
        assert value is None or "${" in str(value), f"catalog hardcoded no target {target}: {value}"

    assert _pipeline().get("catalog") == "${var.catalog}"
    for yml in (REPO / "resources").glob("*.yml"):
        resources = yaml.safe_load(yml.read_text(encoding="utf-8")) or {}
        for schema in ((resources.get("resources") or {}).get("schemas") or {}).values():
            assert schema.get("catalog_name") == "${var.catalog}"
        for dashboard in ((resources.get("resources") or {}).get("dashboards") or {}).values():
            assert dashboard.get("dataset_catalog") == "${var.catalog}"


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_placeholder_do_sql_esta_declarado_no_pipeline(sql):
    """${bronze_shema} com typo deploya sem erro e so morre em runtime."""
    usados = set(PLACEHOLDER.findall(sql.read_text()))
    nao_declarados = usados - set(CONFIG)
    assert not nao_declarados, f"nao declarados em configuration: {nao_declarados}"


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_camada_bate_com_a_pasta(sql):
    """gold/ so pode escrever em gold. Aceita nome de 2 ou 3 partes, literal ou ${}."""
    pasta = sql.parent.name.lower()
    if pasta not in LAYERS:
        pytest.skip(f"'{pasta}' nao e uma pasta de camada")

    escritas = set()
    for alvo in CREATE.findall(sql.read_text()):
        partes = alvo.split(".")
        token = partes[-2] if len(partes) >= 2 else str(_pipeline().get("schema") or "")
        camada = resolve_camada(token)
        if camada:
            escritas.add(camada)

    if not escritas:
        pytest.skip("sem CREATE de tabela/MV neste arquivo")
    assert escritas == {pasta}, f"arquivo em {pasta}/ escreve em {escritas}"


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_destino_sql_usa_catalogo_do_pipeline(sql):
    """As tabelas destino usam o catalogo configurado no bundle, nunca um literal."""
    destinos = CREATE.findall(sql.read_text(encoding="utf-8"))
    for destino in destinos:
        assert destino.startswith(("${medallion_catalog}.", "${var.catalog}."))


@pytest.mark.parametrize("dash", sorted((REPO / "src").rglob("*.lvdash.json")), ids=lambda p: str(p.relative_to(REPO)))
def test_dashboard_sem_catalogo_hardcoded(dash):
    """Dashboard com catalogo no JSON quebra ao trocar de target. Use dataset_catalog/schema."""
    dashboard = json.loads(dash.read_text(encoding="utf-8"))
    for dataset in dashboard.get("datasets", []):
        query = "".join(dataset.get("queryLines", []))
        qualified_sources = re.findall(r"\b(?:FROM|JOIN)\s+([\w$`]+\.[\w$`.]+)", query, re.IGNORECASE)
        assert not qualified_sources, f"use nome de tabela sem catalogo/schema: {qualified_sources}"
