#!/usr/bin/env python
import json
import uuid


# Convert the JSON object to a string
metadata = json.dumps({'uuid': str(uuid.uuid4())})

# Print the JSON string to file
sourceFile = open('meta_data.json', 'w')
print(metadata, file = sourceFile)
sourceFile.close()
