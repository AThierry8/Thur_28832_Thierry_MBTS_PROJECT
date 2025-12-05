-- ============================================
-- DATA RETRIEVAL QUERIES
-- Basic SELECT operations for reporting
-- ============================================

-- 1. CLIENTS MANAGEMENT
-- ---------------------
-- All clients with registration info
SELECT client_id, full_name, email, phone_number, 
       TO_CHAR(registration_date, 'DD-MON-YYYY') as registration_date
FROM clients
ORDER BY registration_date DESC;

-- Clients with their employee status
SELECT c.client_id, c.full_name, c.email, c.phone_number,
       NVL(e.employee_code, 'NOT EMPLOYEE') as employee_status,
       e.department
FROM clients c
LEFT JOIN employee e ON c.client_id = e.client_id
ORDER BY c.full_name;

-- 2. EMPLOYEE QUERIES
-- -------------------
-- All employees with client details
SELECT e.employee_id, e.employee_code, e.department,
       c.full_name, c.email, c.phone_number
FROM employee e
JOIN clients c ON e.client_id = c.client_id
ORDER BY e.department, e.employee_code;

-- Employees by department
SELECT department, COUNT(*) as employee_count,
       LISTAGG(employee_code, ', ') WITHIN GROUP (ORDER BY employee_code) as employees
FROM employee
GROUP BY department
ORDER BY employee_count DESC;

-- 3. BUS FLEET MANAGEMENT
-- -----------------------
-- Bus fleet overview
SELECT bus_id, bus_number, capacity,
       CASE 
           WHEN capacity >= 50 THEN 'LARGE'
           WHEN capacity >= 30 THEN 'MEDIUM'
           ELSE 'SMALL'
       END as bus_size
FROM bus
ORDER BY capacity DESC;

-- 4. ROUTE INFORMATION
-- --------------------
-- All routes with details
SELECT route_id, departure_location, destination, 
       distance_km, estimated_hours,
       ROUND(distance_km / estimated_hours, 2) as avg_speed_kmh
FROM route
ORDER BY departure_location, destination;

-- Popular routes (based on scheduled trips)
SELECT r.route_id, r.departure_location, r.destination,
       COUNT(s.schedule_id) as total_trips,
       AVG(s.fare_amount) as avg_fare
FROM route r
LEFT JOIN schedule s ON r.route_id = s.route_id
GROUP BY r.route_id, r.departure_location, r.destination
ORDER BY total_trips DESC;

-- 5. SCHEDULE QUERIES
-- -------------------
-- Upcoming schedules
SELECT s.schedule_id, 
       r.departure_location || ' to ' || r.destination as route,
       b.bus_number,
       d.driver_name,
       TO_CHAR(s.departure_date, 'DD-MON-YYYY') || ' ' || s.departure_time as departure,
       s.available_seats,
       s.fare_amount,
       s.status
FROM schedule s
JOIN route r ON s.route_id = r.route_id
JOIN bus b ON s.bus_id = b.bus_id
JOIN driver d ON s.driver_id = d.driver_id
WHERE s.departure_date >= TRUNC(SYSDATE)
ORDER BY s.departure_date, s.departure_time;

-- Schedules with low seat availability
SELECT s.schedule_id, 
       r.departure_location || ' to ' || r.destination as route,
       TO_CHAR(s.departure_date, 'DD-MON-YYYY') || ' ' || s.departure_time as departure,
       s.available_seats,
       b.capacity,
       ROUND((s.available_seats / b.capacity) * 100, 1) as seat_percentage
FROM schedule s
JOIN route r ON s.route_id = r.route_id
JOIN bus b ON s.bus_id = b.bus_id
WHERE s.available_seats < (b.capacity * 0.3)  -- Less than 30% seats available
AND s.departure_date >= TRUNC(SYSDATE)
ORDER BY seat_percentage;

