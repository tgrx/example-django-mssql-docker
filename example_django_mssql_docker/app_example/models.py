from uuid import uuid4

from django.db import models


class MsSqlTable(models.Model):
    class Meta:
        managed = True

    id = models.UUIDField(  # noqa: A003,VNE003
        primary_key=True,
        default=uuid4,
    )
    catalog = models.TextField(
        null=True,
        blank=True,
        db_column="TABLE_CATALOG",
    )
    name = models.TextField(
        null=True,
        blank=True,
        db_column="TABLE_NAME",
    )
    schema = models.TextField(
        null=True,
        blank=True,
        db_column="TABLE_SCHEMA",
    )
    type = models.TextField(  # noqa: A003,VNE003
        null=True,
        blank=True,
        db_column="TABLE_TYPE",
    )
