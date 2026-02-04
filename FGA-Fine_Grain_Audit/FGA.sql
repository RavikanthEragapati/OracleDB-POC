-- ################################################## --
-- ############### LOGIN AS SYS USER ################ --
-- ################################################## --
Drop table POC.CARD_ACCOUNT;

CREATE TABLE "POC"."CARD_ACCOUNT" (
    "ACCT_KEY"     NUMBER(10, 0) NOT NULL ENABLE,
    "MIGRATE_FLAG" VARCHAR2(1 BYTE),
    "INC"          NUMBER
);

-- ################################################## --
-- ############ CREATE FUNCTION ##################### --
-- ################################################## --
-- We need this function because FGA.ADD_POLICY {audit_condition } can not contain more than one clause. 
-- Since we have to check MIGRATE_FLAG is not null and also we have 2 values 'I' and 'M' we need to use simple Migration function

CREATE OR REPLACE FUNCTION poc.check_migrate_flag (p_flag IN VARCHAR2) 
RETURN NUMBER AS
BEGIN
    IF ( p_flag = 'M' OR p_flag = 'I' ) AND p_flag IS NOT NULL
    THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/

-- ############################################################################ --
-- ################## ADD Oracle Fine Grained Audit policy #################### --
-- ############################################################################ --
BEGIN
    DBMS_FGA.ADD_POLICY (
        object_schema   => 'POC',                
        object_name     => 'CARD_ACCOUNT',          
        policy_name     => 'CARD_ACCOUNT_MIGRATED_POLICY_6',
        audit_condition => 'poc.check_migrate_flag(MIGRATE_FLAG) = 1',
        statement_types => 'INSERT, UPDATE, DELETE'
    );
END;
/

-- Note: FGA does not audit actions performed by the SYS user so as to not flood the audit table with system operations.

-- ########## VALIDATE POLICY IS CREATED SUCCESSFULLY ##########--
SELECT POLICY_NAME, POLICY_TEXT FROM DBA_AUDIT_POLICIES ;
SELECT POLICY_NAME, POLICY_TEXT FROM DBA_AUDIT_POLICIES WHERE policy_name like 'CARD_ACCOUNT_MIGRATED_POLICY_%';


-- If value of Unified Auditing PARAMETER is 'True' then audit logs will be streamed to DBA_AUDIT_POLICIES 
-- Else look in DBA_FGA_AUDIT_TRAIL table
SELECT VALUE FROM V$OPTION WHERE PARAMETER = 'Unified Auditing'; 


-- #################################################################### --
-- ####### SELECT/INSERT/UPDATE/DELETE ON CARD_ACCOUNT TABLE ########## --
-- #################################################################### --
select count(*) from poc.CARD_ACCOUNT;


INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC) VALUES (1, 'S', 1);
INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC) VALUES (2, 'S', 1);
INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC) VALUES (3, null, 1);
INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC) VALUES (4, 'I', 1);
INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC) VALUES (5, 'M', 1);

DELETE from poc.CARD_ACCOUNT  where acct_key = 1;
DELETE from poc.CARD_ACCOUNT  where acct_key = 4;

INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC) VALUES (1, 'S', 1);
INSERT INTO poc.CARD_ACCOUNT (ACCT_KEY, MIGRATE_FLAG, INC) VALUES (4, 'I', 1);

update poc.CARD_ACCOUNT set INC = 1 where acct_key = 1;
update poc.CARD_ACCOUNT set INC = 1 where acct_key = 2;
update poc.CARD_ACCOUNT set INC = 1 where acct_key = 3;
update poc.CARD_ACCOUNT set INC = 1 where acct_key = 4;
update poc.CARD_ACCOUNT set INC = 1 where acct_key = 5;


update poc.CARD_ACCOUNT set MIGRATE_FLAG = 'I' where acct_key = 3;
update poc.CARD_ACCOUNT set MIGRATE_FLAG = 'M' where acct_key = 4;

update poc.CARD_ACCOUNT set INC = 2 where acct_key = 3;


-- ################################################## --
-- ################################################## --
-- ################################################## --
SELECT * FROM UNIFIED_AUDIT_TRAIL WHERE FGA_POLICY_NAME = 'CARD_ACCOUNT_MIGRATED_POLICY_6' ORDER BY EVENT_TIMESTAMP DESC;


-- ################################################## --
-- ################# DROP POLICY #################### --
-- ################################################## --
BEGIN
    DBMS_FGA.DROP_POLICY (
        object_schema   => 'POC',                
        object_name     => 'CARD_ACCOUNT',          
        policy_name     => 'CARD_ACCOUNT_MIGRATED_POLICY_6'
    );
END;
/
