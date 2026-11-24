/* =====================================================================
   Inpatient Management System  |  Database Systems 1
   Target : Microsoft SQL Server (run in SSMS)
   How to run: open in SSMS -> Execute (F5). The script is re-runnable:
   it drops and recreates the database InpatientDB.
   Sections: 1) Database  2) Tables (DDL)  3) Sample data (left empty)
             4) Views  5) Stored procedures  6) Queries  7) Demo (optional)
   ===================================================================== */

USE master;
GO
IF DB_ID(N'InpatientDB') IS NOT NULL
BEGIN
    ALTER DATABASE InpatientDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE InpatientDB;
END
GO
CREATE DATABASE InpatientDB;
GO
USE InpatientDB;
GO

/* ===================== 2) TABLES (DDL) ===================== */

CREATE TABLE Department (
    DepartmentID    INT IDENTITY(1,1) CONSTRAINT PK_Department PRIMARY KEY,
    DepartmentName  NVARCHAR(100) NOT NULL CONSTRAINT UQ_Department_Name UNIQUE
);

CREATE TABLE Doctor (
    DoctorID        INT IDENTITY(1,1) CONSTRAINT PK_Doctor PRIMARY KEY,
    DoctorName      NVARCHAR(100) NOT NULL,
    Specialization  NVARCHAR(100) NULL,
    DepartmentID    INT NOT NULL
        CONSTRAINT FK_Doctor_Department REFERENCES Department(DepartmentID)
);

CREATE TABLE Room (
    RoomID          INT IDENTITY(1,1) CONSTRAINT PK_Room PRIMARY KEY,
    RoomNumber      NVARCHAR(10) NOT NULL,
    DepartmentID    INT NOT NULL
        CONSTRAINT FK_Room_Department REFERENCES Department(DepartmentID),
    CONSTRAINT UQ_Room_Dept_Number UNIQUE (DepartmentID, RoomNumber)
);

CREATE TABLE BedClass (
    BedClassID      INT IDENTITY(1,1) CONSTRAINT PK_BedClass PRIMARY KEY,
    ClassName       NVARCHAR(50) NOT NULL CONSTRAINT UQ_BedClass_Name UNIQUE,
    DailyCost       DECIMAL(10,2) NOT NULL CONSTRAINT CK_BedClass_Cost CHECK (DailyCost >= 0)
);

CREATE TABLE Bed (
    BedID           INT IDENTITY(1,1) CONSTRAINT PK_Bed PRIMARY KEY,
    BedNumber       INT NOT NULL,
    RoomID          INT NOT NULL
        CONSTRAINT FK_Bed_Room REFERENCES Room(RoomID),
    BedClassID      INT NOT NULL
        CONSTRAINT FK_Bed_BedClass REFERENCES BedClass(BedClassID),
    CONSTRAINT UQ_Bed_Room_Number UNIQUE (RoomID, BedNumber)
);

CREATE TABLE Lab (
    LabID           INT IDENTITY(1,1) CONSTRAINT PK_Lab PRIMARY KEY,
    LabName         NVARCHAR(100) NOT NULL CONSTRAINT UQ_Lab_Name UNIQUE,
    ManagerName     NVARCHAR(100) NULL
);

CREATE TABLE ClinicalService (
    ServiceID       INT IDENTITY(1,1) CONSTRAINT PK_ClinicalService PRIMARY KEY,
    ServiceName     NVARCHAR(100) NOT NULL CONSTRAINT UQ_Service_Name UNIQUE,
    ServiceType     NVARCHAR(20) NOT NULL
        CONSTRAINT CK_Service_Type CHECK (ServiceType IN (N'Lab Test', N'Imaging', N'Operation', N'Other')),
    ServiceCost     DECIMAL(10,2) NOT NULL CONSTRAINT CK_Service_Cost CHECK (ServiceCost >= 0),
    LabID           INT NULL
        CONSTRAINT FK_Service_Lab REFERENCES Lab(LabID),
    -- A "Lab Test" must belong to a lab; other types do not require one
    CONSTRAINT CK_Service_LabRequired CHECK (ServiceType <> N'Lab Test' OR LabID IS NOT NULL)
);

CREATE TABLE Patient (
    PatientID       INT IDENTITY(1,1) CONSTRAINT PK_Patient PRIMARY KEY,
    PatientName     NVARCHAR(100) NOT NULL,
    PatientAddress  NVARCHAR(200) NULL,
    Phone           NVARCHAR(20)  NULL
);

