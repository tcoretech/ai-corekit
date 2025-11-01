-- Airbyte Database Initialization Script
-- This script creates the second database for synced marketing data
-- Executed automatically by PostgreSQL on first container start

-- Create marketing_data database for synced data
CREATE DATABASE marketing_data;

-- Grant all privileges to airbyte user
GRANT ALL PRIVILEGES ON DATABASE marketing_data TO airbyte;

-- Log successful creation
\echo 'Successfully created marketing_data database for Airbyte synced data'
