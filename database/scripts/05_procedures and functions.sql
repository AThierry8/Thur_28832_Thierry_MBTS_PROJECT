-- procedure to add a new bus to the system


create or replace PROCEDURE add_new_bus(
    p_bus_number IN VARCHAR2,
    p_capacity IN NUMBER
)
IS
    v_bus_id NUMBER;
    v_duplicate_check NUMBER;
BEGIN
    -- 1. Check if bus number already exists
    BEGIN
        SELECT 1 INTO v_duplicate_check
        FROM bus
        WHERE bus_number = p_bus_number;

        DBMS_OUTPUT.PUT_LINE('ERROR: Bus number ' || p_bus_number || ' already exists');
        RETURN;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- Good, no duplicate
    END;

    -- 2. Generate new bus ID
    SELECT NVL(MAX(bus_id), 0) + 1 INTO v_bus_id FROM bus;

    -- 3. Insert new bus
    INSERT INTO bus (bus_id, bus_number, capacity)
    VALUES (v_bus_id, p_bus_number, p_capacity);

    DBMS_OUTPUT.PUT_LINE(' New bus added!');
    DBMS_OUTPUT.PUT_LINE('  Bus ID: ' || v_bus_id);
    DBMS_OUTPUT.PUT_LINE('  Bus Number: ' || p_bus_number);
    DBMS_OUTPUT.PUT_LINE('  Capacity: ' || p_capacity);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END add_new_bus;


-- procedure to book a ticket for a client


create or replace PROCEDURE book_ticket(
    p_client_id IN NUMBER,
    p_schedule_id IN NUMBER,
    p_seats_needed IN NUMBER
)
IS
    v_available_seats NUMBER;
    v_fare_per_seat NUMBER;
    v_total_cost NUMBER;
    v_reservation_id NUMBER;
BEGIN
    -- Get schedule info
    SELECT available_seats, fare_amount 
    INTO v_available_seats, v_fare_per_seat
    FROM schedule 
    WHERE schedule_id = p_schedule_id;

    -- Check seat availability
    IF v_available_seats < p_seats_needed THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Only ' || v_available_seats || ' seats available');
        RETURN;
    END IF;

    -- Calculate total
    v_total_cost := p_seats_needed * v_fare_per_seat;

    -- Generate next reservation ID manually
    SELECT NVL(MAX(reservation_id), 0) + 1 
    INTO v_reservation_id
    FROM reservation;

    -- Create reservation
    INSERT INTO reservation (
        reservation_id, 
        client_id, 
        schedule_id, 
        seats_count, 
        total_amount,
        reservation_date,
        status
    ) VALUES (
        v_reservation_id, 
        p_client_id, 
        p_schedule_id, 
        p_seats_needed, 
        v_total_cost,
        SYSDATE,
        'CONFIRMED'
    );

    -- Update seats
    UPDATE schedule 
    SET available_seats = available_seats - p_seats_needed
    WHERE schedule_id = p_schedule_id;

    -- Generate payment ID manually
    DECLARE
        v_payment_id NUMBER;
    BEGIN
        SELECT NVL(MAX(payment_id), 0) + 1 
        INTO v_payment_id
        FROM payment;

        -- Create payment
        INSERT INTO payment (
            payment_id,
            reservation_id, 
            amount,
            payment_date,
            status,
            payment_method
        ) VALUES (
            v_payment_id,
            v_reservation_id, 
            v_total_cost,
            SYSDATE,
            'COMPLETED',
            'CASH'
        );
    END;

    DBMS_OUTPUT.PUT_LINE('SUCCESS: Booking #' || v_reservation_id || ' created');
    DBMS_OUTPUT.PUT_LINE('Total: $' || v_total_cost);

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Schedule or client not found');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        ROLLBACK;
END book_ticket;


-- procedure to cancel a booking


create or replace PROCEDURE cancel_booking(
    p_reservation_id IN NUMBER
)
IS
    v_client_id NUMBER;
    v_schedule_id NUMBER;
    v_seats_count NUMBER;
    v_total_amount NUMBER;
    v_status VARCHAR2(20);
    v_refund_amount NUMBER;
