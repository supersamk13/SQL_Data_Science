-- Create employee table
CREATE TABLE employee (
    emp_id INTEGER PRIMARY KEY,
    first_name VARCHAR(20), 
    last_name VARCHAR(20),
    birth_date DATE, 
    sex VARCHAR(1),
    salary INTEGER,
    super_id INTEGER,
    branch_id INTEGER,
    FOREIGN KEY(super_id) REFERENCES employee(emp_id) ON DELETE SET NULL,
    FOREIGN KEY(branch_id) REFERENCES branch(branch_id) ON DELETE SET NULL
);

-- Create branch table
CREATE TABLE branch (
    branch_id INTEGER PRIMARY KEY,
    branch_name VARCHAR(20), 
    mgr_id INTEGER,
    mgr_start_date DATE,
    FOREIGN KEY(mgr_id) REFERENCES employee(emp_id) ON DELETE SET NULL
);

-- Create works_with table
CREATE TABLE works_with (
    emp_id INTEGER,
    client_id INTEGER,
    total_sales INTEGER,
    PRIMARY KEY(emp_id, client_id),
    FOREIGN KEY(emp_id) REFERENCES employee(emp_id) ON DELETE CASCADE,
    FOREIGN KEY(client_id) REFERENCES client(client_id) ON DELETE CASCADE
);

-- Create client table
CREATE TABLE client (
    client_id INTEGER PRIMARY KEY,
    client_name VARCHAR(25),
    branch_id INTEGER,
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id) ON DELETE SET NULL
);

-- Create branch_supplier table
CREATE TABLE branch_supplier (
    branch_id INTEGER,
    supplier_name INTEGER,
    supply_type VARCHAR(20),
    PRIMARY KEY(branch_id, supplier_name),
    FOREIGN KEY(branch_id) REFERENCES branch(branch_id) ON DELETE CASCADE
);

-- Corporate
INSERT INTO employee VALUES(100, 'David', 'Wallace', '1967-11-17', 'M', 250000, NULL, NULL);

INSERT INTO branch VALUES(1, 'Corporate', 100, '2006-02-09');

-- Update employee branch_id
UPDATE employee
SET branch_id = 1
WHERE emp_id = 100;

INSERT INTO employee VALUES(101, 'Jan', 'Levinson', '1961-05-11', 'F', 110000, 100, 1);

-- Scranton
INSERT INTO employee VALUES(102, 'Michael', 'Scott', '1964-03-15', 'M', 75000, 100, NULL);

INSERT INTO branch VALUES(2, 'Scranton', 102, '1992-04-06');

-- Update employee branch_id
UPDATE employee
SET branch_id = 2
WHERE emp_id = 102;

INSERT INTO employee VALUES(103, 'Angela', 'Martin', '1971-06-25', 'F', 63000, 102, 2);
INSERT INTO employee VALUES(104, 'Kelly', 'Kapoor', '1980-02-05', 'F', 55000, 102, 2);
INSERT INTO employee VALUES(105, 'Stanley', 'Hudson', '1958-02-19', 'M', 69000, 102, 2);

-- Stamford
INSERT INTO employee VALUES(106, 'Josh', 'Porter', '1969-09-05', 'M', 78000, 100, NULL);

INSERT INTO branch VALUES(3, 'Stamford', 106, '1998-02-13');

-- Update employee branch_id
UPDATE employee
SET branch_id = 3
WHERE emp_id = 106;

INSERT INTO employee VALUES(107, 'Andy', 'Bernard', '1973-07-22', 'M', 65000, 106, 3);
INSERT INTO employee VALUES(108, 'Jim', 'Halpert', '1978-10-01', 'M', 71000, 106, 3);

INSERT INTO branch VALUES(4, 'Buffalo', NULL, NULL);

-- BRANCH SUPPLIER
INSERT INTO branch_supplier VALUES(2, 'Hammer Mill', 'Paper');
INSERT INTO branch_supplier VALUES(2, 'Uni-ball', 'Writing Utensils');
INSERT INTO branch_supplier VALUES(3, 'Patriot Paper', 'Paper');
INSERT INTO branch_supplier VALUES(2, 'J.T. Forms & Labels', 'Custom Forms');
INSERT INTO branch_supplier VALUES(3, 'Uni-ball', 'Writing Utensils');
INSERT INTO branch_supplier VALUES(3, 'Hammer Mill', 'Paper');
INSERT INTO branch_supplier VALUES(3, 'Stamford Lables', 'Custom Forms');

