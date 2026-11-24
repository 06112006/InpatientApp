/* =====================================================================
   Inpatient Management System | Sample Data (DML)
   Run AFTER Inpatient_System_SQL_Server.sql (which creates InpatientDB).
   Safe to run once: if data already exists the script skips itself.
   ===================================================================== */

USE InpatientDB;
GO

IF EXISTS (SELECT 1 FROM Department)
BEGIN
    PRINT 'Sample data already exists - nothing inserted.';
    SET NOEXEC ON;
END
GO

INSERT INTO Department (DepartmentName) VALUES
 (N'Cardiology'), (N'General Surgery'), (N'Pediatrics'), (N'Orthopedics');

INSERT INTO Doctor (DoctorName, Specialization, DepartmentID) VALUES
 (N'Dr. Ahmed Hassan',   N'Cardiologist',          1),
 (N'Dr. Mona Saleh',     N'Cardiac Surgeon',       1),
 (N'Dr. Khaled Mostafa', N'General Surgeon',       2),
 (N'Dr. Sara Adel',      N'Laparoscopic Surgeon',  2),
 (N'Dr. Omar Fathy',     N'Pediatrician',          3),
 (N'Dr. Heba Nabil',     N'Neonatologist',         3),
 (N'Dr. Tarek Samir',    N'Orthopedic Surgeon',    4),
 (N'Dr. Dina Ashraf',    N'Rehabilitation Doctor', 4);

INSERT INTO Room (RoomNumber, DepartmentID) VALUES
 (N'101',1), (N'102',1), (N'201',2), (N'202',2),
 (N'301',3), (N'302',3), (N'401',4), (N'402',4);

INSERT INTO BedClass (ClassName, DailyCost) VALUES
 (N'General', 300.00), (N'Semi-Private', 600.00), (N'Private', 1200.00);

INSERT INTO Bed (RoomID, BedNumber, BedClassID) VALUES
 (1,1,1),(1,2,1),(2,1,2),(2,2,2),
 (3,1,1),(3,2,1),(4,1,3),(4,2,2),
 (5,1,1),(5,2,1),(6,1,2),(6,2,2),
 (7,1,1),(7,2,1),(8,1,3),(8,2,2);

INSERT INTO Lab (LabName, ManagerName) VALUES
 (N'Central Laboratory',      N'Dr. Wael Ibrahim'),
 (N'Hematology Laboratory',   N'Dr. Nadia Farouk'),
 (N'Microbiology Laboratory', N'Dr. Essam Lotfy');

INSERT INTO ClinicalService (ServiceName, ServiceType, ServiceCost, LabID) VALUES
 (N'Complete Blood Count',    N'Lab Test',   80.00,    2),
 (N'Blood Glucose Test',      N'Lab Test',   40.00,    1),
 (N'Liver Function Test',     N'Lab Test',   150.00,   1),
 (N'Urine Culture',           N'Lab Test',   120.00,   3),
 (N'Chest X-Ray',             N'Imaging',    200.00,   NULL),
 (N'CT Scan',                 N'Imaging',    900.00,   NULL),
 (N'MRI',                     N'Imaging',    1500.00,  NULL),
 (N'Appendectomy',            N'Operation',  12000.00, NULL),
 (N'Knee Arthroscopy',        N'Operation',  18000.00, NULL),
 (N'Cardiac Catheterization', N'Operation',  25000.00, NULL),
 (N'Physiotherapy Session',   N'Other',      250.00,   NULL);

INSERT INTO Patient (PatientName, PatientAddress, Phone) VALUES
 (N'Mohamed Ali',     N'12 Tahrir St, Cairo',     N'01012345678'),
 (N'Fatma Hussein',   N'5 Nasr City, Cairo',      N'01123456789'),
 (N'Youssef Ibrahim', N'8 Haram St, Giza',        N'01234567890'),
 (N'Nourhan Samy',    N'20 Corniche, Alexandria', N'01098765432'),
 (N'Ali Mahmoud',     N'3 Maadi, Cairo',          N'01187654321'),
 (N'Salma Khaled',    N'14 Mohandessin, Giza',    N'01276543210'),
 (N'Hassan Gamal',    N'9 Heliopolis, Cairo',     N'01055556666'),
 (N'Mariam Tamer',    N'30 Zamalek, Cairo',       N'01166667777');

-- Closed stays have a CheckOutDate; open stays have NULL
INSERT INTO Admission (PatientID, BedID, CheckInDate, CheckOutDate, AdmissionReason) VALUES
 (1, 1,  '2026-11-01', '2026-11-06', N'Chest pain'),
 (2, 5,  '2026-11-10', NULL,         N'Appendicitis'),
 (3, 9,  '2026-11-15', NULL,         N'Pneumonia'),
 (4, 13, '2026-11-18', NULL,         N'Leg fracture'),
 (1, 3,  '2026-11-20', NULL,         N'Arrhythmia (readmission)'),
 (5, 7,  '2026-10-20', '2026-10-25', N'Gallbladder surgery'),
 (6, 11, '2026-11-22', NULL,         N'High fever in child');

INSERT INTO Supervision (AdmissionID, DoctorID) VALUES
 (1,1),(1,2),(2,3),(2,4),(3,5),(4,7),(4,8),(5,1),(6,3),(7,5),(7,6);

INSERT INTO ServiceRecord (AdmissionID, ServiceID, PerformedAt, Notes) VALUES
 (1, 5,  '2026-11-01 10:30', N'Chest X-ray on arrival'),
 (1, 2,  '2026-11-02 09:00', N'Fasting glucose'),
 (2, 1,  '2026-11-10 11:00', N'Pre-operative blood count'),
 (2, 8,  '2026-11-11 08:00', N'Appendectomy completed'),
 (3, 5,  '2026-11-15 12:00', N'Pneumonia confirmation'),
 (3, 4,  '2026-11-16 09:30', N'Urine culture'),
 (4, 7,  '2026-11-18 15:00', N'MRI of the leg'),
 (4, 9,  '2026-11-19 08:30', N'Arthroscopy'),
 (4, 11, '2026-11-21 10:00', N'First physiotherapy session'),
 (5, 10, '2026-11-21 09:00', N'Cardiac catheterization'),
 (6, 3,  '2026-10-20 10:00', N'Liver function before surgery'),
 (7, 1,  '2026-11-22 13:00', N'Blood count');
GO

SET NOEXEC OFF;
GO

-- Quick check: row count per table
SELECT 'Department' AS TableName, COUNT(*) AS Rows FROM Department UNION ALL
SELECT 'Doctor', COUNT(*) FROM Doctor UNION ALL
SELECT 'Room', COUNT(*) FROM Room UNION ALL
SELECT 'BedClass', COUNT(*) FROM BedClass UNION ALL
SELECT 'Bed', COUNT(*) FROM Bed UNION ALL
SELECT 'Lab', COUNT(*) FROM Lab UNION ALL
SELECT 'ClinicalService', COUNT(*) FROM ClinicalService UNION ALL
SELECT 'Patient', COUNT(*) FROM Patient UNION ALL
SELECT 'Admission', COUNT(*) FROM Admission UNION ALL
SELECT 'Supervision', COUNT(*) FROM Supervision UNION ALL
SELECT 'ServiceRecord', COUNT(*) FROM ServiceRecord;
GO