BEGIN
    -- 1. Get reservation details
    BEGIN
        SELECT client_id, schedule_id, seats_count, total_amount, status
        INTO v_client_id, v_schedule_id, v_seats_count, v_total_amount, v_status
        FROM reservation
        WHERE reservation_id = p_reservation_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Reservation ' || p_reservation_id || ' not found');
            RETURN;
    END;

    -- 2. Check if already cancelled
    IF v_status = 'CANCELLED' THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Reservation already cancelled');
        RETURN;
    END IF;

    -- 3. Calculate refund (80% if cancelled > 24 hours before)
    -- For simplicity, we'll refund 80% always
    v_refund_amount := v_total_amount * 0.8;

    -- 4. Update reservation status
    UPDATE reservation 
    SET status = 'CANCELLED'
    WHERE reservation_id = p_reservation_id;

    -- 5. Return seats to schedule
    UPDATE schedule 
    SET available_seats = available_seats + v_seats_count
    WHERE schedule_id = v_schedule_id;

    -- 6. Update payment status
    UPDATE payment 
    SET status = 'REFUNDED',
        amount = v_refund_amount
    WHERE reservation_id = p_reservation_id;

    -- 7. Generate notification ID manually
    DECLARE
        v_notification_id NUMBER;
    BEGIN
        SELECT NVL(MAX(notification_id), 0) + 1 
        INTO v_notification_id 
        FROM notification;

        -- Send notification
        INSERT INTO notification (
            notification_id, client_id, message, sent_date
        ) VALUES (
            v_notification_id, v_client_id,
            'Reservation #' || p_reservation_id || ' cancelled. Refund: $' || v_refund_amount,
            SYSDATE
        );
    END;

    DBMS_OUTPUT.PUT_LINE(' Cancellation successful!');
    DBMS_OUTPUT.PUT_LINE('  Refund issued: $' || v_refund_amount);
    DBMS_OUTPUT.PUT_LINE('  Seats returned: ' || v_seats_count);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END cancel_booking;


-- procedure to generate daily report



create or replace PROCEDURE generate_daily_report(
    p_report_date IN DATE DEFAULT TRUNC(SYSDATE)
)
IS
    v_total_bookings NUMBER;
    v_total_revenue NUMBER;
    v_cancelled_bookings NUMBER;
    v_new_clients NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('DAILY REPORT: ' || TO_CHAR(p_report_date, 'DD-MON-YYYY'));


    -- 1. Total bookings
    SELECT COUNT(*), SUM(total_amount)
    INTO v_total_bookings, v_total_revenue
    FROM reservation
    WHERE TRUNC(reservation_date) = p_report_date
      AND status != 'CANCELLED';

    -- 2. Cancelled bookings
    SELECT COUNT(*)
    INTO v_cancelled_bookings
    FROM reservation
    WHERE TRUNC(reservation_date) = p_report_date
      AND status = 'CANCELLED';

    -- 3. New clients
    SELECT COUNT(*)
    INTO v_new_clients
    FROM clients
    WHERE TRUNC(registration_date) = p_report_date;

    -- 4. Display report
    DBMS_OUTPUT.PUT_LINE('Total Bookings: ' || v_total_bookings);
    DBMS_OUTPUT.PUT_LINE('Total Revenue: $' || NVL(v_total_revenue, 0));
    DBMS_OUTPUT.PUT_LINE('Cancelled Bookings: ' || v_cancelled_bookings);
    DBMS_OUTPUT.PUT_LINE('New Clients: ' || v_new_clients);


EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' Error generating report: ' || SQLERRM);
END generate_daily_report;


-- procedure to log audit trails



create or replace PROCEDURE log_audit (
    p_employee_id  IN NUMBER,
    p_action_type  IN VARCHAR2,
    p_table_name   IN VARCHAR2,
    p_status       IN VARCHAR2
) IS
    PRAGMA AUTONOMOUS_TRANSACTION; -- So trigger can log even if operation fails
