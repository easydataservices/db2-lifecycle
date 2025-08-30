# Subscription Advanced Example

The previous [Subscription Example](SUBSCRIPTION_EXAMPLE.md) is simple, showing a mechanism for retrieval of subscription transitions, and ackowledgement once they are processed. Once the subscriber acknowledges processing data up to the last processed TRANSITION_ID, in a subsequent call table function SUBSCRIPTION.GET_TRANSITIONS returns transitions with TRANSITION_IDs higher than that last processed TRANSITION_ID. The sequence assigns new TRANSITION_IDs to new transitions in strict order. Subscriptions also process in TRANSITION_ID order. All is well! Except of course that the real world is not always quite so simple...

## Scenarios requiring special handling 

### Uncommitted data
Processing data that has not yet been committed (and could be rolled back, becoming "ghost data") can be acceptable in some specific use cases. Generally however, subscribers need to process only committed data. This introduces a difficulty - waiting on transactions that could have a problem and commit transistions slowly (if ever) is not a good solution.

Skipping uncommmitted data to avoid delay, but returning it later (when and if committed) is best in most cases.

### Missing data
Less commonly than uncommitted data, transitions may simply arrive late. Table function SUBSCRIPTION.GET_TRANSITIONS anticipates that data will be written in TRANSITION_ID order. In subsequent invocations, it expects to return TRANSITION_ID values higher than those previously processed. If however a row for a TRANSITION_ID is missing, it is not practical to wait indefinitely in case it appears later.

One possible scenario where transitions are not written in TRANSITION_ID order, and rows may appear later, is a pureScale environment where sequence TRANSITION_ID has been redefined with NO ORDER. This scenario is untested but should work. However it is likely be suboptimal - because the sequence then has multiple caches, one per pureScale member, the TRANSITION_ID order in which transitions are written becomes unpredictable. From the perspective of function SUBSCRIPTION.GET_TRANSITIONS, this could manifest as apparent gaps in the data. Those gaps are rows that could be added later by another pureScale member, out of the expected order.

What about a typical single member database? One could speculate that thread scheduling delays between the reading of a next sequence value and its insertion in a row might cause an apparent gap in extremely rare scenarios. Whether this is actually possible will depend on Db2 and operating system specifics beyond the knowledge of this writer.

Similar to uncommitted data, skipping missing transitions yet processing them later (if added) is the best approach to missing data.

## Design for handling missing and uncommitted data

It is assumed that scenarios such as those above can happen.

The mechanism for handling missing and uncommitted data is the same. Function SUBSCRIPTION.GET_TRANSITIONS uses a backtrack list to track missing and uncommitted transitions that needs to be reconsidered. Other components of the subscriptions feature determine when to add rows to the backtrack list.

The backtrack list is maintained as a table within the Db2 database.

### Boolean control columns

In addition to the columns shown in the [Subscription Example](SUBSCRIPTION_EXAMPLE.md), table function SUBSCRIPTION.GET_TRANSITIONS returns 3 boolean columns that are used to support backtrack processing:
* ``IS_COMMITTED``: Data that table function SUBSCRIPTION.GET_TRANSITIONS returns includes both committed and uncommitted transitions. Column IS_COMMITTED enables these to be distinguished. It returns a boolean value showing whether or not the returned row is committed data.
* ``IS_DATA_MISSING``: Returns a boolean value showing whether or not there may be missing subscription data between the current and previous row returned. Rows of an object type other than that of the subscription are disregarded; only genuine gaps in the range count as possibly missing data.
* ``IS_BACKTRACK``: Returns a boolean value showing whether a specified transition is already in the backtrack list.

Note that the Db2 command line processor (CLP) displays values for the BOOLEAN data type as an integer. ``1`` means true and ``0`` means false.

The Java API uses the boolean functions to determine whether a transition should be skipped and added to the backtrack list.

In general, uncommitted and possible missing transitions for the subscription object type needs to be handled by backtrack processing.

### Updating the backtrack list

The Java API needs a way to add and missing and uncommitted transitions to the list, and potentially to remove them later. The subscriptions feature provides two stored procedures:
* Procedure ``SUBSCRIPTION.ADD_BACKTRACK_TRANSITION_RANGE``: Adds a specified range of uncommitted or missing transition identifiers to the backtrack list. 
* Procedure ``SUBSCRIPTION.REMOVE_BACKTRACK_TRANSITION``: Removes a transition identifier from the list.

Once a transition is added to the backtrack list for a subscription, it will not be returned again by table function SUBSCRIPTION.GET_TRANSITIONS, unless it is (added and) committed.

## Uncommitted data handling example

In this example, the Db2 command line process (CLP) is used to mimic the processing that would normally be performed by the Java API. We can simulate this using multiple Db2 sessions, with the CLP +c option to disable auto-commit.

