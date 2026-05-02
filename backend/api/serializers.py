from rest_framework import serializers
from .models import User, Item, ClaimRequest

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'password']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            role=validated_data.get('role', 'citizen')
        )
        return user

class ItemSerializer(serializers.ModelSerializer):
    uploaded_by_name = serializers.CharField(source='uploaded_by.username', read_only=True)
    
    class Meta:
        model = Item
        fields = ['id', 'name', 'category', 'description', 'date_found', 'location', 'reporting_station', 'image', 'status', 'details', 'uploaded_by', 'uploaded_by_name', 'created_at']
        read_only_fields = ['uploaded_by', 'status', 'created_at']

class ClaimRequestSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    item_name = serializers.CharField(source='item.name', read_only=True)
    item_image = serializers.ImageField(source='item.image', read_only=True)
    
    class Meta:
        model = ClaimRequest
        fields = ['id', 'user', 'user_name', 'item', 'item_name', 'item_image', 'message', 'proof_image', 'status', 'created_at']
        read_only_fields = ['user', 'status', 'created_at']
