CREATE DATABASE UniversityRecordsDB;

USE UniversityRecordsDB;

CREATE TABLE
  Departments (
    DepartmentID INT IDENTITY (1, 1) PRIMARY KEY,
    DepartmentName NVARCHAR (100) NOT NULL UNIQUE,
    Building NVARCHAR (50) NULL,
    Budget DECIMAL(14, 2) NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME ()
  );

CREATE TABLE
  Students (
    StudentID INT IDENTITY (1, 1) PRIMARY KEY,
    FirstName NVARCHAR (50) NOT NULL,
    LastName NVARCHAR (50) NOT NULL,
    Email NVARCHAR (150) NOT NULL UNIQUE,
    EnrollmentDate DATE NOT NULL DEFAULT CAST(GETDATE () AS DATE),
    GPA DECIMAL(3, 2) NOT NULL DEFAULT 0.00 CHECK (
      GPA >= 0.00
      AND GPA <= 4.00
    ),
    DepartmentID INT NOT NULL,
    CONSTRAINT FK_Students_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments (DepartmentID) ON UPDATE CASCADE ON DELETE NO ACTION
  );

CREATE TABLE
  Courses (
    CourseID INT IDENTITY (1, 1) PRIMARY KEY,
    CourseCode NVARCHAR (20) NOT NULL UNIQUE,
    CourseName NVARCHAR (150) NOT NULL,
    Credits TINYINT NOT NULL CHECK (Credits BETWEEN 1 AND 6),
    InstructorName NVARCHAR (100) NULL,
    DepartmentID INT NOT NULL,
    CONSTRAINT FK_Courses_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments (DepartmentID) ON UPDATE CASCADE ON DELETE NO ACTION
  );