CREATE TABLE Admission (
    AdmissionID     INT IDENTITY(1,1) CONSTRAINT PK_Admission PRIMARY KEY,
    PatientID       INT NOT NULL
        CONSTRAINT FK_Admission_Patient REFERENCES Patient(PatientID),
    BedID           INT NOT NULL
        CONSTRAINT FK_Admission_Bed REFERENCES Bed(BedID),
    CheckInDate     DATE NOT NULL,
    CheckOutDate    DATE NULL,              -- NULL = patient still admitted
    AdmissionReason NVARCHAR(200) NULL,
    CONSTRAINT CK_Admission_Dates CHECK (CheckOutDate IS NULL OR CheckOutDate >= CheckInDate)
);

-- BR-07: one open admission per bed and per patient
CREATE UNIQUE INDEX UX_Admission_OpenBed
    ON Admission(BedID) WHERE CheckOutDate IS NULL;
CREATE UNIQUE INDEX UX_Admission_OpenPatient
    ON Admission(PatientID) WHERE CheckOutDate IS NULL;

CREATE TABLE Supervision (
    AdmissionID     INT NOT NULL
        CONSTRAINT FK_Supervision_Admission REFERENCES Admission(AdmissionID),
    DoctorID        INT NOT NULL
        CONSTRAINT FK_Supervision_Doctor REFERENCES Doctor(DoctorID),
    CONSTRAINT PK_Supervision PRIMARY KEY (AdmissionID, DoctorID)
);

CREATE TABLE ServiceRecord (
    ServiceRecordID INT IDENTITY(1,1) CONSTRAINT PK_ServiceRecord PRIMARY KEY,
    AdmissionID     INT NOT NULL
        CONSTRAINT FK_SR_Admission REFERENCES Admission(AdmissionID),
    ServiceID       INT NOT NULL
        CONSTRAINT FK_SR_Service REFERENCES ClinicalService(ServiceID),
    PerformedAt     DATETIME2(0) NOT NULL CONSTRAINT DF_SR_PerformedAt DEFAULT SYSDATETIME(),
    Notes           NVARCHAR(300) NULL
);
GO

/* ===================== 3) SAMPLE DATA ===================== */
-- Intentionally empty: another team member inserts the data.
-- Insert order (parents first): Department, Doctor, Room, BedClass, Bed, Lab,
-- ClinicalService, Patient, Admission, Supervision, ServiceRecord.
GO

/* ===================== 4) VIEWS ===================== */

-- Current inpatients (open admissions)
CREATE VIEW vw_CurrentInpatients AS
SELECT a.AdmissionID, p.PatientID, p.PatientName, d.DepartmentName,
       r.RoomNumber, b.BedNumber, bc.ClassName AS BedClass,
       a.CheckInDate,
       CASE WHEN DATEDIFF(DAY, a.CheckInDate, CAST(GETDATE() AS DATE)) = 0 THEN 1
            ELSE DATEDIFF(DAY, a.CheckInDate, CAST(GETDATE() AS DATE)) END AS DaysStayed,
       a.AdmissionReason
FROM Admission a
JOIN Patient p    ON a.PatientID = p.PatientID
JOIN Bed b        ON a.BedID = b.BedID
JOIN BedClass bc  ON b.BedClassID = bc.BedClassID
JOIN Room r       ON b.RoomID = r.RoomID
JOIN Department d ON r.DepartmentID = d.DepartmentID
WHERE a.CheckOutDate IS NULL;
GO

-- Beds with no open admission
CREATE VIEW vw_AvailableBeds AS
SELECT b.BedID, d.DepartmentName, r.RoomNumber, b.BedNumber,
       bc.ClassName AS BedClass, bc.DailyCost
FROM Bed b
JOIN Room r       ON b.RoomID = r.RoomID
JOIN Department d ON r.DepartmentID = d.DepartmentID
JOIN BedClass bc  ON b.BedClassID = bc.BedClassID
WHERE NOT EXISTS (SELECT 1 FROM Admission a
                  WHERE a.BedID = b.BedID AND a.CheckOutDate IS NULL);
GO

-- Bill per admission = bed cost (daily cost x days, min 1 day) + services
CREATE VIEW vw_AdmissionBill AS
SELECT a.AdmissionID, p.PatientName, a.CheckInDate, a.CheckOutDate,
       x.DaysStayed,
       bc.DailyCost,
       x.DaysStayed * bc.DailyCost                  AS BedCharge,
       ISNULL(s.ServicesTotal, 0)                   AS ServicesTotal,
       x.DaysStayed * bc.DailyCost + ISNULL(s.ServicesTotal, 0) AS TotalBill
