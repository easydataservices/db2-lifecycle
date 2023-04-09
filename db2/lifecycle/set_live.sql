-- Return lifecycle states with the LIVE bit index (bit 2) set, and all other bits unset.
ALTER MODULE lifecycle
ADD FUNCTION set_live(p_lifecycle_states SMALLINT) RETURNS SMALLINT
  DETERMINISTIC
  NO EXTERNAL ACTION
  CONTAINS SQL
BEGIN
  RETURN 4;
END@
