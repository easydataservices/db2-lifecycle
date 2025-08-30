-- Return lifecycle states with the DELETED bit index (bit 0) set; bits 1 and 2 are preserved.
ALTER MODULE lifecycle
ADD FUNCTION set_deleted(p_lifecycle_states SMALLINT) RETURNS SMALLINT
  DETERMINISTIC
  NO EXTERNAL ACTION
  CONTAINS SQL
BEGIN
  RETURN BITOR(BITAND(p_lifecycle_states, 2 + 4), 1);
END@