FROM Admission a
JOIN Patient p   ON a.PatientID = p.PatientID
JOIN Bed b       ON a.BedID = b.BedID
JOIN BedClass bc ON b.BedClassID = bc.BedClassID
CROSS APPLY (
    SELECT CASE WHEN DATEDIFF(DAY, a.CheckInDate, ISNULL(a.CheckOutDate, CAST(GETDATE() AS DATE))) < 1
                THEN 1
                ELSE DATEDIFF(DAY, a.CheckInDate, ISNULL(a.CheckOutDate, CAST(GETDATE() AS DATE)))
           END AS DaysStayed
) x
OUTER APPLY (
    SELECT SUM(cs.ServiceCost) AS ServicesTotal
    FROM ServiceRecord sr
    JOIN ClinicalService cs ON sr.ServiceID = cs.ServiceID
    WHERE sr.AdmissionID = a.AdmissionID
) s;
GO

/* ===================== 5) STORED PROCEDURES ===================== */
-- Useful for the C# screens (call them with parameterized SqlCommand)

CREATE PROCEDURE sp_AdmitPatient
    @PatientID       INT,
    @BedID           INT,
    @CheckInDate     DATE = NULL,
    @AdmissionReason NVARCHAR(200) = NULL,
    @NewAdmissionID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @CheckInDate IS NULL SET @CheckInDate = CAST(GETDATE() AS DATE);

    IF EXISTS (SELECT 1 FROM Admission WHERE BedID = @BedID AND CheckOutDate IS NULL)
        THROW 50001, 'This bed is already occupied.', 1;
    IF EXISTS (SELECT 1 FROM Admission WHERE PatientID = @PatientID AND CheckOutDate IS NULL)
        THROW 50002, 'This patient already has an open admission.', 1;

    INSERT INTO Admission (PatientID, BedID, CheckInDate, AdmissionReason)
    VALUES (@PatientID, @BedID, @CheckInDate, @AdmissionReason);

    SET @NewAdmissionID = SCOPE_IDENTITY();
END
GO

CREATE PROCEDURE sp_DischargePatient
    @AdmissionID   INT,
    @CheckOutDate  DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @CheckOutDate IS NULL SET @CheckOutDate = CAST(GETDATE() AS DATE);

    UPDATE Admission
    SET CheckOutDate = @CheckOutDate
    WHERE AdmissionID = @AdmissionID AND CheckOutDate IS NULL;

    IF @@ROWCOUNT = 0
        THROW 50003, 'Admission not found or patient already discharged.', 1;
END
GO

CREATE PROCEDURE sp_AssignDoctor
    @AdmissionID INT,
    @DoctorID    INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Supervision WHERE AdmissionID = @AdmissionID AND DoctorID = @DoctorID)
        THROW 50004, 'This doctor already supervises this admission.', 1;
    INSERT INTO Supervision (AdmissionID, DoctorID) VALUES (@AdmissionID, @DoctorID);
END
GO

CREATE PROCEDURE sp_AddServiceToAdmission
    @AdmissionID INT,
    @ServiceID   INT,
    @Notes       NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ServiceRecord (AdmissionID, ServiceID, Notes)
    VALUES (@AdmissionID, @ServiceID, @Notes);
END
GO

/* ===================== 6) QUERIES ===================== */

-- Q1: Current inpatients
SELECT p.PatientName, d.DepartmentName, r.RoomNumber, b.BedNumber, a.CheckInDate
FROM Admission a
JOIN Patient p    ON a.PatientID = p.PatientID
JOIN Bed b        ON a.BedID = b.BedID
JOIN Room r       ON b.RoomID = r.RoomID
JOIN Department d ON r.DepartmentID = d.DepartmentID
WHERE a.CheckOutDate IS NULL;

-- Q2: Available (free) beds with class and daily cost
SELECT d.DepartmentName, r.RoomNumber, b.BedNumber, bc.ClassName, bc.DailyCost
FROM Bed b
JOIN Room r       ON b.RoomID = r.RoomID
JOIN Department d ON r.DepartmentID = d.DepartmentID
JOIN BedClass bc  ON b.BedClassID = bc.BedClassID
WHERE b.BedID NOT IN (SELECT BedID FROM Admission WHERE CheckOutDate IS NULL)
ORDER BY d.DepartmentName, r.RoomNumber, b.BedNumber;

