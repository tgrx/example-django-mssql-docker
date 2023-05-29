from rest_framework import viewsets

from app_example.models import MsSqlTable
from app_example.serializers import MsSqlTableSerializer

sql_statement = """
SELECT
    NEWID() as id,
    *
FROM
    INFORMATION_SCHEMA.TABLES
WHERE
    TABLE_TYPE='BASE TABLE';
"""


class MsSqlTableViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MsSqlTable.objects.raw(sql_statement).using(  # type: ignore
        "mssql"
    )
    serializer_class = MsSqlTableSerializer
