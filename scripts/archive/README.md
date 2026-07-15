# Removed One-Time Scripts

The old one-time product imports, seed helpers, data repairs, and test cleanup
scripts were removed for production handoff.

This folder is intentionally kept only as a note so future maintainers know
those tools were removed on purpose. Production catalog data should be managed
from the admin UI, and schema changes should be handled with migrations.
