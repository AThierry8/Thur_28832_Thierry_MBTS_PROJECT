-- Create synonyms for MBTS_USER's tables
CREATE SYNONYM schedule FOR mbts_user.schedule;
CREATE SYNONYM user_employee_mapping FOR mbts_user.user_employee_mapping;
CREATE SYNONYM employee FOR mbts_user.employee;
CREATE SYNONYM audit_log FOR mbts_user.audit_log;
CREATE SYNONYM holiday FOR mbts_user.holiday;
CREATE SYNONYM clients FOR mbts_user.clients;

-- Create synonyms for procedures/functions
CREATE SYNONYM check_restriction FOR mbts_user.check_restriction;
CREATE SYNONYM log_audit FOR mbts_user.log_audit;

SELECT synonym_name, table_owner, table_name
FROM user_synonyms
ORDER BY synonym_name;

SELECT * FROM audit_log;

SET SERVEROUTPUT ON

-- Test INSERT (using synonym - no schema prefix needed!)
BEGIN
    INSERT INTO schedule (
        schedule_id, route_id, bus_id, driver_id, 
        departure_date, departure_time, available_seats, 
        fare_amount, status
    ) VALUES (
        2000, 3, 3, 3,
        SYSDATE + 3, '14:00', 38,
        2000.00, 'SCHEDULED'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Success!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/