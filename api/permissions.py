from rest_framework.permissions import BasePermission


class IsCharityAdmin(BasePermission):
    """Only allow users with role='charity_admin'."""
    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == 'charity_admin'
        )


class IsDonor(BasePermission):
    """Only allow users with role='donor'."""
    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == 'donor'
        )


class IsCharityOwner(BasePermission):
    """Only allow the charity admin who owns this object to modify it."""
    def has_object_permission(self, request, view, obj):
        if hasattr(obj, 'admin'):
            return obj.admin == request.user
        if hasattr(obj, 'charity'):
            return obj.charity.admin == request.user
        return False