-- Q3: Total bill per admission (bed charge + services)
SELECT AdmissionID, PatientName, DaysStayed, BedCharge, ServicesTotal, TotalBill
FROM vw_AdmissionBill
ORDER BY AdmissionID;

-- Q4: Patient admission history (change the name in the WHERE clause)
SELECT p.PatientName, a.AdmissionID, a.CheckInDate, a.CheckOutDate,
       CASE WHEN a.CheckOutDate IS NULL THEN N'Admitted' ELSE N'Discharged' END AS Status,
       a.AdmissionReason
FROM Patient p
JOIN Admission a ON p.PatientID = a.PatientID
WHERE p.PatientName LIKE N'%Mohamed%'
ORDER BY a.CheckInDate DESC;

-- Q5: Supervising doctors for each current admission
SELECT p.PatientName, doc.DoctorName, doc.Specialization
FROM Admission a
JOIN Patient p     ON a.PatientID = p.PatientID
JOIN Supervision s ON a.AdmissionID = s.AdmissionID
JOIN Doctor doc    ON s.DoctorID = doc.DoctorID
WHERE a.CheckOutDate IS NULL
ORDER BY p.PatientName;

-- Q6: Services performed for each admission
SELECT p.PatientName, cs.ServiceName, cs.ServiceType, cs.ServiceCost, sr.PerformedAt
FROM ServiceRecord sr
JOIN Admission a        ON sr.AdmissionID = a.AdmissionID
JOIN Patient p          ON a.PatientID = p.PatientID
JOIN ClinicalService cs ON sr.ServiceID = cs.ServiceID
ORDER BY p.PatientName, sr.PerformedAt;

-- Q7: Service revenue summary by service type
SELECT cs.ServiceType, COUNT(*) AS TimesPerformed, SUM(cs.ServiceCost) AS TotalRevenue
FROM ServiceRecord sr
JOIN ClinicalService cs ON sr.ServiceID = cs.ServiceID
GROUP BY cs.ServiceType
ORDER BY TotalRevenue DESC;

-- Q8: Bed occupancy per department
SELECT d.DepartmentName,
       COUNT(b.BedID) AS TotalBeds,
       SUM(CASE WHEN a.AdmissionID IS NOT NULL THEN 1 ELSE 0 END) AS OccupiedBeds,
       SUM(CASE WHEN a.AdmissionID IS NULL THEN 1 ELSE 0 END)     AS FreeBeds
FROM Department d
JOIN Room r ON r.DepartmentID = d.DepartmentID
JOIN Bed b  ON b.RoomID = r.RoomID
LEFT JOIN Admission a ON a.BedID = b.BedID AND a.CheckOutDate IS NULL
GROUP BY d.DepartmentName;

-- Q9: Doctors and their departments
SELECT d.DepartmentName, doc.DoctorName, doc.Specialization
FROM Doctor doc JOIN Department d ON doc.DepartmentID = d.DepartmentID
ORDER BY d.DepartmentName, doc.DoctorName;

-- Q10: Labs and the tests they provide
SELECT l.LabName, l.ManagerName, cs.ServiceName, cs.ServiceCost
FROM Lab l LEFT JOIN ClinicalService cs ON cs.LabID = l.LabID
ORDER BY l.LabName, cs.ServiceName;
GO

/* ===================== 7) DEMO (optional - needs sample data first; IDs below assume it exists) =====================
DECLARE @NewAdm INT;
EXEC sp_AdmitPatient @PatientID = 7, @BedID = 7, @AdmissionReason = N'Appendicitis', @NewAdmissionID = @NewAdm OUTPUT;
EXEC sp_AssignDoctor @AdmissionID = @NewAdm, @DoctorID = 3;
EXEC sp_AssignDoctor @AdmissionID = @NewAdm, @DoctorID = 4;
EXEC sp_AddServiceToAdmission @AdmissionID = @NewAdm, @ServiceID = 1, @Notes = N'Blood count';
EXEC sp_AddServiceToAdmission @AdmissionID = @NewAdm, @ServiceID = 8, @Notes = N'Appendectomy';
SELECT * FROM vw_CurrentInpatients;
SELECT * FROM vw_AdmissionBill WHERE AdmissionID = @NewAdm;
EXEC sp_DischargePatient @AdmissionID = @NewAdm;   -- frees the bed
SELECT * FROM vw_AvailableBeds;
-- Error tests: admitting into an occupied bed must fail
-- EXEC sp_AdmitPatient @PatientID = 8, @BedID = 5, @NewAdmissionID = @NewAdm OUTPUT;
=============================================================================================== */
