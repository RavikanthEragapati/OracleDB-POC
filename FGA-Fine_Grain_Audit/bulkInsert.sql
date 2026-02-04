-- PL/SQL block using ROW-BY-ROW insertion for FGA performance testing.
-- WARNING: This method is significantly slower than FORALL but is required
-- to trigger Fine-Grained Auditing (FGA) policies on every row.
-- This script inserts a total of 1,000,000 rows (200,000 sets of 5 inserts).

DECLARE
    -- Constants
    C_NUM_SETS      CONSTANT PLS_INTEGER := 200000;
    -- Commit every 2,000 sets (2,000 * 5 = 10,000 rows)
    C_COMMIT_FREQ   CONSTANT PLS_INTEGER := 2000; 

    -- Variable to hold the calculated ACCT_KEY offset for each set of 5
    l_base_key_offset PLS_INTEGER;

    -- Counter for committed rows
    l_rows_processed PLS_INTEGER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting row-by-row data insertion for FGA testing...');
    DBMS_OUTPUT.PUT_LINE('Total sets to process: ' || C_NUM_SETS);

    -- Loop 200,000 times (one iteration per set of 5 inserts)
    FOR i IN 1..C_NUM_SETS LOOP
        -- Calculate the starting key for the current set.
        l_base_key_offset := (i - 1) * 5;

        -- ***********************************************
        -- Insert 1: ACCT_KEY = base + 1, MIGRATE_FLAG = 'S'
        -- This is a standalone insert, ensuring FGA is triggered.
        INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC)
        VALUES (l_base_key_offset + 1, 'S', 1);

        -- Insert 2: ACCT_KEY = base + 2, MIGRATE_FLAG = 'S'
        INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC)
        VALUES (l_base_key_offset + 2, 'S', 1);

        -- Insert 3: ACCT_KEY = base + 3, MIGRATE_FLAG = null
        INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC)
        VALUES (l_base_key_offset + 3, NULL, 1);

        -- Insert 4: ACCT_KEY = base + 4, MIGRATE_FLAG = 'I'
        INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC)
        VALUES (l_base_key_offset + 4, 'S', 1);

        -- Insert 5: ACCT_KEY = base + 5, MIGRATE_FLAG = 'M'
        INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC)
        VALUES (l_base_key_offset + 5, 'S', 1);
        -- ***********************************************

        l_rows_processed := l_rows_processed + 5;

        -- Commit Checkpoint (To prevent massive undo/redo log generation)
        IF MOD(i, C_COMMIT_FREQ) = 0 THEN
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Committed ' || l_rows_processed || ' rows so far (at set ' || i || ').');
        END IF;

    END LOOP;

    -- Final Commit for any remaining rows
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Total rows inserted: ' || l_rows_processed);
    DBMS_OUTPUT.PUT_LINE('Final transaction committed.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error during row-by-row insert: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Rollback executed.');
        -- Re-raise the error to stop execution
        RAISE;
END;
/


-- 1000000 inserted | 400000 audited | 97.318 seconds | 86.412 seconds | 98.343 seconds
-- 1000000 inserted | NO ORA_FGA     | 5.978 seconds  | 6.487 seconds  | 6.815 seconds
-- 1000000 inserted | 0 audited      | 10.354 seconds | 10.51 seconds  | 10.187 seconds