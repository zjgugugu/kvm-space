#!/usr/bin/env python3
import re

with open('/usr/share/cockpit/virtualization/bundle.min.js', 'r') as f:
    content = f.read()

# Find cockpit API calls
calls = set(re.findall(r'cockpit\.\w+', content))
print('=== cockpit API calls ===')
for c in sorted(calls):
    print(c)

# Find Chinese strings
zh = set(re.findall(r'"([^"]*[\u4e00-\u9fff]+[^"]*)"', content))
print('\n=== Chinese strings (features) ===')
for z in sorted(zh)[:60]:
    print(z)

# Find component names
names = set(re.findall(r"name:\s*['\"]([^'\"]+)['\"]", content))
print('\n=== Component names ===')
for n in sorted(names):
    print(n)

# Find method-like patterns
methods = set(re.findall(r'(\w{3,30}):\s*function\s*\(', content))
print('\n=== Methods (function declarations) ===')
for m in sorted(methods)[:50]:
    print(m)
