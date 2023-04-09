-- Return lifecycle states with the DELETED_PENDING bit index (bit 3) set. 
ALTER MODULE lifecycle
ADD FUNCTION set_deleted_pending(p_lifecycle_states SMALLINT) RETURNS SMALLINT
  DETERMINISTIC
  NO EXTERNAL ACTION
  CONTAINS SQL
BEGIN
  IF BITANDNOT(p_lifecycle_states, 4 + 8) > 0 THEN
    SIGNAL SQLSTATE '22546' SET MESSAGE_TEXT = 'Illegal lifecycle state transition';
  END IF;
  RETURN BITOR(p_lifecycle_states, 8);
END@
