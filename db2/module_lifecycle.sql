CREATE OR REPLACE MODULE lifecycle;

-- Return each lifecycle state and its bit index.
ALTER MODULE lifecycle
PUBLISH FUNCTION get_states()
  RETURNS TABLE
  (
    state_code VARCHAR(20),
    bit_index SMALLINT
  );

-- Return TRUE if lifecycle states contain specified state code set, FALSE if unset; NULL if the code is invalid.
ALTER MODULE lifecycle
PUBLISH FUNCTION is_state(p_lifecycle_states SMALLINT, p_state_code VARCHAR(20)) RETURNS BOOLEAN;

-- Return lifecycle states with the DELETED bit index (bit 0) set; bits 1 and 2 are preserved.
ALTER MODULE lifecycle
PUBLISH FUNCTION set_deleted(p_lifecycle_states SMALLINT) RETURNS SMALLINT;

-- Return lifecycle states with the DRAFT bit index (bit 1) set, and all other bits unset.
ALTER MODULE lifecycle
PUBLISH FUNCTION set_draft(p_lifecycle_states SMALLINT) RETURNS SMALLINT;

-- Return lifecycle states with the LIVE bit index (bit 2) set, and all other bits unset.
ALTER MODULE lifecycle
PUBLISH FUNCTION set_live(p_lifecycle_states SMALLINT) RETURNS SMALLINT;

-- Return lifecycle states with the DELETED_PENDING bit index (bit 3) set. 
ALTER MODULE lifecycle
PUBLISH FUNCTION set_deleted_pending(p_lifecycle_states SMALLINT) RETURNS SMALLINT;

-- Return lifecycle states with the SUBMITTED bit index (bit 4) set. 
ALTER MODULE lifecycle
PUBLISH FUNCTION set_submitted(p_lifecycle_states SMALLINT) RETURNS SMALLINT;

