-- Return each lifecycle state and its bit index.
ALTER MODULE lifecycle
ADD FUNCTION get_states()
  RETURNS TABLE
  (
    state_code VARCHAR(20),
    bit_index SMALLINT
  )
  DETERMINISTIC
  NO EXTERNAL ACTION
  CONTAINS SQL
BEGIN
  PIPE('DELETED', 0);
  PIPE('DRAFT', 1);
  PIPE('LIVE', 2);
  PIPE('DELETED_PENDING', 3);
  PIPE('SUBMITTED', 4);
  RETURN;
END@

