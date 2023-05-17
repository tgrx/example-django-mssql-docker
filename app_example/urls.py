from django.urls import include
from django.urls import path
from rest_framework import routers

from app_example.viewsets import MsSqlTableViewSet

router = routers.DefaultRouter()
router.register("", MsSqlTableViewSet)

urlpatterns = [
    path("", include(router.urls)),
]