CREATE TABLE
  Enrollments (
    EnrollmentID INT IDENTITY (1, 1) PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    Semester NVARCHAR (20) NOT NULL,
    Status NVARCHAR (20) NOT NULL CONSTRAINT DF_Enrollments_Status DEFAULT 'Enrolled' CHECK (
      Status IN ('Enrolled', 'Completed', 'Dropped', 'Withdrawn')
    ),
    Grade NVARCHAR (2) NULL,
    EnrollmentDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME (),
    CONSTRAINT FK_Enrollments_Students FOREIGN KEY (StudentID) REFERENCES Students (StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Enrollments_Courses FOREIGN KEY (CourseID) REFERENCES Courses (CourseID) ON DELETE CASCADE,
    CONSTRAINT UQ_Enrollments_StudentCourseSemester UNIQUE (StudentID, CourseID, Semester)
  );

CREATE TABLE
  Audit_Logs (
    LogID INT IDENTITY (1, 1) PRIMARY KEY,
    TableName NVARCHAR (50) NOT NULL,
    RecordID INT NOT NULL,
    Action NVARCHAR (20) NOT NULL,
    OldValue NVARCHAR (100) NULL,
    NewValue NVARCHAR (100) NULL,
    ChangedBy NVARCHAR (128) NOT NULL DEFAULT SUSER_SNAME (),
    ChangeDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME ()
  );

CREATE INDEX IX_Students_DepartmentID ON Students (DepartmentID);

CREATE INDEX IX_Courses_DepartmentID ON Courses (DepartmentID);

CREATE INDEX IX_Enrollments_StudentID ON Enrollments (StudentID);

CREATE INDEX IX_Enrollments_CourseID ON Enrollments (CourseID);

INSERT INTO
  Departments (DepartmentName, Building, Budget)
VALUES
  ('Computer Science', 'Main Hall', 100000.00),
  ('Mathematics', 'Second Hall', 300000.00),
  ('Physics', 'Third Hall', 350000.00);

INSERT INTO
  Students (FirstName, LastName, Email, GPA, DepartmentID)
VALUES
  (
    'Ana',
    'Kapanadze',
    'ana.kapanadze@example.edu',
    3.8,
    1
  ),
  (
    'Giorgi',
    'Beridze',
    'giorgi.beridze@example.edu',
    2.6,
    1
  ),
  (
    'Mariam',
    'Lomidze',
    'mariam.lomidze@example.edu',
    3.4,
    2
  ),
  (
    'Levan',
    'Tsiklauri',
    'levan.tsiklauri@example.edu',
    3.1,
    3
  );

INSERT INTO
  Courses (
    CourseCode,
    CourseName,
    Credits,
    InstructorName,
    DepartmentID
  )
VALUES
  (
    'CS101',
    'Intro to Programming',
    3,
    'Dr. Kakashvili',
    1
  ),
  (
    'MA201',
    'Linear Algebra',
    4,
    'Dr. Nanobashvili',
    2
  ),
  (
    'PH150',
    'Classical Mechanics',
    3,
    'Dr. Janelidze',
    3
  );

INSERT INTO
  Enrollments (StudentID, CourseID, Semester, Status)
VALUES
  (1, 1, 'Fall 2026', 'Enrolled'),
  (2, 1, 'Fall 2026', 'Enrolled'),
  (3, 2, 'Fall 2026', 'Enrolled'),
  (4, 3, 'Fall 2026', 'Enrolled');

--Shows students with GPA >= 3.0 along with their home department.
CREATE
OR
ALTER VIEW v_Top_Students AS
SELECT
  s.StudentID,
  s.FirstName,
  s.LastName,
  s.Email,
  s.GPA,
  d.DepartmentName AS Department
FROM
  Students AS s
  INNER JOIN Departments AS d ON s.DepartmentID = d.DepartmentID
WHERE
  s.GPA >= 3.00;

-- SELECT * FROM v_Top_Students ORDER BY GPA DESC;
--trigger for status changes
CREATE
OR
ALTER TRIGGER trg_Enrollment_StatusChange ON Enrollments AFTER
UPDATE AS BEGIN
SET
  NOCOUNT ON;

IF
UPDATE (Status) BEGIN
INSERT INTO
  Audit_Logs (
    TableName,
    RecordID,
    Action,
    OldValue,
    NewValue,
    ChangedBy
  )
SELECT
  'Enrollments',
  i.EnrollmentID,
  'STATUS_UPDATE',
  d.Status,
  i.Status,
  SUSER_SNAME ()
FROM
  inserted AS i
  INNER JOIN deleted AS d ON i.EnrollmentID = d.EnrollmentID
WHERE
  i.Status <> d.Status;

END END;

CREATE ROLE db_admin;

ALTER ROLE db_owner ADD MEMBER db_admin;

CREATE ROLE committee_reviewer;

GRANT
SELECT
  ON dbo.Students TO committee_reviewer;

GRANT
SELECT
  ON dbo.Enrollments TO committee_reviewer;

DENY INSERT,
UPDATE,
DELETE ON dbo.Students TO committee_reviewer;

DENY INSERT,
UPDATE,
DELETE ON dbo.Enrollments TO committee_reviewer;

CREATE TABLE
  ErrorLog (
    ErrorLogID INT IDENTITY (1, 1) PRIMARY KEY,
    ErrorNumber INT NULL,
    ErrorSeverity INT NULL,
    ErrorState INT NULL,
    ErrorProcedure NVARCHAR (200) NULL,
    ErrorLine INT NULL,
    ErrorMessage NVARCHAR (4000) NULL,
    ErrorDateTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME (),
    LoggedBy NVARCHAR (128) NOT NULL DEFAULT SUSER_SNAME ()
  );

CREATE
OR
ALTER TRIGGER trg_Students_GPAChange ON Students AFTER
UPDATE AS BEGIN
SET
  NOCOUNT ON;

IF
UPDATE (GPA) BEGIN
INSERT INTO
  Audit_Logs (
    TableName,
    RecordID,
    Action,
    OldValue,
    NewValue,
    ChangedBy
  )
SELECT
  'Students',
  i.StudentID,
  'GPA_UPDATE',
  CAST(d.GPA AS NVARCHAR (10)),
  CAST(i.GPA AS NVARCHAR (10)),
  SUSER_SNAME ()
FROM
  inserted AS i
  INNER JOIN deleted AS d ON i.StudentID = d.StudentID
WHERE
  i.GPA <> d.GPA;

END END;