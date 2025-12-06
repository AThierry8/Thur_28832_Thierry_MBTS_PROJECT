-- Shows how full each scheduled trip is compared to others on the same route
SELECT 
    s.schedule_id,
    r.departure_location,
    r.destination,
    s.departure_date,
    s.available_seats,
    b.capacity,
    ROUND((b.capacity - s.available_seats) * 100.0 / b.capacity, 2) AS occupancy_rate,
    RANK() OVER (
        PARTITION BY s.route_id 
        ORDER BY (b.capacity - s.available_seats) DESC
    ) AS popularity_rank
FROM schedule s
JOIN bus b ON s.bus_id = b.bus_id
JOIN route r ON s.route_id = r.route_id
WHERE s.departure_date >= SYSDATE
ORDER BY s.route_id, popularity_rank;


-- Analyzes client booking patterns and ranks them by activity
SELECT 
    c.client_id,
    c.full_name,
    c.registration_date,
    COUNT(r.reservation_id) AS total_reservations,
    SUM(r.seats_count) AS total_seats_booked,
    SUM(r.total_amount) AS total_spent,
    AVG(COUNT(r.reservation_id)) OVER () AS avg_reservations_per_client,
    NTILE(4) OVER (ORDER BY COUNT(r.reservation_id) DESC) AS client_tier,
    LAG(COUNT(r.reservation_id), 1, 0) OVER (
        PARTITION BY c.client_id 
        ORDER BY MIN(r.reservation_date)
    ) AS previous_period_reservations
FROM clients c
LEFT JOIN reservation r ON c.client_id = r.client_id
GROUP BY c.client_id, c.full_name, c.registration_date
ORDER BY total_reservations DESC;



-- Compares revenue performance across routes over time

SELECT 
    r.route_id,
    r.departure_location || ' to ' || r.destination AS route_name,
    TRUNC(s.departure_date, 'MM') AS month,
    SUM(p.amount) AS monthly_revenue,
    SUM(SUM(p.amount)) OVER (
        PARTITION BY r.route_id 
        ORDER BY TRUNC(s.departure_date, 'MM')
    ) AS running_total_revenue,
    ROUND(
        SUM(p.amount) * 100.0 / SUM(SUM(p.amount)) OVER (
            PARTITION BY TRUNC(s.departure_date, 'MM')
        ), 2
    ) AS monthly_revenue_percentage,
    ROW_NUMBER() OVER (
        PARTITION BY TRUNC(s.departure_date, 'MM') 
        ORDER BY SUM(p.amount) DESC
    ) AS monthly_rank
FROM payment p
JOIN reservation res ON p.reservation_id = res.reservation_id
JOIN schedule s ON res.schedule_id = s.schedule_id
JOIN route r ON s.route_id = r.route_id
GROUP BY r.route_id, r.departure_location, r.destination, TRUNC(s.departure_date, 'MM')
ORDER BY month, monthly_rank;

-- Evaluates driver performance and schedule distribution
SELECT 
    d.driver_id,
    d.driver_name,
    TRUNC(s.departure_date) AS schedule_date,
    COUNT(s.schedule_id) AS trips_scheduled,
    SUM(b.capacity - s.available_seats) AS total_passengers,
    AVG(b.capacity - s.available_seats) OVER (
        PARTITION BY d.driver_id
    ) AS avg_passengers_per_trip,
    ROUND(
        COUNT(s.schedule_id) * 100.0 / SUM(COUNT(s.schedule_id)) OVER (
            PARTITION BY TRUNC(s.departure_date)
        ), 2
    ) AS daily_workload_percentage,
    FIRST_VALUE(r.departure_location || ' to ' || r.destination) OVER (
        PARTITION BY d.driver_id 
        ORDER BY s.departure_date DESC
    ) AS most_recent_route,
    LEAD(s.departure_date) OVER (
        PARTITION BY d.driver_id 
        ORDER BY s.departure_date
    ) AS next_scheduled_date
FROM driver d
JOIN schedule s ON d.driver_id = s.driver_id
JOIN bus b ON s.bus_id = b.bus_id
JOIN route r ON s.route_id = r.route_id
WHERE s.departure_date BETWEEN SYSDATE - 30 AND SYSDATE + 30
GROUP BY d.driver_id, d.driver_name, TRUNC(s.departure_date), s.schedule_id, 
         s.available_seats, b.capacity, s.departure_date, r.departure_location, r.destination
ORDER BY d.driver_id, schedule_date;