-- 6. RESERVATION QUERIES
-- ----------------------
-- All reservations with client and schedule details
SELECT res.reservation_id,
       c.full_name as client_name,
       r.departure_location || ' to ' || r.destination as route,
       TO_CHAR(s.departure_date, 'DD-MON-YYYY') || ' ' || s.departure_time as departure,
       res.seats_count,
       res.total_amount,
       res.status,
       TO_CHAR(res.reservation_date, 'DD-MON-YYYY HH24:MI') as reservation_time
FROM reservation res
JOIN clients c ON res.client_id = c.client_id
JOIN schedule s ON res.schedule_id = s.schedule_id
JOIN route r ON s.route_id = r.route_id
ORDER BY res.reservation_date DESC;

-- Reservations by month
SELECT TO_CHAR(reservation_date, 'YYYY-MM') as month,
       COUNT(*) as total_reservations,
       SUM(seats_count) as total_seats,
       SUM(total_amount) as total_revenue
FROM reservation
GROUP BY TO_CHAR(reservation_date, 'YYYY-MM')
ORDER BY month DESC;

-- 7. TICKET QUERIES
-- -----------------
-- All tickets issued
SELECT t.ticket_id,
       c.full_name as passenger,
       r.departure_location || ' to ' || r.destination as route,
       TO_CHAR(s.departure_date, 'DD-MON-YYYY') || ' ' || s.departure_time as departure,
       t.seat_number,
       TO_CHAR(t.issue_date, 'DD-MON-YYYY HH24:MI') as issued_on
FROM ticket t
JOIN clients c ON t.client_id = c.client_id
JOIN schedule s ON t.schedule_id = s.schedule_id
JOIN route r ON s.route_id = r.route_id
ORDER BY t.issue_date DESC;

-- 8. PAYMENT QUERIES
-- ------------------
-- Payment transactions
SELECT p.payment_id,
       c.full_name as client,
       p.payment_method,
       p.amount,
       p.status,
       TO_CHAR(p.payment_date, 'DD-MON-YYYY HH24:MI') as payment_time,
       r.departure_location || ' to ' || r.destination as route
FROM payment p
JOIN reservation res ON p.reservation_id = res.reservation_id
JOIN clients c ON res.client_id = c.client_id
JOIN schedule s ON res.schedule_id = s.schedule_id
JOIN route r ON s.route_id = r.route_id
ORDER BY p.payment_date DESC;

-- Payments by method
SELECT payment_method,
       COUNT(*) as transaction_count,
       SUM(amount) as total_amount,
       ROUND(AVG(amount), 2) as avg_amount
FROM payment
WHERE status = 'COMPLETED'
GROUP BY payment_method
ORDER BY total_amount DESC;

-- 9. HOLIDAY MANAGEMENT
-- ---------------------
-- Upcoming holidays
SELECT holiday_id, holiday_name,
       TO_CHAR(holiday_date, 'DD-MON-YYYY (DY)') as holiday_date,
       e.employee_code as created_by,
       TO_CHAR(created_date, 'DD-MON-YYYY') as created_on
FROM holiday h
LEFT JOIN employee e ON h.employee_id = e.employee_id
WHERE holiday_date >= TRUNC(SYSDATE)
ORDER BY holiday_date;

-- 10. NOTIFICATION QUERIES
-- -----------------------
-- Recent notifications
SELECT notification_id,
       c.full_name as client,
       message,
       TO_CHAR(sent_date, 'DD-MON-YYYY HH24:MI') as sent_time
FROM notification n
JOIN clients c ON n.client_id = c.client_id
ORDER BY sent_date DESC
FETCH FIRST 50 ROWS ONLY;

-- 11. DRIVER INFORMATION
-- ----------------------
-- All drivers with assigned schedules
SELECT d.driver_id, d.driver_name, d.license_number,
       COUNT(s.schedule_id) as total_schedules,
       MIN(s.departure_date) as first_schedule,
       MAX(s.departure_date) as last_schedule
FROM driver d
LEFT JOIN schedule s ON d.driver_id = s.driver_id
GROUP BY d.driver_id, d.driver_name, d.license_number
ORDER BY d.driver_name;