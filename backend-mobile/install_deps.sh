#!/bin/bash

echo "Installing Python dependencies with --break-system-packages..."

python3 -m pip install django==5.0.4 --break-system-packages
python3 -m pip install djangorestframework==3.15.1 --break-system-packages
python3 -m pip install django-cors-headers==4.3.1 --break-system-packages
python3 -m pip install social-auth-app-django==5.4.0 --break-system-packages
python3 -m pip install celery --break-system-packages
python3 -m pip install django-celery-beat==2.6.0 --break-system-packages
python3 -m pip install mysqlclient==2.2.4 --break-system-packages
python3 -m pip install pandas --break-system-packages
python3 -m pip install python-Levenshtein --break-system-packages
python3 -m pip install scikit-learn --break-system-packages
python3 -m pip install redis --break-system-packages

echo "✅ All packages installed."