There are 3 CLP sessions:
1. Transition CLP session 1: This processes an insurance policy submission 
1. Transition CLP session 2: This processes another insurance policy submission 
1. Subscription CLP session: This represents a subscription to insurance policy changes

### Subscription query

This is used in the Subscription CLP session. The query used in the previous simple scenario is extended to use include the additional boolean control columns:
```
SET SESSION AUTHORIZATION subscriber;

SELECT
  CAST(transition_id AS INTEGER) AS transition_id,
  object_type_id,
  CAST(transition_code AS VARCHAR(15)) as transition_code,
  CAST(object_id AS INTEGER) AS object_id,
  CAST(object_ref AS VARCHAR(10)) AS object_ref,
  from_states,
  to_states,
  transition_utc_ts,
  CAST(transition_db_user AS VARCHAR(19)) AS transition_db_user,
  CAST(transition_client_user AS VARCHAR(21)) AS transition_client_user,
  is_backtrack,
  is_data_missing,
  is_committed
FROM
  TABLE(subscription.get_transitions(101));
```

### Transition CLP session 1: Uncommitted submission 00030201

A web user submits a new policy application. However, due to some issue, the transaction is not committed immediately:
```
SET SESSION AUTHORIZATION insurance;

CALL object_change.add_object(99, '00030201', '{}', 'webuser2350', ?);

CALL object_change.apply_transition(object_info.object_id(99, '00030201'), 'submit', 'webuser2350', '{}', ?);

-- Not committed;
```

###### Example output uncommitted changes
```
DB20000I  The SQL command completed successfully.

  Value of output parameters
  --------------------------
  Parameter Name  : P_OBJECT_ID
  Parameter Value : 83

  Return Status = 0

  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 11

  Return Status = 0
```

### Subscription CLP session: Data retrieval

The subscription query now returns:

###### Example subscription output
```
TRANSITION_ID OBJECT_TYPE_ID TRANSITION_CODE OBJECT_ID   OBJECT_REF FROM_STATES TO_STATES   TRANSITION_UTC_TS       TRANSITION_DB_USER  TRANSITION_CLIENT_USER IS_COMMITTED IS_BACKTRACK
------------- -------------- --------------- ----------- ---------- ----------- ----------- ----------------------- ------------------- ---------------------- ------------ ------------

  0 record(s) selected.
```

No rows! This is because, to prevent unnecessary backtracking, the table function only returns unacknowledged data up to the highest _committed_ transition.

### CLP session 2: Committed submission 00030205

A second web user also submits a new policy application, committed immediately:

```
SET SESSION AUTHORIZATION insurance;

CALL object_change.add_object(99, '00030205', '{}', 'webuser1234', ?);

CALL object_change.apply_transition(object_info.object_id(99, '00030205'), 'submit', 'webuser1234', '{}', ?);

COMMIT;
```

###### Example output committed changes
```
DB20000I  The SQL command completed successfully.

  Value of output parameters
  --------------------------
  Parameter Name  : P_OBJECT_ID
  Parameter Value : 84

  Return Status = 0

  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 13

  Return Status = 0
```

### Subscription CLP session: Data retrieval

The query now shows both the uncommitted transitions and the later committed ones:

###### Example subscription output
```
TRANSITION_ID OBJECT_TYPE_ID TRANSITION_CODE OBJECT_ID   OBJECT_REF FROM_STATES TO_STATES   TRANSITION_UTC_TS       TRANSITION_DB_USER  TRANSITION_CLIENT_USER IS_COMMITTED IS_BACKTRACK
------------- -------------- --------------- ----------- ---------- ----------- ----------- ----------------------- ------------------- ---------------------- ------------ ------------
           10             99 _INIT                    83 00030201             0          81 2025-08-02-21.51.14.601 INSURANCE           webuser2350                       0            0
           11             99 submit                   83 00030201            81          82 2025-08-02-21.51.14.764 INSURANCE           webuser2350                       0            0
           12             99 _INIT                    84 00030205             0          81 2025-08-02-21.55.54.310 INSURANCE           webuser1234                       1            0
           13             99 submit                   84 00030205            81          82 2025-08-02-21.55.54.399 INSURANCE           webuser1234                       1            0

  4 record(s) selected.
```

The IS_COMMITTED column shows which transitions are committed and which are not.

### Subscription CLP session: Adding backtrack rows

The subscriber needs to continue processing committed data, so it adds the uncommitted transitions to the backtrack list:
```
CALL subscription.add_backtrack_transition_range(101, 10, 11);
```

###### Example output uncommitted changes
```
  Return Status = 0
```

Repeating the subscription query:

## See also

* [Subscription Example](SUBSCRIPTION_EXAMPLE.md)
* [Insurance Policy Example](EXAMPLE.md)
* [Overview](../README.md)