--------------------------------------------------------------------------------------------------------------------------------
-- File:        DIARY_NOTES.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

INSERT INTO object_type(object_type_id, type_name, owner, creator_role, viewer_role)
VALUES
  (5, 'Diary Notes request', 'Sales Customer', 'DIARY_NOTE_CREATOR', 'DIARY_NOTE_VIEWER');

INSERT INTO model(model_id, object_type_id, model_name)
VALUES
  (1, 5, 'Workflow');

INSERT INTO model_state(model_id, bit_index, state_code)
VALUES
  (1, 0, 'DRAFT'),
  (1, 1, 'SUBMITTED'),
  (1, 2, 'APPROVED'),
  (1, 3, 'DATA_SENT'),
  (1, 4, 'PASSCODE_SENT'),
  (1, 5, 'COMPLETE'),
  (1, 6, 'REJECTED'),
  (1, 7, 'CANCELLED');

INSERT INTO state_transition
(
  object_type_id,
  transition_code,
  from_mask,
  from_states,
  bitand_match_rule,
  to_mask_off,
  to_mask_on,
  transition_role,
  transition_quorum,
  description
)
VALUES
  (5, 'SUBMIT', DEFAULT, 1, DEFAULT, DEFAULT, 2, 'DIARY_NOTE_REQUESTER', 1, 'Submit request'),
  (5, 'APPROVE', DEFAULT, 2, DEFAULT, DEFAULT, 4, 'DIARY_NOTE_APPROVER', 1, 'Approve request'),
  (5, 'SEND_DATA', DEFAULT, 4, DEFAULT, DEFAULT, 8, 'DIARY_NOTE_AUTOMATION', 1, 'Send requested data'),
  (5, 'SEND_PASSWORD', DEFAULT, 8, DEFAULT, DEFAULT, 16, 'DIARY_NOTE_AUTOMATION', 1, 'Send password'),
  (5, 'COMPLETE', DEFAULT, 16, DEFAULT, DEFAULT, 32, 'DIARY_NOTE_APPROVER', 1, 'Complete request'),
  (5, 'REJECT', DEFAULT, 2, DEFAULT, DEFAULT, 64, 'DIARY_NOTE_APPROVER', 1, 'Reject request'),
  (5, 'CANCEL', DEFAULT, 3, 'SOME', DEFAULT, 128, 'DIARY_NOTE_REQUESTER', 1, 'Cancel request');

