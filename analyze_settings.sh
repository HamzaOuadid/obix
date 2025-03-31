#!/bin/bash

# Analyze Django settings.py file
echo "=== ANALYZING DJANGO SETTINGS.PY ==="

# Target file path
SETTINGS_FILE="/app/debt_chatbot/settings.py"

# Step 1: Extract the entire file for analysis
echo "Extracting entire settings file..."
docker exec obix_backend_1 bash -c "cat $SETTINGS_FILE" > full_settings.py

# Step 2: Display file stats
LINES=$(wc -l < full_settings.py)
echo "Settings file has $LINES lines"

# Step 3: Check for syntax errors with Python
echo "Checking for Python syntax errors..."
cat > check_syntax.py << 'EOF'
import sys
import tokenize
from io import BytesIO

def check_syntax(filename):
    try:
        with open(filename, 'rb') as f:
            bytes_content = f.read()
        
        # Try to tokenize the file to find syntax errors
        try:
            tokenize.tokenize(BytesIO(bytes_content).readline)
            print("No tokenization errors found.")
        except tokenize.TokenError as e:
            print(f"Tokenization error: {e}")
        except IndentationError as e:
            print(f"Indentation error: {e}")
        
        # Try to compile the file
        try:
            compile(bytes_content, filename, 'exec')
            print("No compilation errors found.")
        except SyntaxError as e:
            line_num = e.lineno
            print(f"Syntax error on line {line_num}: {e.msg}")
            
            # Extract the problematic line and context
            with open(filename, 'r') as f:
                lines = f.readlines()
            
            start = max(0, line_num - 5)
            end = min(len(lines), line_num + 5)
            
            print("\nContext:")
            for i in range(start, end):
                prefix = ">>> " if i == line_num - 1 else "    "
                print(f"{prefix}{i+1}: {lines[i].rstrip()}")
                
            # Analyze specific patterns that could cause issues
            if line_num - 1 < len(lines):
                line = lines[line_num - 1]
                if ',' in line and ('}' in line or ')' in line):
                    print("\nPossible issue: Trailing comma in dictionary or tuple")
                if line.strip().endswith((':', ',')) and not lines[line_num].strip():
                    print("\nPossible issue: Dictionary key or value missing")
    
    except Exception as e:
        print(f"Error analyzing file: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        check_syntax(sys.argv[1])
    else:
        print("Please provide a file to check")
EOF

echo "Running syntax check on settings.py..."
python3 check_syntax.py full_settings.py

# Step 4: Check line 189 specifically
echo -e "\nLine 189 content:"
sed -n '189p' full_settings.py
echo -e "\nContext around line 189:"
sed -n '184,194p' full_settings.py

# Step 5: Show common Django settings patterns
echo -e "\nChecking for common Django settings patterns..."
grep -n "^[A-Z_]* = {" full_settings.py | head -10
grep -n "^[A-Z_]* = os.getenv" full_settings.py | head -10

# Step 6: Clean up
rm -f full_settings.py check_syntax.py

echo -e "\nAnalysis complete. Use this information to determine how to fix the settings file." 