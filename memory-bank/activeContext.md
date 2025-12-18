# Active Context

## Current Phase
**Refactoring & Standardization**

### Recent Accomplishments
- **Secrets Management Refactor**: Centralized secret generation in `lib/utils/secrets.sh` and `generate_all_secrets.sh`.
- **Update Process Overhaul**: Replaced monolithic `apply_update.sh` with modular `lib/services/update.sh`.
- **Service Structure Enforcement**: 
    - Removed `hooks/` subdirectories from services.
    - Moved lifecycle scripts (`prepare.sh`, `startup.sh`) to service roots.
    - Updated `lib/services/up.sh` to support the new structure.
- **Legacy Logic Migration**: Ported service-specific logic (Vexa, Supabase, LibreTranslate, Seafile) from legacy update scripts to individual service lifecycle scripts.
- **Hardcoding Removal**: Updated scripts to use `$PROJECT_NAME` instead of hardcoded "localai".

## Current State
- **Architecture**: Service-based modular architecture is now strictly enforced.
- **Orchestration**: `launchkit.sh` -> `lib/services/up.sh` handles service lifecycle with proper environment variable propagation.
- **Configuration**: `PROJECT_NAME` is dynamically loaded from `core.yaml` and exported to all child scripts.

## Next Steps
- Verify the full system startup with the new structure.
- Continue with any further service integrations or feature requests.
