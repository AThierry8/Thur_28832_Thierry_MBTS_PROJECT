
-- trigger to restrict certain employees from performing DML operations 
-- on the payment table


create or replace TRIGGER trg_restrict_employees_payment
BEFORE INSERT OR UPDATE OR DELETE ON payment
DECLARE
    v_employee_id NUMBER;
    v_restricted  BOOLEAN;
    v_action_type VARCHAR2(20);
    v_username    VARCHAR2(30) := USER;
BEGIN
    BEGIN
        SELECT employee_id INTO v_employee_id
        FROM user_employee_mapping
        WHERE username = v_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN;
    END;

    IF INSERTING THEN v_action_type := 'INSERT';
    ELSIF UPDATING THEN v_action_type := 'UPDATE';
    ELSE v_action_type := 'DELETE';
    END IF;

    v_restricted := check_restriction(v_employee_id);

    IF v_restricted THEN
        log_audit(v_employee_id, v_action_type, 'PAYMENT', 'DENIED');
        RAISE_APPLICATION_ERROR(-20004, 
            'Employee ' || v_employee_id || ' cannot perform ' || v_action_type || 
            ' on weekdays/holidays.');
    ELSE
        log_audit(v_employee_id, v_action_type, 'PAYMENT', 'ALLOWED');
    END IF;
END trg_restrict_employees_payment;


-- trigger to restrict certain employees from performing DML operations 
-- on the reservation table


create or replace TRIGGER trg_restrict_employees_reservation
BEFORE INSERT OR UPDATE OR DELETE ON reservation
DECLARE
    v_employee_id NUMBER;
    v_restricted  BOOLEAN;
    v_action_type VARCHAR2(20);
    v_username    VARCHAR2(30) := USER;
BEGIN
    BEGIN
        SELECT employee_id INTO v_employee_id
        FROM user_employee_mapping
        WHERE username = v_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN;
    END;

    IF INSERTING THEN v_action_type := 'INSERT';
    ELSIF UPDATING THEN v_action_type := 'UPDATE';
    ELSE v_action_type := 'DELETE';
    END IF;

    v_restricted := check_restriction(v_employee_id);

    IF v_restricted THEN
        log_audit(v_employee_id, v_action_type, 'RESERVATION', 'DENIED');
        RAISE_APPLICATION_ERROR(-20002, 
            'Employee ' || v_employee_id || ' cannot perform ' || v_action_type || 
            ' on weekdays/holidays.');
    ELSE
        log_audit(v_employee_id, v_action_type, 'RESERVATION', 'ALLOWED');
    END IF;
END trg_restrict_employees_reservation;


-- trigger to restrict certain employees from performing DML operations 
-- on the schedule table


    create or replace TRIGGER trg_restrict_employees_schedule
BEFORE INSERT OR UPDATE OR DELETE ON schedule
DECLARE
    v_employee_id NUMBER;
    v_restricted  BOOLEAN;
    v_action_type VARCHAR2(20);
    v_username    VARCHAR2(30) := USER;
BEGIN
    -- Get employee_id from mapping table
    BEGIN
        SELECT employee_id INTO v_employee_id
        FROM user_employee_mapping
        WHERE username = v_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN; -- Not an employee, no restriction
    END;

    -- Determine action type
    IF INSERTING THEN
        v_action_type := 'INSERT';
    ELSIF UPDATING THEN
        v_action_type := 'UPDATE';
    ELSE
        v_action_type := 'DELETE';
    END IF;

    -- Check if restricted (weekday/holiday)
    v_restricted := check_restriction(v_employee_id);

    IF v_restricted THEN
        -- Log DENIED attempt
        log_audit(v_employee_id, v_action_type, 'SCHEDULE', 'DENIED');
        RAISE_APPLICATION_ERROR(-20001, 
            'Employee ' || v_employee_id || ' (' || v_username || 
            ') cannot perform ' || v_action_type || 
            ' on weekdays or holidays.');
    ELSE
        -- Log ALLOWED attempt
        log_audit(v_employee_id, v_action_type, 'SCHEDULE', 'ALLOWED');
    END IF;
END trg_restrict_employees_schedule;


-- trigger to restrict certain employees from performing DML operations 
-- on the ticket table

create or replace TRIGGER trg_restrict_employees_ticket
BEFORE INSERT OR UPDATE OR DELETE ON ticket
DECLARE
    v_employee_id NUMBER;
    v_restricted  BOOLEAN;
    v_action_type VARCHAR2(20);
    v_username    VARCHAR2(30) := USER;
BEGIN
    BEGIN
        SELECT employee_id INTO v_employee_id
        FROM user_employee_mapping
        WHERE username = v_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN;
    END;

    IF INSERTING THEN v_action_type := 'INSERT';
    ELSIF UPDATING THEN v_action_type := 'UPDATE';
    ELSE v_action_type := 'DELETE';
    END IF;

    v_restricted := check_restriction(v_employee_id);

    IF v_restricted THEN
        log_audit(v_employee_id, v_action_type, 'TICKET', 'DENIED');
        RAISE_APPLICATION_ERROR(-20003, 
            'Employee ' || v_employee_id || ' cannot perform ' || v_action_type || 
            ' on weekdays/holidays.');
    ELSE
        log_audit(v_employee_id, v_action_type, 'TICKET', 'ALLOWED');
    END IF;
END trg_restrict_employees_ticket;