-- CLIENT
INSERT INTO client VALUES(400, 'Dunmore Highschool', 2);
INSERT INTO client VALUES(401, 'Lackawana Country', 2);
INSERT INTO client VALUES(402, 'FedEx', 3);
INSERT INTO client VALUES(403, 'John Daly Law, LLC', 3);
INSERT INTO client VALUES(404, 'Scranton Whitepages', 2);
INSERT INTO client VALUES(405, 'Times Newspaper', 3);
INSERT INTO client VALUES(406, 'FedEx', 2);

-- WORKS_WITH
INSERT INTO works_with VALUES(105, 400, 55000);
INSERT INTO works_with VALUES(102, 401, 267000);
INSERT INTO works_with VALUES(108, 402, 22500);
INSERT INTO works_with VALUES(107, 403, 5000);
INSERT INTO works_with VALUES(108, 403, 12000);
INSERT INTO works_with VALUES(105, 404, 33000);
INSERT INTO works_with VALUES(107, 405, 26000);
INSERT INTO works_with VALUES(102, 406, 15000);
INSERT INTO works_with VALUES(105, 406, 130000);

-- Wildcards

-- Get employees born in October
SELECT * FROM employee WHERE birth_date LIKE '____-10%';

-- Unions
-- Find a list of employee and branch names
SELECT first_name FROM employee
UNION
SELECT branch_name FROM branch;

-- List of clients and branch_supplier's names
SELECT client_name FROM client AS firm_names
UNION
SELECT supplier_name FROM branch_supplier;

-- Find all branches and their managers
SELECT employee.emp_id, employee.first_name, employee.last_name, branch.branch_id, branch.branch_name
FROM employee
JOIN branch
ON employee.emp_id = branch.mgr_id;

SELECT employee.emp_id, employee.first_name, employee.last_name, branch.branch_id, branch.branch_name
FROM employee
LEFT JOIN branch
ON employee.emp_id = branch.mgr_id;

-- Find names of all employees who have sold over 30,000 to a single client
SELECT employee.first_name, employee.last_name, works_with.total_sales 
FROM employee
INNER JOIN works_with
ON employee.emp_id = works_with.emp_id
WHERE works_with.total_sales > 30000;

-- Find all clients who are handled by the branch 
-- that Michael Scott manages
SELECT client.client_name
FROM client
WHERE client.branch_id = (
    SELECT branch.branch_id
    FROM branch
    WHERE branch.mgr_id = (
        SELECT employee.emp_id
        FROM employee
        WHERE employee.first_name = "Michael" AND employee.last_name = "Scott"
        LIMIT(1)
    )
    LIMIT (1)
);

-- Create audit_log table if not exists
CREATE TABLE IF NOT EXISTS audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50),
    action_type VARCHAR(10),
    record_id INT,
    field_name VARCHAR(50),
    old_value VARCHAR(255),
    new_value VARCHAR(255),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create or replace the audit trail trigger
DELIMITER //

CREATE TRIGGER audit_employee_changes
AFTER INSERT OR UPDATE OR DELETE ON employee
FOR EACH ROW
BEGIN
    DECLARE log_action_type VARCHAR(10);
    DECLARE log_old_value VARCHAR(255);
    DECLARE log_new_value VARCHAR(255);

    -- Determine the action type
    IF NEW.emp_id IS NOT NULL AND OLD.emp_id IS NULL THEN
        SET log_action_type = 'INSERT';
    ELSEIF NEW.emp_id IS NULL AND OLD.emp_id IS NOT NULL THEN
        SET log_action_type = 'DELETE';
    ELSE
        SET log_action_type = 'UPDATE';
    END IF;

    -- Log the changes for relevant columns
    IF log_action_type = 'UPDATE' THEN
        -- Example: Log changes for the 'first_name' column
        IF NEW.first_name != OLD.first_name THEN
            SET log_old_value = OLD.first_name;
            SET log_new_value = NEW.first_name;
            INSERT INTO audit_log (table_name, action_type, record_id, field_name, old_value, new_value)
            VALUES ('employee', log_action_type, NEW.emp_id, 'first_name', log_old_value, log_new_value);
        END IF;

        -- Add similar checks for other columns as needed
        -- Example: Log changes for the 'salary' column
        IF NEW.salary != OLD.salary THEN
            SET log_old_value = OLD.salary;
            SET log_new_value = NEW.salary;
            INSERT INTO audit_log (table_name, action_type, record_id, field_name, old_value, new_value)
            VALUES ('employee', log_action_type, NEW.emp_id, 'salary', log_old_value, log_new_value);
        END IF;
    END IF;

    -- Log the entire row for INSERT and DELETE actions
    IF log_action_type IN ('INSERT', 'DELETE') THEN
        INSERT INTO audit_log (table_name, action_type, record_id, old_value, new_value)
        VALUES ('employee', log_action_type, NEW.emp_id, NULL, NULL);
    END IF;
END //

DELIMITER ;