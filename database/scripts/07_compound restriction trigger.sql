-- This is the code for the compound trigger 
-- that restricts employee 'S' from performing
-- INSERT, UPDATE, DELETE operations on weekdays and holidays.
CREATE OR REPLACE TRIGGER restrict_employee_s_dml
FOR INSERT OR UPDATE OR DELETE
ON YOUR_TABLE
COMPOUND TRIGGER

    v_username VARCHAR2(30);
    v_action   VARCHAR2(20);
    v_date     DATE := SYSDATE;
    v_allowed  BOOLEAN := TRUE;

    -- Before each row
    BEFORE STATEMENT IS
    BEGIN
        v_username := USER;
        v_action := CASE
            WHEN INSERTING THEN 'INSERT'
            WHEN UPDATING THEN 'UPDATE'
            WHEN DELETING THEN 'DELETE'
        END;
    END BEFORE STATEMENT;

    -- Before each row
    BEFORE EACH ROW IS
    BEGIN
        IF v_username = 'S' THEN
            IF is_weekday(v_date) OR is_holiday(v_date) THEN
                v_allowed := FALSE;
                log_audit(v_username, v_action, 'YOUR_TABLE', 'DENIED',
                          'Action not allowed on weekday/holiday');
                RAISE_APPLICATION_ERROR(-20001,
                    'User S cannot perform ' || v_action || ' on weekday or holiday.');
            ELSE
                log_audit(v_username, v_action, 'YOUR_TABLE', 'ALLOWED');
            END IF;
        END IF;
    END BEFORE EACH ROW;

    -- After each row
    AFTER EACH ROW IS
    BEGIN
        NULL; -- Optional: additional logging
    END AFTER EACH ROW;

    -- After statement
    AFTER STATEMENT IS
    BEGIN
        NULL; -- Optional: summary logging
    END AFTER STATEMENT;

END restrict_employee_s_dml;
/