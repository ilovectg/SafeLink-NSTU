#!/bin/bash
# Simple script to run the Firebase account creation

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="serviceAccountKey.json"

# Run the Node.js script
node scripts/create_staff_accounts.js
