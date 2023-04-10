-- Return lifecycle states with the DRAFT_SUBMITTED bit index (bit 3) set. 
ALTER MODULE lifecycle
ADD FUNCTION set_draft_submitted(p_lifecycle_states SMALLINT) RETURNS SMALLINT
  DETERMINISTIC
  NO EXTERNAL ACTION
  CONTAINS SQL
BEGIN
  IF BITANDNOT(p_lifecycle_states, 2 + 8) > 0 THEN
    SIGNAL SQLSTATE '22546' SET MESSAGE_TEXT = 'Illegal lifecycle state transition';
  END IF;
  RETURN BITOR(p_lifecycle_states, 8);
END@
