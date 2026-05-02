from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RegisterView, CustomAuthToken, ItemViewSet, ClaimRequestViewSet, PoliceStatsView

router = DefaultRouter()
router.register(r'items', ItemViewSet)
router.register(r'requests', ClaimRequestViewSet, basename='requests')

urlpatterns = [
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', CustomAuthToken.as_view(), name='login'),
    path('', include(router.urls)),
    path('stats/', PoliceStatsView.as_view(), name='police-stats'),
]
