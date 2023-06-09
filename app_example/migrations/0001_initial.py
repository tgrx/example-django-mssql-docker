# Generated by Django 4.1.9 on 2023-05-17 21:17

import uuid

from django.db import migrations
from django.db import models


class Migration(migrations.Migration):
    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="MsSqlTable",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4, primary_key=True, serialize=False
                    ),
                ),
                (
                    "catalog",
                    models.TextField(
                        blank=True, db_column="TABLE_CATALOG", null=True
                    ),
                ),
                (
                    "name",
                    models.TextField(
                        blank=True, db_column="TABLE_NAME", null=True
                    ),
                ),
                (
                    "schema",
                    models.TextField(
                        blank=True, db_column="TABLE_SCHEMA", null=True
                    ),
                ),
                (
                    "type",
                    models.TextField(
                        blank=True, db_column="TABLE_TYPE", null=True
                    ),
                ),
            ],
            options={
                "managed": True,
            },
        ),
    ]
