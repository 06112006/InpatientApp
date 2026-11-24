-- Inpatient Management System - SQL Server Express / SSMS
-- WARNING: Running this script replaces InpatientDB and all its data.
USE master;
GO
IF DB_ID(N'InpatientDB') IS NOT NULL
BEGIN
 ALTER DATABASE InpatientDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
 DROP DATABASE InpatientDB;
END;
GO
CREATE DATABASE InpatientDB;
GO
USE InpatientDB;
GO
CREATE TABLE Department (DepartmentID INT IDENTITY PRIMARY KEY, DepartmentName NVARCHAR(100) NOT NULL UNIQUE);
CREATE TABLE Doctor (DoctorID INT IDENTITY PRIMARY KEY, DoctorName NVARCHAR(100) NOT NULL, Specialization NVARCHAR(100), DepartmentID INT NOT NULL REFERENCES Department(DepartmentID));
CREATE TABLE Room (RoomID INT IDENTITY PRIMARY KEY, RoomNumber NVARCHAR(10) NOT NULL, DepartmentID INT NOT NULL REFERENCES Department(DepartmentID), UNIQUE(DepartmentID,RoomNumber));
CREATE TABLE BedClass (BedClassID INT IDENTITY PRIMARY KEY, ClassName NVARCHAR(50) NOT NULL UNIQUE, DailyCost DECIMAL(10,2) NOT NULL CHECK(DailyCost>=0));
CREATE TABLE Bed (BedID INT IDENTITY PRIMARY KEY, BedNumber INT NOT NULL, RoomID INT NOT NULL REFERENCES Room(RoomID), BedClassID INT NOT NULL REFERENCES BedClass(BedClassID), UNIQUE(RoomID,BedNumber));
CREATE TABLE Lab (LabID INT IDENTITY PRIMARY KEY, LabName NVARCHAR(100) NOT NULL UNIQUE, ManagerName NVARCHAR(100));
CREATE TABLE ClinicalService (ServiceID INT IDENTITY PRIMARY KEY, ServiceName NVARCHAR(100) NOT NULL UNIQUE, ServiceType NVARCHAR(20) NOT NULL CHECK(ServiceType IN(N'Lab Test',N'Imaging',N'Operation',N'Other')), ServiceCost DECIMAL(10,2) NOT NULL CHECK(ServiceCost>=0), LabID INT REFERENCES Lab(LabID), CHECK(ServiceType<>N'Lab Test' OR LabID IS NOT NULL));
CREATE TABLE Patient (PatientID INT IDENTITY PRIMARY KEY, PatientName NVARCHAR(100) NOT NULL, PatientAddress NVARCHAR(200), Phone NVARCHAR(20));
CREATE TABLE Admission (AdmissionID INT IDENTITY PRIMARY KEY, PatientID INT NOT NULL REFERENCES Patient(PatientID), BedID INT NOT NULL REFERENCES Bed(BedID), CheckInDate DATE NOT NULL, CheckOutDate DATE, AdmissionReason NVARCHAR(200), CHECK(CheckOutDate IS NULL OR CheckOutDate>=CheckInDate));
CREATE UNIQUE INDEX UX_Admission_OpenBed ON Admission(BedID) WHERE CheckOutDate IS NULL;
CREATE UNIQUE INDEX UX_Admission_OpenPatient ON Admission(PatientID) WHERE CheckOutDate IS NULL;
CREATE TABLE Supervision (AdmissionID INT NOT NULL REFERENCES Admission(AdmissionID), DoctorID INT NOT NULL REFERENCES Doctor(DoctorID), PRIMARY KEY(AdmissionID,DoctorID));
CREATE TABLE ServiceRecord (ServiceRecordID INT IDENTITY PRIMARY KEY, AdmissionID INT NOT NULL REFERENCES Admission(AdmissionID), ServiceID INT NOT NULL REFERENCES ClinicalService(ServiceID), PerformedAt DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(), Notes NVARCHAR(300));
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT Department(DepartmentName) VALUES (N'Cardiology'),(N'General Surgery'),(N'Pediatrics'),(N'Orthopedics');
INSERT Doctor(DoctorName,Specialization,DepartmentID) VALUES
(N'Dr. Ahmed Hassan',N'Cardiologist',1),(N'Dr. Mona Saleh',N'Cardiac Surgeon',1),(N'Dr. Khaled Mostafa',N'General Surgeon',2),(N'Dr. Sara Adel',N'Laparoscopic Surgeon',2),(N'Dr. Omar Fathy',N'Pediatrician',3),(N'Dr. Heba Nabil',N'Neonatologist',3),(N'Dr. Tarek Samir',N'Orthopedic Surgeon',4),(N'Dr. Dina Ashraf',N'Rehabilitation Doctor',4);
INSERT Room(RoomNumber,DepartmentID) VALUES (N'101',1),(N'102',1),(N'201',2),(N'202',2),(N'301',3),(N'302',3),(N'401',4),(N'402',4);
INSERT BedClass(ClassName,DailyCost) VALUES (N'General',300),(N'Semi-Private',600),(N'Private',1200);
INSERT Bed(RoomID,BedNumber,BedClassID) VALUES (1,1,1),(1,2,1),(2,1,2),(2,2,2),(3,1,1),(3,2,1),(4,1,3),(4,2,2),(5,1,1),(5,2,1),(6,1,2),(6,2,2),(7,1,1),(7,2,1),(8,1,3),(8,2,2);
INSERT Lab(LabName,ManagerName) VALUES (N'Central Laboratory',N'Dr. Wael Ibrahim'),(N'Hematology Laboratory',N'Dr. Nadia Farouk'),(N'Microbiology Laboratory',N'Dr. Essam Lotfy');
INSERT ClinicalService(ServiceName,ServiceType,ServiceCost,LabID) VALUES
(N'Complete Blood Count',N'Lab Test',80,2),(N'Blood Glucose Test',N'Lab Test',40,1),(N'Liver Function Test',N'Lab Test',150,1),(N'Urine Culture',N'Lab Test',120,3),(N'Chest X-Ray',N'Imaging',200,NULL),(N'CT Scan',N'Imaging',900,NULL),(N'MRI',N'Imaging',1500,NULL),(N'Appendectomy',N'Operation',12000,NULL),(N'Knee Arthroscopy',N'Operation',18000,NULL),(N'Cardiac Catheterization',N'Operation',25000,NULL),(N'Physiotherapy Session',N'Other',250,NULL);
INSERT Patient(PatientName,PatientAddress,Phone) VALUES
(N'Mohamed Ali',N'12 Tahrir St, Cairo',N'01012345678'),(N'Fatma Hussein',N'5 Nasr City, Cairo',N'01123456789'),(N'Youssef Ibrahim',N'8 Haram St, Giza',N'01234567890'),(N'Nourhan Samy',N'20 Corniche, Alexandria',N'01098765432'),(N'Ali Mahmoud',N'3 Maadi, Cairo',N'01187654321'),(N'Salma Khaled',N'14 Mohandessin, Giza',N'01276543210'),(N'Hassan Gamal',N'9 Heliopolis, Cairo',N'01055556666'),(N'Mariam Tamer',N'30 Zamalek, Cairo',N'01166667777');
INSERT Admission(PatientID,BedID,CheckInDate,CheckOutDate,AdmissionReason) VALUES
(1,1,'2026-11-01','2026-11-06',N'Chest pain'),(2,5,'2026-11-10',NULL,N'Appendicitis'),(3,9,'2026-11-15',NULL,N'Pneumonia'),(4,13,'2026-11-18',NULL,N'Leg fracture'),(1,3,'2026-11-20',NULL,N'Arrhythmia (readmission)'),(5,7,'2026-10-20','2026-10-25',N'Gallbladder surgery'),(6,11,'2026-11-22',NULL,N'High fever in child');
INSERT Supervision VALUES (1,1),(1,2),(2,3),(2,4),(3,5),(4,7),(4,8),(5,1),(6,3),(7,5),(7,6);
INSERT ServiceRecord(AdmissionID,ServiceID,PerformedAt,Notes) VALUES
(1,5,'2026-11-01T10:30:00',N'Chest X-ray on arrival'),(1,2,'2026-11-02T09:00:00',N'Fasting glucose'),(2,1,'2026-11-10T11:00:00',N'Pre-operative blood count'),(2,8,'2026-11-11T08:00:00',N'Appendectomy completed'),(3,5,'2026-11-15T12:00:00',N'Pneumonia confirmation'),(3,4,'2026-11-16T09:30:00',N'Urine culture'),(4,7,'2026-11-18T15:00:00',N'MRI of the leg'),(4,9,'2026-11-19T08:30:00',N'Arthroscopy'),(4,11,'2026-11-21T10:00:00',N'First physiotherapy session'),(5,10,'2026-11-21T09:00:00',N'Cardiac catheterization'),(6,3,'2026-10-20T10:00:00',N'Liver function before surgery'),(7,1,'2026-11-22T13:00:00',N'Blood count');
COMMIT;
GO
CREATE VIEW vw_CurrentInpatients AS SELECT a.AdmissionID,p.PatientID,p.PatientName,d.DepartmentName,r.RoomNumber,b.BedNumber,bc.ClassName AS BedClass,a.CheckInDate,CASE WHEN DATEDIFF(day,a.CheckInDate,CAST(GETDATE() AS date))<1 THEN 1 ELSE DATEDIFF(day,a.CheckInDate,CAST(GETDATE() AS date)) END AS DaysStayed,a.AdmissionReason FROM Admission a JOIN Patient p ON a.PatientID=p.PatientID JOIN Bed b ON a.BedID=b.BedID JOIN BedClass bc ON b.BedClassID=bc.BedClassID JOIN Room r ON b.RoomID=r.RoomID JOIN Department d ON r.DepartmentID=d.DepartmentID WHERE a.CheckOutDate IS NULL;
GO
CREATE VIEW vw_AvailableBeds AS SELECT b.BedID,d.DepartmentName,r.RoomNumber,b.BedNumber,bc.ClassName AS BedClass,bc.DailyCost FROM Bed b JOIN Room r ON b.RoomID=r.RoomID JOIN Department d ON r.DepartmentID=d.DepartmentID JOIN BedClass bc ON b.BedClassID=bc.BedClassID WHERE NOT EXISTS(SELECT 1 FROM Admission a WHERE a.BedID=b.BedID AND a.CheckOutDate IS NULL);
GO
CREATE VIEW vw_AdmissionBill AS SELECT a.AdmissionID,p.PatientName,a.CheckInDate,a.CheckOutDate,x.DaysStayed,bc.DailyCost,x.DaysStayed*bc.DailyCost AS BedCharge,ISNULL(s.ServicesTotal,0) AS ServicesTotal,x.DaysStayed*bc.DailyCost+ISNULL(s.ServicesTotal,0) AS TotalBill FROM Admission a JOIN Patient p ON a.PatientID=p.PatientID JOIN Bed b ON a.BedID=b.BedID JOIN BedClass bc ON b.BedClassID=bc.BedClassID CROSS APPLY(SELECT CASE WHEN DATEDIFF(day,a.CheckInDate,ISNULL(a.CheckOutDate,CAST(GETDATE() AS date)))<1 THEN 1 ELSE DATEDIFF(day,a.CheckInDate,ISNULL(a.CheckOutDate,CAST(GETDATE() AS date))) END AS DaysStayed)x OUTER APPLY(SELECT SUM(cs.ServiceCost) AS ServicesTotal FROM ServiceRecord sr JOIN ClinicalService cs ON sr.ServiceID=cs.ServiceID WHERE sr.AdmissionID=a.AdmissionID)s;
GO
CREATE PROCEDURE sp_AdmitPatient @PatientID INT,@BedID INT,@CheckInDate DATE=NULL,@AdmissionReason NVARCHAR(200)=NULL,@NewAdmissionID INT OUTPUT AS BEGIN SET NOCOUNT ON; IF @CheckInDate IS NULL SET @CheckInDate=CAST(GETDATE() AS date); IF EXISTS(SELECT 1 FROM Admission WHERE BedID=@BedID AND CheckOutDate IS NULL) THROW 50001,'This bed is already occupied.',1; IF EXISTS(SELECT 1 FROM Admission WHERE PatientID=@PatientID AND CheckOutDate IS NULL) THROW 50002,'This patient already has an open admission.',1; INSERT Admission(PatientID,BedID,CheckInDate,AdmissionReason) VALUES(@PatientID,@BedID,@CheckInDate,@AdmissionReason); SET @NewAdmissionID=SCOPE_IDENTITY(); END;
GO
CREATE PROCEDURE sp_DischargePatient @AdmissionID INT,@CheckOutDate DATE=NULL AS BEGIN SET NOCOUNT ON; IF @CheckOutDate IS NULL SET @CheckOutDate=CAST(GETDATE() AS date); UPDATE Admission SET CheckOutDate=@CheckOutDate WHERE AdmissionID=@AdmissionID AND CheckOutDate IS NULL; IF @@ROWCOUNT=0 THROW 50003,'Admission not found or patient already discharged.',1; END;
GO
CREATE PROCEDURE sp_AssignDoctor @AdmissionID INT,@DoctorID INT AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM Supervision WHERE AdmissionID=@AdmissionID AND DoctorID=@DoctorID) THROW 50004,'This doctor already supervises this admission.',1; INSERT Supervision VALUES(@AdmissionID,@DoctorID); END;
GO
CREATE PROCEDURE sp_AddServiceToAdmission @AdmissionID INT,@ServiceID INT,@Notes NVARCHAR(300)=NULL AS BEGIN SET NOCOUNT ON; INSERT ServiceRecord(AdmissionID,ServiceID,Notes) VALUES(@AdmissionID,@ServiceID,@Notes); END;
GO
-- Display all populated tables in SSMS Results to Grid.
SELECT * FROM Department ORDER BY DepartmentID;
SELECT * FROM Doctor ORDER BY DoctorID;
SELECT * FROM Room ORDER BY RoomID;
SELECT * FROM BedClass ORDER BY BedClassID;
SELECT * FROM Bed ORDER BY BedID;
SELECT * FROM Lab ORDER BY LabID;
SELECT * FROM ClinicalService ORDER BY ServiceID;
SELECT * FROM Patient ORDER BY PatientID;
SELECT * FROM Admission ORDER BY AdmissionID;
SELECT * FROM Supervision ORDER BY AdmissionID,DoctorID;
SELECT * FROM ServiceRecord ORDER BY ServiceRecordID;
GO
-- Q1-Q10
SELECT PatientName,DepartmentName,RoomNumber,BedNumber,CheckInDate FROM vw_CurrentInpatients;
SELECT DepartmentName,RoomNumber,BedNumber,BedClass AS ClassName,DailyCost FROM vw_AvailableBeds ORDER BY DepartmentName,RoomNumber,BedNumber;
SELECT AdmissionID,PatientName,DaysStayed,BedCharge,ServicesTotal,TotalBill FROM vw_AdmissionBill ORDER BY AdmissionID;
SELECT p.PatientName,a.AdmissionID,a.CheckInDate,a.CheckOutDate,CASE WHEN a.CheckOutDate IS NULL THEN N'Admitted' ELSE N'Discharged' END AS Status,a.AdmissionReason FROM Patient p JOIN Admission a ON p.PatientID=a.PatientID WHERE p.PatientName LIKE N'%Mohamed%' ORDER BY a.CheckInDate DESC;
SELECT p.PatientName,doc.DoctorName,doc.Specialization FROM Admission a JOIN Patient p ON a.PatientID=p.PatientID JOIN Supervision s ON a.AdmissionID=s.AdmissionID JOIN Doctor doc ON s.DoctorID=doc.DoctorID WHERE a.CheckOutDate IS NULL ORDER BY p.PatientName;
SELECT p.PatientName,cs.ServiceName,cs.ServiceType,cs.ServiceCost,sr.PerformedAt FROM ServiceRecord sr JOIN Admission a ON sr.AdmissionID=a.AdmissionID JOIN Patient p ON a.PatientID=p.PatientID JOIN ClinicalService cs ON sr.ServiceID=cs.ServiceID ORDER BY p.PatientName,sr.PerformedAt;
SELECT cs.ServiceType,COUNT(*) AS TimesPerformed,SUM(cs.ServiceCost) AS TotalRevenue FROM ServiceRecord sr JOIN ClinicalService cs ON sr.ServiceID=cs.ServiceID GROUP BY cs.ServiceType ORDER BY TotalRevenue DESC;
SELECT d.DepartmentName,COUNT(b.BedID) AS TotalBeds,SUM(CASE WHEN a.AdmissionID IS NOT NULL THEN 1 ELSE 0 END) AS OccupiedBeds,SUM(CASE WHEN a.AdmissionID IS NULL THEN 1 ELSE 0 END) AS FreeBeds FROM Department d JOIN Room r ON r.DepartmentID=d.DepartmentID JOIN Bed b ON b.RoomID=r.RoomID LEFT JOIN Admission a ON a.BedID=b.BedID AND a.CheckOutDate IS NULL GROUP BY d.DepartmentName;
SELECT d.DepartmentName,doc.DoctorName,doc.Specialization FROM Doctor doc JOIN Department d ON doc.DepartmentID=d.DepartmentID ORDER BY d.DepartmentName,doc.DoctorName;
SELECT l.LabName,l.ManagerName,cs.ServiceName,cs.ServiceCost FROM Lab l LEFT JOIN ClinicalService cs ON cs.LabID=l.LabID ORDER BY l.LabName,cs.ServiceName;
GO
