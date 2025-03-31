# Django Settings.py Fix and Login Setup Instructions

This document provides step-by-step instructions for fixing the syntax error in settings.py and setting up the direct login functionality on the Django backend.

## The Problem

The backend container is failing to start due to a syntax error in `settings.py` at line 242:
```
} PATCHED_WSGI_APPLICATION = "wsgi_patch.application"
```

This is causing a syntax error because there should be a line break between the closing brace of the previous dictionary and the new variable assignment.

## Container Names

The scripts have been updated to use the correct container names:
- Backend container: `obix_backend_1` (not debt-backend-1)
- Frontend container: `obix_frontend_1`

## Fix Scripts

We've provided scripts with the correct container names to fix this issue:

### Option 1: Complete Fix Script (Recommended)

This script handles both fixing the settings.py file and setting up direct login:

```bash
# 1. Make the script executable
chmod +x fix_login_complete_correct.sh

# 2. Run the script
./fix_login_complete_correct.sh
```

### Option 2: Settings Fix Only

If you only want to fix the settings.py syntax error:

```bash
# 1. Make the script executable
chmod +x fix_settings_correct_container.sh

# 2. Run the script
./fix_settings_correct_container.sh
```

### Option 3: Direct Login Setup Only

If the settings.py file is already fixed and you only need to set up direct login:

```bash
# 1. Make the script executable
chmod +x add_direct_login_correct.sh

# 2. Run the script
./add_direct_login_correct.sh
```

## Manual Fix if All Scripts Fail

If all scripts fail, try this manual approach through docker:

```bash
# 1. Access the container shell
docker exec -it obix_backend_1 bash

# 2. Inside the container, edit the settings.py file
vi /app/debt_chatbot/settings.py

# 3. Go to line 242 (pressing ESC, then typing ":242" and Enter)
# 4. Change the line to just "}" (delete the PATCHED_WSGI_APPLICATION part)
# 5. Save and exit (press ESC, then type ":wq" and Enter)

# 6. Exit the container
exit

# 7. Restart the container
docker restart obix_backend_1
```

## Alternative Manual Fix

If you don't have vi/vim inside the container, you can try this alternate approach:

```bash
# Directly edit the file using sed
docker exec obix_backend_1 bash -c "sed -i 's/} PATCHED_WSGI_APPLICATION.*/}/' /app/debt_chatbot/settings.py"

# Restart the container
docker restart obix_backend_1
```

## Testing the Login

After applying the fixes, test the login at:
```
http://157.230.65.142/login-test.html
```

This page will attempt to log in using the direct login endpoint. If successful, it will store the login information in localStorage for the main application to use.

## Troubleshooting

If you still face issues:

1. Check the backend container logs:
   ```bash
   docker logs obix_backend_1
   ```

2. Verify the syntax error is fixed:
   ```bash
   docker exec obix_backend_1 grep -n "PATCHED_WSGI_APPLICATION" /app/debt_chatbot/settings.py
   ```

3. Ensure the direct login view is properly installed:
   ```bash
   docker exec obix_backend_1 ls -la /app/direct_login_view.py
   ```

4. Check the Django URLs configuration:
   ```bash
   docker exec obix_backend_1 grep -A 3 "direct_login" /app/debt_chatbot/urls.py
   ```

5. If you're having trouble with the file paths or container structure, explore the container to see the actual files:
   ```bash
   docker exec obix_backend_1 find /app -type f -name "*.py" | grep settings
   ```

6. If none of the above works, you may need to check the container's filesystem structure:
   ```bash
   docker exec obix_backend_1 ls -la /app
   ``` 