from rest_framework import viewsets, permissions, status, generics
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.decorators import action
from .models import User, Item, ClaimRequest
from .serializers import UserSerializer, ItemSerializer, ClaimRequestSerializer

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.AllowAny]

class CustomAuthToken(ObtainAuthToken):
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user_id': user.pk,
            'username': user.username,
            'email': user.email,
            'role': user.role
        })

class ItemViewSet(viewsets.ModelViewSet):
    queryset = Item.objects.all().order_by('-created_at')
    serializer_class = ItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(uploaded_by=self.request.user)

    def get_queryset(self):
        queryset = super().get_queryset()
        category = self.request.query_params.get('category')
        location = self.request.query_params.get('location')
        if category:
            queryset = queryset.filter(category__icontains=category)
        if location:
            queryset = queryset.filter(location__icontains=location)
        return queryset

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        if request.user.role != 'police':
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        item = self.get_object()
        new_status = request.data.get('status')
        if new_status in dict(Item.STATUS_CHOICES):
            item.status = new_status
            item.save()
            return Response({'status': 'Item status updated'})
        return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)

    def destroy(self, request, *args, **kwargs):
        if request.user.role != 'police':
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)
class ClaimRequestViewSet(viewsets.ModelViewSet):
    serializer_class = ClaimRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'police':
            return ClaimRequest.objects.filter(item__uploaded_by=user).order_by('-created_at')
        else:
            return ClaimRequest.objects.filter(user=user).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        if request.user.role != 'police':
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        claim_request = self.get_object()
        new_status = request.data.get('status')
        if new_status in dict(ClaimRequest.STATUS_CHOICES):
            claim_request.status = new_status
            claim_request.save()
            if new_status == 'Accepted':
                item = claim_request.item
                item.status = 'Claimed'
                item.save()
            return Response({'status': 'Request status updated'})
        return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)

class PoliceStatsView(generics.GenericAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role != 'police':
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
        uploaded_items = Item.objects.filter(uploaded_by=request.user).count()
        requests_query = ClaimRequest.objects.filter(item__uploaded_by=request.user)
        accepted_claims = requests_query.filter(status='Accepted').count()
        rejected_claims = requests_query.filter(status='Rejected').count()
        
        return Response({
            'uploaded_items': uploaded_items,
            'accepted_claims': accepted_claims,
            'rejected_claims': rejected_claims,
        })
