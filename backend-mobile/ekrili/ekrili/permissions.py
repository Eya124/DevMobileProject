from rest_framework.permissions import BasePermission

class IsAdminPermission(BasePermission):
    """
    Allows access only to users with is_admin=True
    """
    def has_permission(self, request, view):
        print( request.user 
           )
        print( 
             request.user.is_authenticated 
           )
        print(
             getattr(request.user, "is_admin", False))
        return bool(
            request.user 
            and request.user.is_authenticated 
            and getattr(request.user, "is_admin", False)
        )
