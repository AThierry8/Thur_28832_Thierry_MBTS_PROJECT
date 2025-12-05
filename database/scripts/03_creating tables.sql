CREATE TABLE clients (
    client_id NUMBER(10) PRIMARY KEY,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone_number VARCHAR2(20) NOT NULL,
    full_name VARCHAR2(100) NOT NULL,
    registration_date DATE DEFAULT SYSDATE
);


-- Table 2: EMPLOYEE
CREATE TABLE employee (
    employee_id NUMBER(10) PRIMARY KEY,
    client_id NUMBER(10) NOT NULL UNIQUE,
    employee_code VARCHAR2(20) UNIQUE NOT NULL,
    department VARCHAR2(20) DEFAULT 'OPERATIONS',
    CONSTRAINT fk_employee_client 
        FOREIGN KEY (client_id) REFERENCES clients(client_id)
);


-- Table 3: HOLIDAY
CREATE TABLE holiday (
    holiday_id NUMBER(10) PRIMARY KEY,
    holiday_date DATE UNIQUE NOT NULL,
    holiday_name VARCHAR2(100) NOT NULL,
    employee_id NUMBER(10),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_holiday_created_by 
        FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);


-- Table 4: BUS
CREATE TABLE bus (
    bus_id NUMBER(10) PRIMARY KEY,
    bus_number VARCHAR2(20) UNIQUE NOT NULL,
    capacity NUMBER(3) NOT NULL CHECK (capacity > 0)
);


-- Table 5: ROUTE
CREATE TABLE route (
    route_id NUMBER(10) PRIMARY KEY,
    departure_location VARCHAR2(50) NOT NULL,
    destination VARCHAR2(50) NOT NULL,
    distance_km NUMBER(6,2) NOT NULL CHECK (distance_km > 0),
    estimated_hours NUMBER(3,1) NOT NULL CHECK (estimated_hours > 0),
    CONSTRAINT unique_route UNIQUE (departure_location, destination)
);


-- Table 6: DRIVER
CREATE TABLE driver (
    driver_id NUMBER(10) PRIMARY KEY,
    driver_name VARCHAR2(100) NOT NULL,
    license_number VARCHAR2(50) UNIQUE NOT NULL
);


-- Table 7: SCHEDULE
CREATE TABLE schedule (
    schedule_id NUMBER(10) PRIMARY KEY,
    route_id NUMBER(10) NOT NULL,
    bus_id NUMBER(10) NOT NULL,
    driver_id NUMBER(10) NOT NULL,
    departure_date DATE NOT NULL,
    departure_time VARCHAR2(5) NOT NULL,
    available_seats NUMBER(3) NOT NULL CHECK (available_seats >= 0),
    fare_amount NUMBER(8,2) NOT NULL CHECK (fare_amount > 0),
    status VARCHAR2(20) DEFAULT 'SCHEDULED',
    CONSTRAINT fk_schedule_route FOREIGN KEY (route_id) REFERENCES route(route_id),
    CONSTRAINT fk_schedule_bus FOREIGN KEY (bus_id) REFERENCES bus(bus_id),
    CONSTRAINT fk_schedule_driver FOREIGN KEY (driver_id) REFERENCES driver(driver_id),
    CONSTRAINT chk_departure_time CHECK (REGEXP_LIKE(departure_time, '^([0-1][0-9]|2[0-3]):[0-5][0-9]$'))
);


-- Table 8: RESERVATION
CREATE TABLE reservation (
    reservation_id NUMBER(10) PRIMARY KEY,
    client_id NUMBER(10) NOT NULL,
    schedule_id NUMBER(10) NOT NULL,
    reservation_date DATE DEFAULT SYSDATE,
    seats_count NUMBER(2) DEFAULT 1 CHECK (seats_count BETWEEN 1 AND 10),
    total_amount NUMBER(10,2) NOT NULL CHECK (total_amount > 0),
    status VARCHAR2(20) DEFAULT 'CONFIRMED',
    CONSTRAINT fk_reservation_client FOREIGN KEY (client_id) REFERENCES clients(client_id),
    CONSTRAINT fk_reservation_schedule FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id)
);


-- Table 9: TICKET
CREATE TABLE ticket (
    ticket_id NUMBER(10) PRIMARY KEY,
    reservation_id NUMBER(10) NOT NULL,
    client_id NUMBER(10) NOT NULL,
    schedule_id NUMBER(10) NOT NULL,
    seat_number VARCHAR2(10) NOT NULL,
    issue_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_ticket_reservation FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id),
    CONSTRAINT fk_ticket_client FOREIGN KEY (client_id) REFERENCES clients(client_id),
    CONSTRAINT fk_ticket_schedule FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id)
);


-- Table 10: PAYMENT
CREATE TABLE payment (
    payment_id NUMBER(10) PRIMARY KEY,
    reservation_id NUMBER(10) UNIQUE NOT NULL,
    payment_method VARCHAR2(20) DEFAULT 'CASH',
    amount NUMBER(10,2) NOT NULL CHECK (amount > 0),
    payment_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) DEFAULT 'COMPLETED',
    CONSTRAINT fk_payment_reservation FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id),
    CONSTRAINT chk_payment_method CHECK (payment_method IN ('CASH', 'CREDIT_CARD', 'MOBILE_MONEY'))
);


-- Table 11: NOTIFICATION
CREATE TABLE notification (
    notification_id NUMBER(10) PRIMARY KEY,
    client_id NUMBER(10) NOT NULL,
    message VARCHAR2(500) NOT NULL,
    sent_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_notification_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
);


-- Table 12: AUDIT_LOG
CREATE TABLE audit_log (
    log_id NUMBER(10) PRIMARY KEY,
    employee_id NUMBER(10) NOT NULL,
    action_type VARCHAR2(20) NOT NULL,
    table_name VARCHAR2(30) NOT NULL,
    action_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) NOT NULL,
    CONSTRAINT fk_audit_employee FOREIGN KEY (employee_id) REFERENCES employee(employee_id),
    CONSTRAINT chk_action_type CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')),
    CONSTRAINT chk_audit_status CHECK (status IN ('ALLOWED', 'DENIED'))
);

