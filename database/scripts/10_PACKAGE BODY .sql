create or replace PACKAGE BODY admin_pkg IS
    
    -- 1. ADD NEW BUS
    PROCEDURE add_bus(
        p_bus_number IN VARCHAR2,
        p_capacity IN NUMBER
    ) IS
        v_bus_id NUMBER;
    BEGIN
        -- Check if bus number exists
        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count
            FROM bus WHERE bus_number = p_bus_number;

            IF v_count > 0 THEN
                DBMS_OUTPUT.PUT_LINE(' Error: Bus number exists');
                RETURN;
            END IF;
        END;

        -- Generate new ID
        SELECT NVL(MAX(bus_id), 0) + 1 INTO v_bus_id FROM bus;

        -- Insert bus
        INSERT INTO bus (bus_id, bus_number, capacity)
        VALUES (v_bus_id, p_bus_number, p_capacity);

        DBMS_OUTPUT.PUT_LINE('Bus added: ' || p_bus_number);
        DBMS_OUTPUT.PUT_LINE('   ID: ' || v_bus_id);
        DBMS_OUTPUT.PUT_LINE('   Capacity: ' || p_capacity);

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(' Error: ' || SQLERRM);
    END add_bus;

    -- 2. ADD NEW ROUTE
    PROCEDURE add_route(
        p_from IN VARCHAR2,
        p_to IN VARCHAR2,
        p_distance IN NUMBER,
        p_hours IN NUMBER
    ) IS
        v_route_id NUMBER;
    BEGIN
        -- Check if route exists
        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count
            FROM route 
            WHERE departure_location = p_from
              AND destination = p_to;

            IF v_count > 0 THEN
                DBMS_OUTPUT.PUT_LINE(' Error: Route exists');
                RETURN;
            END IF;
        END;

        -- Generate new ID
        SELECT NVL(MAX(route_id), 0) + 1 INTO v_route_id FROM route;

        -- Insert route
        INSERT INTO route (route_id, departure_location, destination, 
                          distance_km, estimated_hours)
        VALUES (v_route_id, p_from, p_to, p_distance, p_hours);

        DBMS_OUTPUT.PUT_LINE(' Route added: ' || p_from || ' → ' || p_to);
        DBMS_OUTPUT.PUT_LINE('   ID: ' || v_route_id);
        DBMS_OUTPUT.PUT_LINE('   Distance: ' || p_distance || ' km');

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END add_route;

    -- 3. ADD NEW SCHEDULE
    PROCEDURE add_schedule(
        p_route_id IN NUMBER,
        p_bus_id IN NUMBER,
        p_departure_date IN DATE,
        p_departure_time IN VARCHAR2,
        p_fare IN NUMBER
    ) IS
        v_schedule_id NUMBER;
        v_capacity NUMBER;
        v_driver_id NUMBER;
    BEGIN
        -- Get bus capacity
        SELECT capacity INTO v_capacity
        FROM bus WHERE bus_id = p_bus_id;

        -- Get first driver (for simplicity)
        SELECT MIN(driver_id) INTO v_driver_id
        FROM driver;

        -- Generate schedule ID
        SELECT NVL(MAX(schedule_id), 0) + 1 INTO v_schedule_id FROM schedule;

        -- Insert schedule
        INSERT INTO schedule (
            schedule_id, route_id, bus_id, driver_id,
            departure_date, departure_time, available_seats,
            fare_amount, status
        ) VALUES (
            v_schedule_id, p_route_id, p_bus_id, v_driver_id,
            p_departure_date, p_departure_time, v_capacity,
            p_fare, 'SCHEDULED'
        );

        DBMS_OUTPUT.PUT_LINE(' Schedule added');
        DBMS_OUTPUT.PUT_LINE('   ID: ' || v_schedule_id);
        DBMS_OUTPUT.PUT_LINE('   Date: ' || TO_CHAR(p_departure_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('   Time: ' || p_departure_time);
        DBMS_OUTPUT.PUT_LINE('   Fare: $' || p_fare);

        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE(' Error: Bus or driver not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(' Error: ' || SQLERRM);
    END add_schedule;

    -- 4. DAILY REPORT
    PROCEDURE show_daily_report(
        p_date IN DATE DEFAULT SYSDATE
    ) IS
        v_bookings NUMBER;
        v_revenue NUMBER;
        v_cancellations NUMBER;
        v_trips NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('📊 DAILY REPORT: ' || TO_CHAR(p_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('=======================');

        -- Bookings
        SELECT COUNT(*), SUM(total_amount)
        INTO v_bookings, v_revenue
        FROM reservation
        WHERE TRUNC(reservation_date) = TRUNC(p_date)
          AND status = 'CONFIRMED';

        -- Cancellations
        SELECT COUNT(*)
        INTO v_cancellations
        FROM reservation
        WHERE TRUNC(reservation_date) = TRUNC(p_date)
          AND status = 'CANCELLED';

        -- Trips
        SELECT COUNT(*)
        INTO v_trips
        FROM schedule
        WHERE departure_date = TRUNC(p_date);

        DBMS_OUTPUT.PUT_LINE('Bookings:      ' || NVL(v_bookings, 0));
        DBMS_OUTPUT.PUT_LINE('Revenue:       $' || NVL(v_revenue, 0));
        DBMS_OUTPUT.PUT_LINE('Cancellations: ' || NVL(v_cancellations, 0));
        DBMS_OUTPUT.PUT_LINE('Trips:         ' || NVL(v_trips, 0));

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error generating report');
    END show_daily_report;

    -- 5. DAILY REVENUE
    FUNCTION get_daily_revenue(
        p_date IN DATE DEFAULT SYSDATE
    ) RETURN NUMBER IS
        v_revenue NUMBER;
    BEGIN
        SELECT SUM(total_amount)
        INTO v_revenue
        FROM reservation
        WHERE TRUNC(reservation_date) = TRUNC(p_date)
          AND status = 'CONFIRMED';

        RETURN NVL(v_revenue, 0);

    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_daily_revenue;

    -- 6. BUSIEST ROUTE
    FUNCTION get_busiest_route RETURN VARCHAR2 IS
        v_route_name VARCHAR2(100);
        v_trip_count NUMBER;
    BEGIN
        SELECT r.departure_location || ' to ' || r.destination,
               COUNT(s.schedule_id)
        INTO v_route_name, v_trip_count
        FROM route r
        JOIN schedule s ON r.route_id = s.route_id
        GROUP BY r.departure_location, r.destination
        ORDER BY COUNT(s.schedule_id) DESC
        FETCH FIRST 1 ROWS ONLY;

        RETURN v_route_name || ' (' || v_trip_count || ' trips)';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'No routes found';
    END get_busiest_route;

END admin_pkg;


-- 


create or replace PACKAGE BODY booking_pkg IS
    
    -- 1. BOOK TICKET
    PROCEDURE book_ticket(
        p_client_id IN NUMBER,
        p_schedule_id IN NUMBER,
        p_seats IN NUMBER
    ) IS
        v_available_seats NUMBER;
        v_fare_amount NUMBER;
        v_total_cost NUMBER;
        v_reservation_id NUMBER;
    BEGIN
        -- Check available seats
        SELECT available_seats, fare_amount 
        INTO v_available_seats, v_fare_amount
        FROM schedule 
        WHERE schedule_id = p_schedule_id;

        -- If not enough seats
        IF v_available_seats < p_seats THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error: Only ' || v_available_seats || ' seats left');
            RETURN;
        END IF;

        -- Calculate total
        v_total_cost := p_seats * v_fare_amount;

        -- Generate reservation ID
        SELECT NVL(MAX(reservation_id), 0) + 1 
        INTO v_reservation_id 
        FROM reservation;

        -- Create reservation
        INSERT INTO reservation (
            reservation_id, client_id, schedule_id, 
            seats_count, total_amount, status
        ) VALUES (
            v_reservation_id, p_client_id, p_schedule_id,
            p_seats, v_total_cost, 'CONFIRMED'
        );

        -- Update seats
        UPDATE schedule 
        SET available_seats = available_seats - p_seats
        WHERE schedule_id = p_schedule_id;

        -- Create payment
        DECLARE
            v_payment_id NUMBER;
        BEGIN
            SELECT NVL(MAX(payment_id), 0) + 1 
            INTO v_payment_id 
            FROM payment;

            INSERT INTO payment (
                payment_id, reservation_id, amount, status
            ) VALUES (
                v_payment_id, v_reservation_id, v_total_cost, 'COMPLETED'
            );
        END;

        DBMS_OUTPUT.PUT_LINE('✅ Booking successful!');
        DBMS_OUTPUT.PUT_LINE('   Booking ID: ' || v_reservation_id);
        DBMS_OUTPUT.PUT_LINE('   Total: $' || v_total_cost);

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
            ROLLBACK;
    END book_ticket;

    -- 2. CANCEL TICKET
    PROCEDURE cancel_ticket(
        p_reservation_id IN NUMBER
    ) IS
        v_seats_count NUMBER;
        v_schedule_id NUMBER;
        v_total_amount NUMBER;
        v_refund_amount NUMBER;
    BEGIN
        -- Get reservation details
        SELECT seats_count, schedule_id, total_amount
        INTO v_seats_count, v_schedule_id, v_total_amount
        FROM reservation
        WHERE reservation_id = p_reservation_id;

        -- Calculate 80% refund
        v_refund_amount := v_total_amount * 0.8;

        -- Mark as cancelled
        UPDATE reservation 
        SET status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;

        -- Return seats
        UPDATE schedule 
        SET available_seats = available_seats + v_seats_count
        WHERE schedule_id = v_schedule_id;

        -- Update payment
        UPDATE payment 
        SET status = 'REFUNDED',
            amount = v_refund_amount
        WHERE reservation_id = p_reservation_id;

        DBMS_OUTPUT.PUT_LINE('✅ Cancellation successful!');
        DBMS_OUTPUT.PUT_LINE('   Refund: $' || v_refund_amount);

        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error: Booking not found');
    END cancel_ticket;

    -- 3. CHECK AVAILABLE SEATS
    FUNCTION check_available_seats(
        p_schedule_id IN NUMBER
    ) RETURN VARCHAR2 IS
        v_available NUMBER;
        v_capacity NUMBER;
    BEGIN
        SELECT s.available_seats, b.capacity
        INTO v_available, v_capacity
        FROM schedule s
        JOIN bus b ON s.bus_id = b.bus_id
        WHERE s.schedule_id = p_schedule_id;

        RETURN v_available || ' out of ' || v_capacity || ' seats available';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Schedule not found';
    END check_available_seats;

    -- 4. CALCULATE FARE
    FUNCTION calculate_fare(
        p_schedule_id IN NUMBER,
        p_seats IN NUMBER
    ) RETURN NUMBER IS
        v_fare_amount NUMBER;
    BEGIN
        SELECT fare_amount INTO v_fare_amount
        FROM schedule WHERE schedule_id = p_schedule_id;

        RETURN v_fare_amount * p_seats;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END calculate_fare;

    -- 5. SHOW CLIENT BOOKINGS
    PROCEDURE show_my_bookings(
        p_client_id IN NUMBER
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('📋 YOUR BOOKINGS');
        DBMS_OUTPUT.PUT_LINE('================');

        FOR rec IN (
            SELECT r.reservation_id, r.reservation_date,
                   r.seats_count, r.total_amount, r.status,
                   s.departure_date, s.departure_time,
                   rt.departure_location, rt.destination
            FROM reservation r
            JOIN schedule s ON r.schedule_id = s.schedule_id
            JOIN route rt ON s.route_id = rt.route_id
            WHERE r.client_id = p_client_id
            ORDER BY r.reservation_date DESC
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Booking #' || rec.reservation_id);
            DBMS_OUTPUT.PUT_LINE('  From: ' || rec.departure_location);
            DBMS_OUTPUT.PUT_LINE('  To: ' || rec.destination);
            DBMS_OUTPUT.PUT_LINE('  Date: ' || TO_CHAR(rec.departure_date, 'DD-MON'));
            DBMS_OUTPUT.PUT_LINE('  Time: ' || rec.departure_time);
            DBMS_OUTPUT.PUT_LINE('  Seats: ' || rec.seats_count);
            DBMS_OUTPUT.PUT_LINE('  Amount: $' || rec.total_amount);
            DBMS_OUTPUT.PUT_LINE('  Status: ' || rec.status);
            DBMS_OUTPUT.PUT_LINE('---');
        END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No bookings found');
    END show_my_bookings;

END booking_pkg;