BEGIN
    INSERT INTO audit_log (
        log_id, employee_id, action_type, table_name, action_date, status
    ) VALUES (
        audit_log_seq.NEXTVAL, p_employee_id, p_action_type, p_table_name, SYSDATE, p_status
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END log_audit;





-- function to calculate total revenue

create or replace FUNCTION calculate_total_revenue(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
) RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    IF p_start_date IS NULL AND p_end_date IS NULL THEN
        -- All time revenue
        SELECT SUM(total_amount)
        INTO v_total
        FROM reservation
        WHERE status != 'CANCELLED';
    ELSE
        -- Date range revenue
        SELECT SUM(total_amount)
        INTO v_total
        FROM reservation
        WHERE status != 'CANCELLED'
          AND reservation_date BETWEEN 
              NVL(p_start_date, reservation_date) 
              AND NVL(p_end_date, reservation_date);
    END IF;

    RETURN NVL(v_total, 0);

EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END calculate_total_revenue;

-- function to check if an employee is restricted from performing actions  this 
-- checks if it the day is in week days and cancels the action if true 


create or replace FUNCTION check_restriction (
    p_employee_id IN NUMBER
) RETURN BOOLEAN
IS
    v_day_of_week VARCHAR2(10);
    v_is_holiday NUMBER;
BEGIN
    -- Check if today is a weekday (Monday-Friday)
    v_day_of_week := TO_CHAR(SYSDATE, 'DY');
    IF v_day_of_week IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        RETURN TRUE; -- Restricted (weekday)
    END IF;

    -- Check if today is a holiday (upcoming month only)
    SELECT COUNT(*)
    INTO v_is_holiday
    FROM holiday
    WHERE holiday_date = TRUNC(SYSDATE);

    IF v_is_holiday > 0 THEN
        RETURN TRUE; -- Restricted (holiday)
    END IF;

    RETURN FALSE; -- Allowed (weekend and not holiday)
END check_restriction;


-- function to check if a client exists
create or replace FUNCTION client_exists(
    p_client_id IN NUMBER
) RETURN BOOLEAN
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM clients
    WHERE client_id = p_client_id;

    RETURN v_count > 0;
END client_exists;

-- function to get bus information ! this helps 
-- us know the bus capacit ,its schedules and  bus_number

create or replace FUNCTION get_bus_info(
    p_bus_id IN NUMBER
) RETURN VARCHAR2
IS
    v_bus_number VARCHAR2(20);
    v_capacity NUMBER;
    v_schedules NUMBER;
BEGIN
    -- Get bus details
    SELECT bus_number, capacity
    INTO v_bus_number, v_capacity
    FROM bus
    WHERE bus_id = p_bus_id;

    -- Count schedules for this bus
    SELECT COUNT(*)
    INTO v_schedules
    FROM schedule
    WHERE bus_id = p_bus_id
      AND departure_date >= SYSDATE;

    RETURN 'Bus ' || v_bus_number || 
           ' (Capacity: ' || v_capacity || 
           ', Future trips: ' || v_schedules || ')';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Bus not found';
END get_bus_info;

-- function to get client email address

create or replace FUNCTION get_client_email(
    p_client_id IN NUMBER
) RETURN VARCHAR2
IS
    v_email VARCHAR2(100);
BEGIN
    SELECT email
    INTO v_email
    FROM clients
    WHERE client_id = p_client_id;

    RETURN v_email;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Client not found';
END get_client_email;



-- function to check available seats for a schedule

create or replace FUNCTION has_available_seats(
    p_schedule_id IN NUMBER
) RETURN VARCHAR2
IS
    v_available NUMBER;
    v_capacity NUMBER;
BEGIN
    -- Get seats info
    SELECT s.available_seats, b.capacity
    INTO v_available, v_capacity
    FROM schedule s
    JOIN bus b ON s.bus_id = b.bus_id
    WHERE s.schedule_id = p_schedule_id;

    -- Return result
    IF v_available > 0 THEN
        RETURN 'YES - ' || v_available || ' seats available';
    ELSE
        RETURN 'NO - Bus is full';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ERROR: Schedule not found';
END has_available_seats;



-- function to validate email format

create or replace FUNCTION is_valid_email(
    p_email IN VARCHAR2
) RETURN VARCHAR2
IS
BEGIN
    -- Simple email validation
    IF p_email LIKE '%@%.%' 
       AND LENGTH(p_email) >= 5 
       AND p_email NOT LIKE '@%' 
       AND p_email NOT LIKE '%@' THEN
        RETURN 'VALID';
    ELSE
        RETURN 'INVALID - Must contain @ and .';
    END IF;
END is_valid_email;



