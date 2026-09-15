# University Academic Records & Enrollment Database

A Microsoft SQL Server project demonstrating relational schema design,
data integrity, auditing via triggers, role-based access control, and
a basic backup procedure.

## Overview

This project models a simplified academic records system for a
university: departments offer courses, students enroll in those
courses each semester, and changes to enrollment status or student
GPA are automatically logged for auditing purposes.

## Architecture

### Entity-Relationship Summary

```
Departments 1───* Students
Departments 1───* Courses
Students    1───* Enrollments *───1 Courses

Enrollments (Status change) ──(trigger)──▶ Audit_Logs
Students    (GPA change)    ──(trigger)──▶ Audit_Logs
```

| Table         | Purpose                                                 |
| ------------- | ------------------------------------------------------- |
| `Departments` | Academic units (e.g., Computer Science, Mathematics)    |
| `Students`    | Student records, including GPA and home department      |
| `Courses`     | Course catalog, linked to the offering department       |
| `Enrollments` | Junction table linking students to courses per semester |
| `Audit_Logs`  | Append-only history of status and GPA changes           |
| `ErrorLog`    | Structured table for capturing procedure error details  |

Referential integrity is enforced with primary/foreign keys, `UNIQUE`
constraints (e.g. one enrollment per student/course/semester), and
`CHECK` constraints (GPA bounded 0.00–4.00, enrollment status limited
to a fixed set of values).

## Features

### Schema & Data Integrity

- Six tables connected with primary/foreign keys, unique constraints,
  and check constraints.
- Supporting indexes on every foreign key column
  (`Students.DepartmentID`, `Courses.DepartmentID`,
  `Enrollments.StudentID`, `Enrollments.CourseID`) to keep joins fast.
- Sample seed data for all core tables to make the schema demoable
  immediately after running the script.

### View

- **`v_Top_Students`** — joins `Students` to `Departments` and returns
  students with a GPA of 3.0 or higher, alongside their department.

### Triggers

- **`trg_Enrollment_StatusChange`** — fires `AFTER UPDATE` on
  `Enrollments`; when `Status` changes (e.g. `Enrolled` →
  `Completed`), it writes a timestamped row to `Audit_Logs` with the
  old value, new value, and the user who made the change.
- **`trg_Students_GPAChange`** — the same audit pattern applied to
  `Students.GPA`, so grade changes are traceable too.

### Stored Procedure

- **`usp_BackupDatabaseFull`** — takes a compressed, checksum-validated
  full backup of the database to a configurable directory, with a
  timestamped filename so repeated backups don't overwrite each other.

### Security (Role-Based Access Control)

- **`db_admin`** — full administrative privileges via membership in
  the built-in `db_owner` role.
- **`committee_reviewer`** — read-only `SELECT` access to `Students`
  and `Enrollments` only, with explicit `DENY` on `INSERT`, `UPDATE`,
  and `DELETE` for both tables as defense-in-depth.

## Getting Started

1. Open the script in SQL Server Management Studio (SSMS) or Azure
   Data Studio, connected to a SQL Server instance.
2. Run the script — it creates `UniversityRecordsDB`, builds the
   schema, loads sample data, and sets up the view, triggers, roles,
   and backup procedure.
3. Try it out:

```sql
-- See students with a GPA of 3.0+
SELECT * FROM v_Top_Students ORDER BY GPA DESC;

-- Trigger a status change and confirm it's audited
UPDATE Enrollments SET Status = 'Completed', Grade = 'A' WHERE EnrollmentID = 1;
SELECT * FROM Audit_Logs;

-- Trigger a GPA change and confirm it's audited too
UPDATE Students SET GPA = 3.9 WHERE StudentID = 2;
SELECT * FROM Audit_Logs WHERE TableName = 'Students';

-- Take a full backup (adjust the directory to one that exists on your instance)
EXEC usp_BackupDatabaseFull @BackupDirectory = N'C:\SQLBackups\';
```

## Tech Stack

- Microsoft SQL Server (T-SQL)
- Compatible with SSMS, Azure Data Studio, or `sqlcmd`

## Possible Extensions

- Add stored procedures for enrolling students and updating enrollment
  status, wrapped in `TRY/CATCH` and transactions, logging failures to
  `ErrorLog`.
- Add index maintenance (rebuild/reorganize based on fragmentation)
  and statistics-refresh procedures.
- Archive old `Audit_Logs` rows to a separate table on a retention
  schedule.
- Schedule `usp_BackupDatabaseFull` as a recurring SQL Server Agent
  job.
- Set the database to `FULL` recovery model and pair full backups with
  transaction-log backups for point-in-time restore.
