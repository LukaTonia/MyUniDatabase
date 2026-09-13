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

  CREATE TABLE Enrollments (
    EnrollmentID    INT IDENTITY(1,1) PRIMARY KEY,
    StudentID       INT             NOT NULL,
    CourseID        INT             NOT NULL,
    Semester        NVARCHAR(20)    NOT NULL,       
    Status          NVARCHAR(20)    NOT NULL
                       CONSTRAINT DF_Enrollments_Status DEFAULT 'Enrolled'
                       CHECK (Status IN ('Enrolled','Completed','Dropped','Withdrawn')),
    Grade           NVARCHAR(2)     NULL,           
    EnrollmentDate  DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Enrollments_Students
        FOREIGN KEY (StudentID) REFERENCES Students(StudentID)
        ON DELETE CASCADE,
    CONSTRAINT FK_Enrollments_Courses
        FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
        ON DELETE CASCADE,
    CONSTRAINT UQ_Enrollments_StudentCourseSemester
        UNIQUE (StudentID, CourseID, Semester)
);