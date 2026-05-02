from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_CHOICES = (
        ('police', 'Police'),
        ('citizen', 'Citizen'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='citizen')

    def __str__(self):
        return f"{self.username} ({self.role})"

class Item(models.Model):
    CATEGORY_CHOICES = (
        ('Mobile', 'Mobile'),
        ('Wallet', 'Wallet'),
        ('Vehicle', 'Vehicle'),
        ('Person', 'Person'),
        ('Others', 'Others'),
    )
    STATUS_CHOICES = (
        ('Available', 'Available'),
        ('Claimed', 'Claimed'),
        ('Verified', 'Verified'),
    )

    name = models.CharField(max_length=255)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    description = models.TextField()
    date_found = models.DateField()
    location = models.CharField(max_length=255)
    reporting_station = models.CharField(max_length=255, default='Central Station')
    image = models.ImageField(upload_to='items/')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Available')
    details = models.JSONField(default=dict, blank=True)
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='uploaded_items')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class ClaimRequest(models.Model):
    STATUS_CHOICES = (
        ('Pending', 'Pending'),
        ('Accepted', 'Accepted'),
        ('Rejected', 'Rejected'),
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='requests')
    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name='requests')
    message = models.TextField()
    proof_image = models.ImageField(upload_to='proofs/', null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Request by {self.user.username} for {self.item.name}"
