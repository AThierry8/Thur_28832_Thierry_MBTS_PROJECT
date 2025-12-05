MOBILE BUS TICKETING SYSTEM - DATA DICTIONARY
TABLE 1: CLIENTS
Column	Type	Size	PK/FK	Null?	Description
client_id	NUMBER	10	PK	NO	Unique client identifier
email	VARCHAR2	100	-	NO	Unique email address
phone_number	VARCHAR2	20	-	NO	Contact phone number
full_name	VARCHAR2	100	-	NO	Client's full name
registration_date	DATE	-	-	YES	Date of registration
TABLE 2: EMPLOYEE 
Column	Type	Size	PK/FK	Null?	Description
employee_id	NUMBER	10	PK	NO	Unique employee identifier
client_id	NUMBER	10	FK→CLIENTS	NO	Associated client account
employee_code	VARCHAR2	20	UNIQUE	NO	Employee identification code
department	VARCHAR2	20	-	YES	Employee department
TABLE 3: HOLIDAY 
Column	Type	Size	PK/FK	Null?	Description
holiday_id	NUMBER	10	PK	NO	Unique holiday identifier
holiday_date	DATE	-	UNIQUE	NO	Date of holiday
holiday_name	VARCHAR2	100	-	NO	Name of holiday
created_by	NUMBER	10	FK→EMPLOYEE	YES	Employee who created holiday
TABLE 4: BUS
Column	Type	Size	PK/FK	Null?	Description
bus_id	NUMBER	10	PK	NO	Unique bus identifier
bus_number	VARCHAR2	20	UNIQUE	NO	Physical bus number
capacity	NUMBER	3	-	NO	Maximum seat capacity
TABLE 5: ROUTE
Column	Type	Size	PK/FK	Null?	Description
route_id	NUMBER	10	PK	NO	Unique route identifier
departure_location	VARCHAR2	50	-	NO	Starting location
destination	VARCHAR2	50	-	NO	Ending location
distance_km	NUMBER	6,2	-	NO	Distance in kilometers
estimated_hours	NUMBER	3,1	-	NO	Estimated travel time
TABLE 6: DRIVER
Column	Type	Size	PK/FK	Null?	Description
driver_id	NUMBER	10	PK	NO	Unique driver identifier
driver_name	VARCHAR2	100	-	NO	Driver's full name
license_number	VARCHAR2	50	UNIQUE	NO	Driving license number
TABLE 7: SCHEDULE 
Column	Type	Size	PK/FK	Null?	Description
schedule_id	NUMBER	10	PK	NO	Unique schedule identifier
route_id	NUMBER	10	FK→ROUTE	NO	Associated route
bus_id	NUMBER	10	FK→BUS	NO	Assigned bus
driver_id	NUMBER	10	FK→DRIVER	NO	Assigned driver
departure_date	DATE	-	-	NO	Date of departure
departure_time	VARCHAR2	5	-	NO	Time of departure (HH24:MI)
available_seats	NUMBER	3	-	NO	Available seats count
fare_amount	NUMBER	8,2	-	NO	Price per seat
status	VARCHAR2	20	-	YES	Schedule status
TABLE 8: RESERVATION
Column	Type	Size	PK/FK	Null?	Description
reservation_id	NUMBER	10	PK	NO	Unique reservation identifier
client_id	NUMBER	10	FK→CLIENTS	NO	Client who made booking
schedule_id	NUMBER	10	FK→SCHEDULE	NO	Booked schedule
reservation_date	DATE	-	-	YES	Date of reservation
seats_count	NUMBER	2	-	YES	Number of seats booked
total_amount	NUMBER	10,2	-	NO	Total payment amount
status	VARCHAR2	20	-	YES	Reservation status
TABLE 9: TICKET
Column	Type	Size	PK/FK	Null?	Description
ticket_id	NUMBER	10	PK	NO	Unique ticket identifier
reservation_id	NUMBER	10	FK→RESERVATION	NO	Associated reservation
client_id	NUMBER	10	FK→CLIENTS	NO	Ticket holder
schedule_id	NUMBER	10	FK→SCHEDULE	NO	Associated schedule
seat_number	VARCHAR2	10	-	NO	Assigned seat number
issue_date	DATE	-	-	YES	Ticket issue date
TABLE 10: PAYMENT
Column	Type	Size	PK/FK	Null?	Description
payment_id	NUMBER	10	PK	NO	Unique payment identifier
reservation_id	NUMBER	10	FK→RESERVATION	NO	Associated reservation
payment_method	VARCHAR2	20	-	YES	Payment method used
amount	NUMBER	10,2	-	NO	Amount paid
payment_date	DATE	-	-	YES	Date of payment
status	VARCHAR2	20	-	YES	Payment status
TABLE 11: NOTIFICATION
Column	Type	Size	PK/FK	Null?	Description
notification_id	NUMBER	10	PK	NO	Unique notification identifier
client_id	NUMBER	10	FK→CLIENTS	NO	Recipient client
message	VARCHAR2	500	-	NO	Notification message
sent_date	DATE	-	-	YES	Date sent
TABLE 12: AUDIT_LOG 
Column	Type	Size	PK/FK	Null?	Description
log_id	NUMBER	10	PK	NO	Unique log identifier
employee_id	NUMBER	10	FK→EMPLOYEE	NO	Employee who performed action
action_type	VARCHAR2	20	-	NO	Type of action (INSERT/UPDATE/DELETE)
table_name	VARCHAR2	30	-	NO	Table where action occurred
action_date	DATE	-	-	YES	Date of action
status	VARCHAR2	20	-	NO	Result (ALLOWED/DENIED)

BUSINESS RULES
•	Employees cannot INSERT/UPDATE/DELETE on weekdays (Mon-Fri)
•	Employees cannot INSERT/UPDATE/DELETE on holidays
•	All attempts logged in AUDIT_LOG with status ALLOWED/DENIED
Booking Rules:
•	Maximum 10 seats per reservation
•	Available seats cannot go negative
•	One payment per reservation (1:1 relationship)
Data Integrity:
•	Client email must be unique
•	Bus number must be unique
•	Driver license must be unique
•	Holiday dates cannot duplicate
Status Values:
•	Schedule: SCHEDULED, CANCELLED
•	Reservation: CONFIRMED, CANCELLED
•	Payment: COMPLETED, FAILED
•	Audit Log: ALLOWED, DENIED

