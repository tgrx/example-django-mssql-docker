from rest_framework import serializers

from app_example.models import MsSqlTable


class MsSqlTableSerializer(serializers.ModelSerializer):
    class Meta:
        fields = "__all__"
        model = MsSqlTable
