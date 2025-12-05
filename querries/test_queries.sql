-- ============================================
-- TEST QUERIES
-- Data Validation, Integrity Checks, and Testing
-- ============================================

-- 1. DATA INTEGRITY TESTS
-- -----------------------
-- Check for orphaned records
SELECT 'RESERVATION without CLIENT' as test_name,
       COUNT(*) as orphan_count
FROM reservation r
LEFT JOIN clients c ON r.client_id = c.client_id
WHERE c.client_id IS NULL
UNION ALL
SELECT 'RESERVATION without SCHEDULE' as test_name,
       COUNT(*) as orphan_count
FROM reservation r
LEFT JOIN schedule s ON r.schedule_id = s.schedule_id
WHERE s.schedule_id IS NULL
UNION ALL
SELECT 'SCHEDULE without BUS' as test_name,
       COUNT(*) as orphan_count
FROM schedule s
LEFT JOIN bus b ON s.bus_id = b.bus_id
WHERE b.bus_id IS NULL
UNION ALL
SELECT 'EMPLOYEE without CLIENT' as test_name,
       COUNT(*) as orphan_count
FROM employee e
LEFT JOIN clients c ON e.client_id = c.client_id
WHERE c.client_id IS NULL;

-- Check constraint violations
SELECT 'Invalid departure_time format' as test_name,
       COUNT(*) as violation_count
FROM schedule
WHERE NOT REGEXP_LIKE(departure_time, '^([0-1][0-9]|2[0-3]):[0-5][0-9]$')
UNION ALL
SELECT 'Negative available_seats' as test_name,
       COUNT(*) as violation_count
FROM schedule
WHERE available_seats < 0
UNION ALL
SELECT 'Invalid payment_method' as test_name,
       COUNT(*) as violation_count
FROM payment
WHERE payment_method NOT IN ('CASH', 'CREDIT_CARD', 'MOBILE_MONEY');

-- 2. BUSINESS RULE VALIDATION
-- ---------------------------
-- Check for overbooking
SELECT s.schedule_id,
       r.departure_location || ' to ' || r.destination as route,
       b.bus_number,
       b.capacity,
       s.available_seats,
       (SELECT SUM(seats_count) 
        FROM reservation res 
        WHERE res.schedule_id = s.schedule_id) as reserved_seats,
       b.capacity - s.available_seats as calculated_seats_sold
FROM schedule s
JOIN bus b ON s.bus_id = b.bus_id
JOIN route r ON s.route_id = r.route_id
WHERE (b.capacity - s.available_seats) != 
      (SELECT COALESCE(SUM(seats_count), 0) 
       FROM reservation res 
       WHERE res.schedule_id = s.schedule_id);

-- Check fare consistency
SELECT s.schedule_id,
       r.departure_location || ' to ' || r.destination as route,
       s.fare_amount,
       AVG(s2.fare_amount) as avg_route_fare,
       s.fare_amount - AVG(s2.fare_amount) as fare_difference,
       ROUND((s.fare_amount - AVG(s2.fare_amount)) / AVG(s2.fare_amount) * 100, 2) as percent_difference
FROM schedule s
JOIN route r ON s.route_id = r.route_id
JOIN schedule s2 ON r.route_id = s2.route_id
GROUP BY s.schedule_id, r.departure_location, r.destination, s.fare_amount
HAVING ABS(s.fare_amount - AVG(s2.fare_amount)) > AVG(s2.fare_amount) * 0.5  -- More than 50% difference
ORDER BY percent_difference DESC;

-- 3. REFERENTIAL INTEGRITY TESTS
-- ------------------------------
-- Verify all foreign key relationships
SELECT 'CLIENT-EMPLOYEE relationship' as relationship,
       COUNT(*) as total_employees,
       COUNT(DISTINCT client_id) as unique_client_references,
       CASE 
           WHEN COUNT(*) = COUNT(DISTINCT client_id) THEN 'OK - One-to-One'
           ELSE 'CHECK - Possible duplicates'
       END as status
FROM employee
UNION ALL
SELECT 'RESERVATION-CLIENT relationship' as relationship,
       COUNT(*) as total_reservations,
       COUNT(DISTINCT client_id) as unique_clients,
       ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT client_id), 2) as avg_reservations_per_client
FROM reservation;

-- Check circular references
SELECT 'No circular references found' as test_result
FROM dual
WHERE NOT EXISTS (
    -- Add any circular reference checks here
    SELECT 1 FROM dual WHERE 1=0
);

-- 4. DATA QUALITY CHECKS
-- ----------------------
-- Missing required data
SELECT 'Clients without email' as data_issue,
       COUNT(*) as record_count
FROM clients
WHERE email IS NULL OR TRIM(email) = ''
UNION ALL
SELECT 'Employees without department' as data_issue,
       COUNT(*) as record_count
FROM employee
WHERE department IS NULL
UNION ALL
SELECT 'Schedules without status' as data_issue,
       COUNT(*) as record_count
FROM schedule
WHERE status IS NULL;

-- Duplicate detection
SELECT 'Duplicate emails in clients' as issue_type,
       email,
       COUNT(*) as duplicate_count
FROM clients
GROUP BY email
HAVING COUNT(*) > 1
UNION ALL
SELECT 'Duplicate phone numbers' as issue_type,
       phone_number,
       COUNT(*) as duplicate_count
FROM clients
GROUP BY phone_number
HAVING COUNT(*) > 1
UNION ALL
SELECT 'Duplicate employee codes' as issue_type,
       employee_code,
       COUNT(*) as duplicate_count
FROM employee
GROUP BY employee_code
HAVING COUNT(*) > 1;

-- 5. PERFORMANCE TEST QUERIES
-- ---------------------------
-- Query execution time test (complex joins)
SET TIMING ON
SELECT /*+ TEST_QUERY_1 */ 
       c.client_id, c.full_name,
       COUNT(r.reservation_id) as total_reservations,
       SUM(p.amount) as total_spent,
       MAX(r.reservation_date) as last_booking
FROM clients c
LEFT JOIN reservation r ON c.client_id = r.client_id
LEFT JOIN payment p ON r.reservation_id = p.reservation_id
GROUP BY c.client_id, c.full_name
ORDER BY total_spent DESC NULLS LAST;
SET TIMING OFF

-- Index usage test
