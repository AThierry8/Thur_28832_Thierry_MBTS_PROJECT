DECLARE
  CURSOR big_cursor IS
    SELECT employee_id, first_name, email
    FROM employees;
    
  TYPE emp_table IS TABLE OF big_cursor%ROWTYPE;
  v_employees emp_table;
BEGIN
  -- BULK COLLECT: fetches all rows at once (optimized)
  OPEN big_cursor;
  FETCH big_cursor BULK COLLECT INTO v_employees;
  CLOSE big_cursor;
  
  -- Process the collection
  FOR i IN 1..v_employees.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Employee: ' || v_employees(i).first_name);
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('Total employees processed: ' || v_employees.COUNT);
END;
/

DECLARE
  -- Explicit cursor for EMPLOYEES table
  CURSOR emp_cursor IS
    SELECT employee_id, first_name, last_name, salary, department_id
    FROM employees
    WHERE department_id IN (10, 20, 30)
    ORDER BY last_name;
    
  -- BULK collection type
  TYPE emp_table IS TABLE OF emp_cursor%ROWTYPE;
  v_employees emp_table;
  
  v_total_salary NUMBER := 0;
BEGIN
  -- OPEN cursor
  OPEN emp_cursor;
  
  -- BULK FETCH all rows
  FETCH emp_cursor BULK COLLECT INTO v_employees;
  
  -- CLOSE cursor
  CLOSE emp_cursor;
  
  -- Process collection
  FOR i IN 1..v_employees.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE(
      'Employee: ' || v_employees(i).first_name || ' ' || 
      v_employees(i).last_name || 
      ', Salary: $' || v_employees(i).salary ||
      ', Dept: ' || v_employees(i).department_id
    );
    v_total_salary := v_total_salary + v_employees(i).salary;
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('Total employees: ' || v_employees.COUNT);
  DBMS_OUTPUT.PUT_LINE('Total salary sum: $' || v_total_salary);
END;
/


