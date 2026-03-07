from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsCharityAdmin(BasePermission):
    """Allow access only to users with the 'charity_admin' role."""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            (request.user.role == 'charity_admin' or request.user.is_staff)
        )


class IsDonor(BasePermission):
    """Allow access only to users with the 'donor' role."""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            (request.user.role == 'donor' or request.user.is_staff)
        )


class IsObjectOwner(BasePermission):
    """
    Object-level permission to only allow owners of an object to edit it.
    Assumes the model has one of: 'admin', 'charity', 'creator', or 'donor'.
    """
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request
        if request.method in SAFE_METHODS:
            return True

        if not request.user or not request.user.is_authenticated:
            return False

        # Superusers can do anything
        if request.user.is_staff or request.user.is_superuser:
            return True

        # Check various ownership patterns
        if hasattr(obj, 'admin'):
            return obj.admin == request.user
        if hasattr(obj, 'charity'):
            return obj.charity.admin == request.user
        if hasattr(obj, 'creator'):
            return obj.creator == request.user
        if hasattr(obj, 'donor'):
            return obj.donor == request.user

        return False


# Alias for backward compatibility and semantic clarity
IsCharityOwner = IsObjectOwner
