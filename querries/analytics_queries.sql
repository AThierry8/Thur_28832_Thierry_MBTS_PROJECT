-- ============================================
-- ANALYTICS QUERIES
-- Business Intelligence and Performance Metrics
-- ============================================

-- 1. REVENUE ANALYTICS
-- --------------------
-- Daily revenue report
SELECT TRUNC(payment_date) as payment_day,
       COUNT(*) as transactions,
       SUM(amount) as daily_revenue,
       ROUND(AVG(amount), 2) as avg_transaction,
       MIN(amount) as min_transaction,
       MAX(amount) as max_transaction
FROM payment
WHERE status = 'COMPLETED'
GROUP BY TRUNC(payment_date)
ORDER BY payment_day DESC;

-- Revenue by route
SELECT r.route_id, 
       r.departure_location || ' to ' || r.destination as route,
       COUNT(DISTINCT res.reservation_id) as total_bookings,
       SUM(p.amount) as total_revenue,
       ROUND(AVG(p.amount), 2) as avg_booking_value,
       COUNT(DISTINCT res.client_id) as unique_customers
FROM route r
JOIN schedule s ON r.route_id = s.route_id
JOIN reservation res ON s.schedule_id = res.schedule_id
JOIN payment p ON res.reservation_id = p.reservation_id
WHERE p.status = 'COMPLETED'
GROUP BY r.route_id, r.departure_location, r.destination
ORDER BY total_revenue DESC;

-- Monthly revenue trend
SELECT TO_CHAR(payment_date, 'YYYY-MM') as month,
       EXTRACT(YEAR FROM payment_date) as year,
       EXTRACT(MONTH FROM payment_date) as month_num,
       SUM(amount) as monthly_revenue,
       COUNT(*) as transaction_count,
       ROUND(SUM(amount) / COUNT(*), 2) as avg_ticket_value,
       LAG(SUM(amount)) OVER (ORDER BY TO_CHAR(payment_date, 'YYYY-MM')) as prev_month_revenue,
       ROUND(((SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY TO_CHAR(payment_date, 'YYYY-MM'))) / 
              LAG(SUM(amount)) OVER (ORDER BY TO_CHAR(payment_date, 'YYYY-MM'))) * 100, 2) as growth_percentage
FROM payment
WHERE status = 'COMPLETED'
GROUP BY TO_CHAR(payment_date, 'YYYY-MM'), 
         EXTRACT(YEAR FROM payment_date), 
         EXTRACT(MONTH FROM payment_date)
ORDER BY month;

-- 2. OCCUPANCY & UTILIZATION ANALYTICS
-- ------------------------------------
-- Bus utilization rate
SELECT b.bus_id, b.bus_number, b.capacity,
       COUNT(s.schedule_id) as total_trips,
       SUM(s.available_seats) as total_available_seats,
       SUM(b.capacity - s.available_seats) as total_seats_sold,
       ROUND((SUM(b.capacity - s.available_seats) / (COUNT(s.schedule_id) * b.capacity)) * 100, 2) as avg_occupancy_rate
FROM bus b
LEFT JOIN schedule s ON b.bus_id = s.bus_id
WHERE s.departure_date >= ADD_MONTHS(TRUNC(SYSDATE), -3)  -- Last 3 months
GROUP BY b.bus_id, b.bus_number, b.capacity
ORDER BY avg_occupancy_rate DESC;

-- Route occupancy analysis
SELECT r.route_id,
       r.departure_location || ' to ' || r.destination as route,
       COUNT(s.schedule_id) as total_trips,
       AVG(b.capacity - s.available_seats) as avg_seats_sold,
       AVG(s.available_seats) as avg_seats_available,
       ROUND(AVG((b.capacity - s.available_seats) / b.capacity) * 100, 2) as avg_occupancy_percentage
FROM route r
JOIN schedule s ON r.route_id = s.route_id
JOIN bus b ON s.bus_id = b.bus_id
GROUP BY r.route_id, r.departure_location, r.destination
ORDER BY avg_occupancy_percentage DESC;

-- 3. CUSTOMER ANALYTICS
-- ---------------------
-- Customer segmentation by booking frequency
SELECT 
    CASE 
        WHEN booking_count >= 10 THEN 'VIP (10+ bookings)'
        WHEN booking_count >= 5 THEN 'Frequent (5-9 bookings)'
        WHEN booking_count >= 2 THEN 'Regular (2-4 bookings)'
        ELSE 'New (1 booking)'
    END as customer_segment,
    COUNT(*) as customer_count,
    SUM(total_spent) as segment_revenue,
    ROUND(AVG(total_spent), 2) as avg_customer_value,
    ROUND(AVG(booking_count), 2) as avg_bookings_per_customer
FROM (
    SELECT c.client_id, c.full_name, c.email,
           COUNT(res.reservation_id) as booking_count,
           SUM(p.amount) as total_spent
    FROM clients c
    LEFT JOIN reservation res ON c.client_id = res.client_id
    LEFT JOIN payment p ON res.reservation_id = p.reservation_id AND p.status = 'COMPLETED'
    GROUP BY c.client_id, c.full_name, c.email
) customer_stats
GROUP BY 
    CASE 
        WHEN booking_count >= 10 THEN 'VIP (10+ bookings)'
        WHEN booking_count >= 5 THEN 'Frequent (5-9 bookings)'
        WHEN booking_count >= 2 THEN 'Regular (2-4 bookings)'
        ELSE 'New (1 booking)'
    END
