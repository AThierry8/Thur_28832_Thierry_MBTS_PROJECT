create or replace PACKAGE booking_pkg IS
    -- Simple booking procedure
    PROCEDURE book_ticket(
        p_client_id IN NUMBER,
        p_schedule_id IN NUMBER,
        p_seats IN NUMBER
    );

    -- Simple cancellation procedure
    PROCEDURE cancel_ticket(
        p_reservation_id IN NUMBER
    );

    -- Check seat availability
    FUNCTION check_available_seats(
        p_schedule_id IN NUMBER
    ) RETURN VARCHAR2;

    -- Calculate fare
    FUNCTION calculate_fare(
        p_schedule_id IN NUMBER,
        p_seats IN NUMBER
    ) RETURN NUMBER;

    -- Show client bookings
    PROCEDURE show_my_bookings(
        p_client_id IN NUMBER
    );
END booking_pkg;




-- 


create or replace PACKAGE admin_pkg IS
    -- Add new bus
    PROCEDURE add_bus(
        p_bus_number IN VARCHAR2,
        p_capacity IN NUMBER
    );

    -- Add new route
    PROCEDURE add_route(
        p_from IN VARCHAR2,
        p_to IN VARCHAR2,
        p_distance IN NUMBER,
        p_hours IN NUMBER
    );

    -- Add new schedule
    PROCEDURE add_schedule(
        p_route_id IN NUMBER,
        p_bus_id IN NUMBER,
        p_departure_date IN DATE,
        p_departure_time IN VARCHAR2,
        p_fare IN NUMBER
    );

    -- Daily report
    PROCEDURE show_daily_report(
        p_date IN DATE DEFAULT SYSDATE
    );

    -- Revenue report
    FUNCTION get_daily_revenue(
        p_date IN DATE DEFAULT SYSDATE
    ) RETURN NUMBER;

    -- Busiest route
    FUNCTION get_busiest_route RETURN VARCHAR2;
END admin_pkg;

