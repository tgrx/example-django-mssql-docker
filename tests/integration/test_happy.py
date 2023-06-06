import requests


def test_happy() -> None:
    url = "http://localhost:8000/"

    try:
        response: requests.Response = requests.get(url, timeout=30)
    except requests.ConnectionError as exc:
        msg = "django server is not available"
        raise AssertionError(msg) from exc

    assert response.status_code == 200

    assert "Content-Type" in response.headers
    assert response.headers["Content-Type"] == "application/json"

    payload: dict = response.json()
    assert isinstance(payload, list)

    for i, table in enumerate(payload):
        assert isinstance(table, dict), f"invalid table #{i}"

        name = table.get("name")
        assert name, f"invalid name of table #{i}"

        catalog = table.get("catalog")
        assert catalog, f"invalid catalog of table #{i}"

        schema = table.get("schema")
        assert schema, f"invalid schema of table #{i}"

        type = table.get("type")  # noqa: A001,VNE003
        assert type == "BASE TABLE", f"invalid type of table #{i}"
