CREATE DATABASE UniversityRecordsDB;
USE UniversityRecordsDB;
CREATE TABLE Departments (
    DepartmentID    INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName  NVARCHAR(100)   NOT NULL UNIQUE,
    Building        NVARCHAR(50)    NULL,
    Budget          DECIMAL(14,2)   NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);