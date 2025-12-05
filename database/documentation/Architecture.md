# Database Architecture - Mobile Bus Ticketing System (MBTS)

## System Overview
The Mobile Bus Ticketing System (MBTS) provides a modern, efficient, and secure solution for bus ticket purchasing, replacing traditional manual systems. The database serves as the backbone for ticket reservations, scheduling, payment processing, and business intelligence reporting.

## Database Design
- **DBMS:** Oracle Database 23ai
- **PDB Name:** `thur_28832_thierry_mbts_db`
- **Character Set:** AL32UTF8
- **National Character Set:** AL16UTF16
- **Database Mode:** PDB (Pluggable Database)

## Tablespace Configuration
- **USERS:** Default tablespace for application data
- **INDEX_TS:** Dedicated tablespace for indexes
- **TEMP_TS:** Temporary tablespace for sort operations
- **UNDO_TS:** Undo tablespace for transaction management

## Memory Configuration
- **SGA Size:** 2GB (Recommended for development)
- **PGA Size:** 1GB
- **Shared Pool:** 512MB
- **Buffer Cache:** 1GB
- **Processes:** 150 concurrent connections

## Security Architecture
### User Roles:
- **MBTS_ADMIN:** Full DBA privileges (schema owner)
- **MBTS_USER:** Application user with execute privileges on packages
- **MBTS_READER:** Read-only access for reporting

### Authentication:
- Password-based authentication
- Profile limits for resource management
- Failed login attempt tracking

## Schema Structure
### Core Transactional Tables (12 tables):
1. **CLIENTS** - Passenger registration
2. **EMPLOYEE** - System operators and admins
3. **HOLIDAY** - Holiday management for restriction rules
4. **BUS** - Bus fleet inventory
5. **ROUTE** - Travel routes with distances
6. **DRIVER** - Driver information
7. **SCHEDULE** - Trip scheduling with fare calculation
8. **RESERVATION** - Ticket bookings
9. **TICKET** - Issued tickets
10. **PAYMENT** - Payment transactions
11. **NOTIFICATION** - Customer communications
12. **AUDIT_LOG** - Security and compliance tracking

## PL/SQL Architecture
### Packages:
- **ADMIN_PKG:** Administrative functions (route/schedule management, reporting)
- **BOOKING_PKG:** Customer-facing booking operations

### Procedures (7):
- `ADD_NEW_BUS`
- `BOOK_TICKET`
- `CANCEL_BOOKING`
- `GENERATE_DAILY_REPORT`
- `LOG_AUDIT`

### Functions (10+):
- `CALCULATE_TOTAL_REVENUE`
- `CHECK_RESTRICTION`
- `CLIENT_EXISTS`
- `GET_BUS_INFO`
- `GET_CLIENT_EMAIL`
- `HAS_AVAILABLE_SEATS`
- `IS_VALID_EMAIL`
- `CALCULATE_FARE` (in BOOKING_PKG)

### Triggers (4):
- `TRG_RESTRICT_EMPLOYEES_PAY` - Payment table restrictions
- `TRG_RESTRICT_EMPLOYEES_RES` - Reservation table restrictions
- `TRG_RESTRICT_EMPLOYEES_SCHED` - Schedule table restrictions
- `TRG_RESTRICT_EMPLOYEES_TIC` - Ticket table restrictions

## Backup & Recovery Strategy
- **Archive Logging:** Enabled
- **Backup Frequency:** Daily incremental, weekly full
- **Retention Policy:** 30 days for archive logs
- **Recovery Point Objective (RPO):** 24 hours
- **Recovery Time Objective (RTO):** 4 hours

## Performance Optimization
### Indexing Strategy:
- Primary key indexes on all tables
- Foreign key indexes for join optimization
- Composite indexes on frequently queried columns:
  - `SCHEDULE(departure_date, route_id)`
  - `RESERVATION(reservation_date, client_id)`

### Partitioning Considerations:
- `SCHEDULE` table partitioned by `departure_date` (range partitioning)
- `RESERVATION` table partitioned by `reservation_date`

## Business Intelligence Layer
### Analytical Components:
- Daily revenue reporting via `GET_DAILY_REVENUE`
- Busiest route identification via `GET_BUSIEST_ROUTE`
- Real-time seat availability checking
- Audit compliance reporting

### Key Performance Indicators (KPIs):
- Daily ticket sales
- Route utilization rates
- Revenue by payment method
- Customer booking patterns

## Monitoring & Maintenance
- **Oracle Enterprise Manager (OEM):** Performance monitoring
- **Alert Log:** System error tracking
- **AWR Reports:** Performance analysis
- **Space Management:** Automated tablespace alerts

## Connectivity
- **Listener Port:** 1521
- **Service Name:** `thur_28832_thierry_mbts_db`
- **Protocol:** TCP/IP
- **Max Connections:** 100 concurrent users

---
*Architecture designed for ACID compliance, high availability, and scalable performance.*
