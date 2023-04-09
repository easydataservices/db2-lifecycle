-- Return lifecycle states with the DRAFT bit index (bit 1) set, and all other bits unset.
ALTER MODULE lifecycle
ADD FUNCTION set_draft(p_lifecycle_states SMALLINT) RETURNS SMALLINT
  DETERMINISTIC
  NO EXTERNAL ACTION
  CONTAINS SQL
BEGIN
  RETURN 2;
END@
