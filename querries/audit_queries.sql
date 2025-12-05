-- ============================================
-- AUDIT QUERIES
-- Security, Compliance, and Monitoring
-- ============================================

-- 1. AUDIT LOG OVERVIEW
-- ---------------------
-- Complete audit trail
SELECT al.log_id,
       e.employee_code,
       e.department,
       al.action_type,
       al.table_name,
       al.status,
       TO_CHAR(al.action_date, 'DD-MON-YYYY HH24:MI:SS') as action_timestamp,
       CASE 
           WHEN al.status = 'DENIED' THEN 'SECURITY VIOLATION'
           ELSE 'NORMAL OPERATION'
       END as security_level
FROM audit_log al
JOIN employee e ON al.employee_id = e.employee_id
ORDER BY al.action_date DESC;

-- 2. SECURITY VIOLATIONS
-- ----------------------
-- All denied operations (potential security breaches)
SELECT al.log_id,
       e.employee_code,
       e.department,
       al.action_type,
       al.table_name,
       TO_CHAR(al.action_date, 'DD-MON-YYYY HH24:MI:SS') as violation_time,
       TO_CHAR(al.action_date, 'DY') as day_of_week,
       CASE 
           WHEN TO_CHAR(al.action_date, 'DY') IN ('SAT', 'SUN') THEN 'WEEKEND'
           ELSE 'WEEKDAY'
       END as day_type
FROM audit_log al
JOIN employee e ON al.employee_id = e.employee_id
WHERE al.status = 'DENIED'
ORDER BY al.action_date DESC;

-- Security violations by employee
SELECT e.employee_code,
       e.department,
       COUNT(*) as total_violations,
       MIN(al.action_date) as first_violation,
       MAX(al.action_date) as last_violation,
       COUNT(DISTINCT al.table_name) as tables_affected,
       LISTAGG(DISTINCT al.action_type, ', ') WITHIN GROUP (ORDER BY al.action_type) as action_types
FROM audit_log al
JOIN employee e ON al.employee_id = e.employee_id
WHERE al.status = 'DENIED'
GROUP BY e.employee_code, e.department
ORDER BY total_violations DESC;

-- 3. COMPLIANCE MONITORING
-- ------------------------
-- Weekday restriction compliance (Phase VII)
SELECT 
    TO_CHAR(action_date, 'YYYY-MM-DD') as date,
    TO_CHAR(action_date, 'DY') as day,
    COUNT(CASE WHEN status = 'DENIED' THEN 1 END) as restricted_operations,
    COUNT(CASE WHEN status = 'ALLOWED' THEN 1 END) as allowed_operations,
    ROUND(COUNT(CASE WHEN status = 'DENIED' THEN 1 END) * 100.0 / COUNT(*), 2) as restriction_rate
FROM audit_log
WHERE action_type IN ('INSERT', 'UPDATE', 'DELETE')
  AND table_name = 'SCHEDULE'
GROUP BY TO_CHAR(action_date, 'YYYY-MM-DD'), TO_CHAR(action_date, 'DY')
ORDER BY date DESC;

-- Holiday restriction compliance
SELECT h.holiday_name,
       TO_CHAR(h.holiday_date, 'DD-MON-YYYY') as holiday_date,
       COUNT(al.log_id) as attempted_operations,
       COUNT(CASE WHEN al.status = 'DENIED' THEN 1 END) as denied_operations,
       COUNT(CASE WHEN al.status = 'ALLOWED' THEN 1 END) as allowed_operations
FROM holiday h
LEFT JOIN audit_log al ON TRUNC(al.action_date) = h.holiday_date
WHERE al.action_type IN ('INSERT', 'UPDATE', 'DELETE')
  AND al.table_name = 'SCHEDULE'
GROUP BY h.holiday_name, h.holiday_date
ORDER BY h.holiday_date DESC;

-- 4. EMPLOYEE ACTIVITY MONITORING
-- -------------------------------
-- Employee activity summary
SELECT e.employee_code,
       e.department,
       COUNT(al.log_id) as total_actions,
       COUNT(CASE WHEN al.status = 'ALLOWED' THEN 1 END) as successful_actions,
       COUNT(CASE WHEN al.status = 'DENIED' THEN 1 END) as denied_actions,
       COUNT(DISTINCT al.table_name) as tables_accessed,
       MIN(al.action_date) as first_action,
       MAX(al.action_date) as last_action,
       ROUND(COUNT(CASE WHEN al.status = 'DENIED' THEN 1 END) * 100.0 / COUNT(*), 2) as denial_rate
FROM employee e
LEFT JOIN audit_log al ON e.employee_id = al.employee_id
GROUP BY e.employee_code, e.department
ORDER BY total_actions DESC;

-- Employee activity by time of day
SELECT e.employee_code,
       EXTRACT(HOUR FROM al.action_date) as hour_of_day,
       COUNT(*) as action_count,
       COUNT(CASE WHEN al.status = 'DENIED' THEN 1 END) as denied_count
FROM audit_log al
JOIN employee e ON al.employee_id = e.employee_id
GROUP BY e.employee_code, EXTRACT(HOUR FROM al.action_date)
ORDER BY e.employee_code, hour_of_day;

-- 5. TABLE ACCESS PATTERNS
-- ------------------------
-- Table access frequency
SELECT table_name,
       action_type,
       COUNT(*) as total_operations,
       COUNT(CASE WHEN status = 'DENIED' THEN 1 END) as denied_operations,
       COUNT(CASE WHEN status = 'ALLOWED' THEN 1 END) as allowed_operations,
       MIN(action_date) as first_access,
       MAX(action_date) as last_access
