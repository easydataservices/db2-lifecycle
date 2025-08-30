-- Return TRUE if lifecycle states contain specified state code set, FALSE if unset; NULL if the code is invalid.
ALTER MODULE lifecycle
ADD FUNCTION is_state(p_lifecycle_states SMALLINT, p_state_code VARCHAR(20)) RETURNS BOOLEAN
  DETERMINISTIC
  NO EXTERNAL ACTION
BEGIN
  DECLARE v_states SMALLINT;
  DECLARE v_bit_index SMALLINT;

  SET v_bit_index = (SELECT bit_index FROM TABLE(get_states()) WHERE state_code = p_state_code);
  SET v_states = BITAND(p_lifecycle_states, SMALLINT(POWER(2, v_bit_index)));
  IF v_states = 0 THEN
    RETURN FALSE;
  ELSEIF v_states > 0 THEN
    RETURN TRUE;
  ELSE
    RETURN NULL;
  END IF;
END@

