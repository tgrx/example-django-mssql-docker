from django.contrib import admin
from django.urls import include
from django.urls import path

urlpatterns = [
    path("", include("app_example.urls")),
    path("admin/", admin.site.urls),
    path("drf/", include("rest_framework.urls")),
]