FROM audit_log
GROUP BY table_name, action_type
ORDER BY total_operations DESC;

-- Most frequently modified tables
SELECT table_name,
       COUNT(*) as modification_count,
       COUNT(DISTINCT employee_id) as unique_modifiers,
       ROUND(COUNT(*) / COUNT(DISTINCT employee_id), 2) as avg_modifications_per_user
FROM audit_log
WHERE action_type IN ('INSERT', 'UPDATE', 'DELETE')
GROUP BY table_name
ORDER BY modification_count DESC;

-- 6. ANOMALY DETECTION
-- --------------------
-- Unusual activity patterns (multiple rapid operations)
SELECT al.employee_id,
       e.employee_code,
       COUNT(*) as operations_in_period,
       MIN(al.action_date) as period_start,
       MAX(al.action_date) as period_end,
       ROUND((MAX(al.action_date) - MIN(al.action_date)) * 24 * 60, 2) as duration_minutes,
       ROUND(COUNT(*) / ((MAX(al.action_date) - MIN(al.action_date)) * 24 * 60), 2) as operations_per_minute
FROM audit_log al
JOIN employee e ON al.employee_id = e.employee_id
WHERE al.action_date >= SYSDATE - 1/24  -- Last hour
GROUP BY al.employee_id, e.employee_code
HAVING COUNT(*) > 10  -- More than 10 operations in the period
ORDER BY operations_per_minute DESC;

-- After-hours activity
SELECT e.employee_code,
       e.department,
       COUNT(*) as after_hours_actions,
       TO_CHAR(MIN(al.action_date), 'DD-MON-YYYY HH24:MI') as earliest_action,
       TO_CHAR(MAX(al.action_date), 'DD-MON-YYYY HH24:MI') as latest_action
FROM audit_log al
JOIN employee e ON al.employee_id = e.employee_id
WHERE EXTRACT(HOUR FROM al.action_date) NOT BETWEEN 8 AND 18  -- Outside 8 AM to 6 PM
GROUP BY e.employee_code, e.department
HAVING COUNT(*) > 0
ORDER BY after_hours_actions DESC;

-- 7. AUDIT LOG INTEGRITY CHECKS
-- -----------------------------
-- Missing audit entries (potential gaps)
SELECT 
    TO_CHAR(expected_date, 'YYYY-MM-DD') as missing_date,
    COUNT(*) as expected_entries,
    COUNT(al.log_id) as actual_entries,
    CASE 
        WHEN COUNT(al.log_id) = 0 THEN 'NO AUDIT DATA'
        WHEN COUNT(al.log_id) < COUNT(*) * 0.5 THEN 'INCOMPLETE DATA'
        ELSE 'OK'
    END as audit_status
FROM (
    SELECT TRUNC(SYSDATE) - LEVEL + 1 as expected_date
    FROM dual
    CONNECT BY LEVEL <= 30  -- Last 30 days
) dates
LEFT JOIN audit_log al ON TRUNC(al.action_date) = dates.expected_date
GROUP BY TO_CHAR(expected_date, 'YYYY-MM-DD'), expected_date
ORDER BY expected_date DESC;

-- 8. DEPARTMENT-LEVEL COMPLIANCE
-- ------------------------------
-- Department-wise compliance report
SELECT e.department,
       COUNT(*) as total_operations,
       COUNT(CASE WHEN al.status = 'DENIED' THEN 1 END) as denied_operations,
       COUNT(CASE WHEN al.status = 'ALLOWED' THEN 1 END) as allowed_operations,
       COUNT(DISTINCT e.employee_id) as active_employees,
       ROUND(COUNT(CASE WHEN al.status = 'DENIED' THEN 1 END) * 100.0 / COUNT(*), 2) as department_denial_rate,
       LISTAGG(DISTINCT al.table_name, ', ') WITHIN GROUP (ORDER BY al.table_name) as accessed_tables
FROM employee e
LEFT JOIN audit_log al ON e.employee_id = al.employee_id
GROUP BY e.department
ORDER BY total_operations DESC;

-- 9. AUDIT RETENTION ANALYSIS
-- ---------------------------
-- Audit log age analysis
SELECT 
    CASE 
        WHEN action_date >= SYSDATE - 7 THEN 'Last 7 days'
        WHEN action_date >= SYSDATE - 30 THEN '7-30 days'
        WHEN action_date >= SYSDATE - 90 THEN '30-90 days'
        ELSE 'Older than 90 days'
    END as age_category,
    COUNT(*) as entry_count,
    MIN(action_date) as oldest_entry,
    MAX(action_date) as newest_entry,
    COUNT(DISTINCT employee_id) as unique_employees
FROM audit_log
GROUP BY 
    CASE 
        WHEN action_date >= SYSDATE - 7 THEN 'Last 7 days'
        WHEN action_date >= SYSDATE - 30 THEN '7-30 days'
        WHEN action_date >= SYSDATE - 90 THEN '30-90 days'
        ELSE 'Older than 90 days'
    END
ORDER BY 
    CASE 
        WHEN action_date >= SYSDATE - 7 THEN 1
        WHEN action_date >= SYSDATE - 30 THEN 2
        WHEN action_date >= SYSDATE - 90 THEN 3
        ELSE 4
    END;