ORDER BY segment_revenue DESC;

-- Repeat customer rate
WITH customer_orders AS (
    SELECT client_id,
           COUNT(DISTINCT reservation_id) as order_count
    FROM reservation
    GROUP BY client_id
)
SELECT 
    COUNT(CASE WHEN order_count > 1 THEN 1 END) as repeat_customers,
    COUNT(*) as total_customers,
    ROUND(COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0 / COUNT(*), 2) as repeat_customer_rate
FROM customer_orders;

-- 4. TIME-BASED ANALYTICS
-- -----------------------
-- Peak hours analysis
SELECT EXTRACT(HOUR FROM TO_DATE(departure_time, 'HH24:MI')) as hour_of_day,
       COUNT(*) as total_departures,
       AVG(available_seats) as avg_available_seats,
       AVG(fare_amount) as avg_fare,
       ROUND(AVG(b.capacity - available_seats), 2) as avg_seats_sold
FROM schedule s
JOIN bus b ON s.bus_id = b.bus_id
GROUP BY EXTRACT(HOUR FROM TO_DATE(departure_time, 'HH24:MI'))
ORDER BY hour_of_day;

-- Weekend vs Weekday performance
SELECT 
    CASE 
        WHEN TO_CHAR(departure_date, 'DY') IN ('SAT', 'SUN') THEN 'Weekend'
        ELSE 'Weekday'
    END as day_type,
    COUNT(*) as total_trips,
    AVG(b.capacity - s.available_seats) as avg_seats_sold,
    AVG(s.fare_amount) as avg_fare,
    SUM(b.capacity - s.available_seats) as total_seats_sold
FROM schedule s
JOIN bus b ON s.bus_id = b.bus_id
GROUP BY 
    CASE 
        WHEN TO_CHAR(departure_date, 'DY') IN ('SAT', 'SUN') THEN 'Weekend'
        ELSE 'Weekday'
    END;

-- 5. EMPLOYEE PERFORMANCE ANALYTICS
-- ---------------------------------
-- Employee activity (for those who create holidays)
SELECT e.employee_id, e.employee_code, e.department,
       COUNT(h.holiday_id) as holidays_created,
       MIN(h.created_date) as first_holiday_created,
       MAX(h.created_date) as last_holiday_created
FROM employee e
LEFT JOIN holiday h ON e.employee_id = h.employee_id
GROUP BY e.employee_id, e.employee_code, e.department
ORDER BY holidays_created DESC;

-- 6. PRICE OPTIMIZATION ANALYTICS
-- -------------------------------
-- Fare analysis by route and occupancy
SELECT r.route_id,
       r.departure_location || ' to ' || r.destination as route,
       AVG(s.fare_amount) as avg_fare,
       AVG(b.capacity - s.available_seats) as avg_seats_sold,
       CORR(s.fare_amount, (b.capacity - s.available_seats)) as price_demand_correlation,
       COUNT(*) as trip_count
FROM route r
JOIN schedule s ON r.route_id = s.route_id
JOIN bus b ON s.bus_id = b.bus_id
GROUP BY r.route_id, r.departure_location, r.destination
HAVING COUNT(*) >= 5  -- Only routes with sufficient data
ORDER BY price_demand_correlation DESC;

-- 7. CANCELLATION ANALYSIS
-- ------------------------
-- Reservation cancellation rate
SELECT 
    TO_CHAR(reservation_date, 'YYYY-MM') as month,
    COUNT(*) as total_reservations,
    COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled_reservations,
    ROUND(COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) * 100.0 / COUNT(*), 2) as cancellation_rate,
    SUM(CASE WHEN status = 'CANCELLED' THEN total_amount ELSE 0 END) as lost_revenue
FROM reservation
GROUP BY TO_CHAR(reservation_date, 'YYYY-MM')
ORDER BY month DESC;

-- 8. SEASONAL TRENDS
-- ------------------
-- Monthly performance trends
SELECT 
    EXTRACT(MONTH FROM s.departure_date) as month_number,
    TO_CHAR(s.departure_date, 'MONTH') as month_name,
    COUNT(DISTINCT s.schedule_id) as total_trips,
    SUM(b.capacity - s.available_seats) as total_seats_sold,
    ROUND(AVG(b.capacity - s.available_seats), 2) as avg_seats_per_trip,
    SUM(p.amount) as total_revenue
FROM schedule s
JOIN bus b ON s.bus_id = b.bus_id
LEFT JOIN reservation res ON s.schedule_id = res.schedule_id
LEFT JOIN payment p ON res.reservation_id = p.reservation_id AND p.status = 'COMPLETED'
WHERE EXTRACT(YEAR FROM s.departure_date) = EXTRACT(YEAR FROM SYSDATE)
GROUP BY EXTRACT(MONTH FROM s.departure_date), TO_CHAR(s.departure_date, 'MONTH')
ORDER BY month_number;