# Design Decisions - Mobile Bus Ticketing System

## 1. Database Normalization Level (3NF+)
**Decision:** Implemented Third Normal Form with selective denormalization for performance.

**Reason:**
- All tables satisfy 3NF, eliminating transitive dependencies
- `SCHEDULE` table includes calculated `fare_amount` (controlled denormalization) to avoid joins during frequent queries
- Maintains data integrity while optimizing read performance for booking operations

## 2. Entity Relationship Design
**Decision:** Created 12 interrelated tables with clear business domain separation.

**Key Relationships:**
- **CLIENTS → EMPLOYEE:** 1:1 relationship (an employee is also a client)
- **CLIENTS → RESERVATION:** 1:M (a client can have multiple bookings)
- **SCHEDULE → RESERVATION:** 1:M (a schedule can have multiple reservations)
- **RESERVATION → TICKET:** 1:M (a reservation can have multiple tickets for group bookings)

**Reason:** Mirrors real-world business processes while maintaining referential integrity.

## 3. Business Rule Implementation (Critical Requirement)
**Decision:** Implemented comprehensive restriction system preventing employee DML during weekdays and holidays.

**Implementation:**
- 4 specialized triggers (`TRG_RESTRICT_EMPLOYEES_*`) for PAYMENT, RESERVATION, SCHEDULE, and TICKET tables
- `HOLIDAY` table with `employee_id` tracking who created holiday entries
- `CHECK_RESTRICTION` function validating against both weekday and holiday constraints
- Complete audit trail in `AUDIT_LOG` table

**Reason:** Meets Phase VII requirements while providing real-world security controls.

## 4. PL/SQL Architecture
**Decision:** Structured code into two main packages with clear separation of concerns.

**Package Design:**
- **ADMIN_PKG:** Administrative operations (route management, reporting, revenue tracking)
- **BOOKING_PKG:** Customer-facing operations (booking, cancellation, fare calculation)

**Reason:**
- Encapsulation of related functionality
- Improved performance through package state persistence
- Easier maintenance and version control
- Clear security boundary (different execute privileges)

## 5. Data Type Selection
**Decision:** Optimized data types for storage and validation.

**Examples:**
- IDs: `NUMBER(10)` - Sufficient for 10-digit identifiers
- Names: `VARCHAR2(100)` - Accommodates international names
- Time: `VARCHAR2(5)` with regex constraint (`HH:MM` format)
- Monetary: `NUMBER(10,2)` - Precision for financial calculations
- Status fields: `VARCHAR2(20)` with check constraints

**Reason:** Balances storage efficiency with business requirements and validation.

## 6. Constraint Strategy
**Decision:** Implemented multi-layer constraints.

**Types Used:**
- **Primary Keys:** All tables
- **Foreign Keys:** All relationships (ON DELETE NO ACTION)
- **Unique Constraints:** Business keys (email, bus_number, route uniqueness)
- **Check Constraints:** 
  - `departure_time` format validation
  - `payment_method` domain restriction
  - `seats_count` range validation (1-10)
  - Positive values for amounts and distances

**Reason:** Enforces data integrity at database level, preventing application-layer errors.

## 7. Audit & Security Design
**Decision:** Comprehensive audit system with `AUDIT_LOG` table.

**Features:**
- Tracks all restricted DML attempts (allowed/denied)
- Records employee ID, action type, table name, and timestamp
- Status categorization for easy reporting
- Foreign key to EMPLOYEE table for accountability

**Reason:** Meets compliance requirements and provides troubleshooting capability.

## 8. Indexing Strategy
**Decision:** Strategic indexing beyond primary keys.

**Indexes Created:**
- Foreign key columns for join performance
- `SCHEDULE(departure_date)` for date-range queries
- `CLIENTS(email)` for quick login validation
- Composite indexes on frequently filtered columns

**Reason:** Optimizes query performance while minimizing insert/update overhead.

## 9. Business Intelligence Considerations
**Decision:** Built-in analytics in PL/SQL packages.

**Analytical Functions:**
- `GET_DAILY_REVENUE` - Aggregates payment data
- `GET_BUSIEST_ROUTE` - Identifies popular routes
- `SHOW_DAILY_REPORT` - Comprehensive daily summary
- Window functions for ranking and trend analysis

**Reason:** Provides immediate business value without external reporting tools.

## 10. Error Handling & Validation
**Decision:** Robust exception handling throughout.

**Approach:**
- Custom exceptions for business rule violations
- `LOG_AUDIT` procedure for security event tracking
- Input validation functions (`IS_VALID_EMAIL`, `CLIENT_EXISTS`)
- Graceful error messages with actionable information

**Reason:** Improves user experience and system reliability.

## 11. Scalability Considerations
**Decision:** Design accommodates future growth.

**Scalability Features:**
- `SEAT_NUMBER` as `VARCHAR2(10)` in TICKET table (supports alphanumeric seatings)
- `CAPACITY` in BUS table with check constraint
- `AVAILABLE_SEATS` in SCHEDULE with real-time updates
- Reservation limits (1-10 seats) preventing overbooking

**Reason:** Supports fleet expansion and varying bus configurations.

## 12. Testing Strategy
**Decision:** Comprehensive test coverage.

**Test Areas:**
- Unit tests for all procedures and functions
- Integration tests for trigger restrictions
- Edge cases (holiday bookings, full capacity, invalid inputs)
- Performance tests for concurrent bookings

**Reason:** Ensures production readiness as required by project specifications.

---
*Design decisions prioritize data integrity, performance, maintainability, and compliance with project requirements.*
