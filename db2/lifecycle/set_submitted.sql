-- Return lifecycle states with the SUBMITTED bit index (bit 4) set. 
ALTER MODULE lifecycle
ADD FUNCTION set_submitted(p_lifecycle_states SMALLINT) RETURNS SMALLINT
  DETERMINISTIC
  NO EXTERNAL ACTION
  CONTAINS SQL
BEGIN
  IF BITANDNOT(p_lifecycle_states, 2 + 8 + 16) > 0 THEN
    SIGNAL SQLSTATE '22546' SET MESSAGE_TEXT = 'Illegal lifecycle state transition';
  END IF;
  RETURN BITOR(p_lifecycle_states, 16);
END@
