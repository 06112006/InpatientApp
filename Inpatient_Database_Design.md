# Inpatient Management System: Database Design

## 1. System Overview
| Aspect | Details |
|---|---|
| Project name | Inpatient Management System |
| Domain | Healthcare / Hospital management |
| Idea | A database that manages hospital departments, doctors, rooms and beds, patient admissions and discharges, and the lab tests, imaging and operations performed during each stay. |
| Target users | Reception, nursing staff, administrators |
| Scope | Patient registration, admission and bed allocation, doctor supervision, services and billing, discharge, search and reports |
| Tools | Microsoft SQL Server + SSMS (DBMS), Graphviz/Draw.io (ERD), Word |

## 2. System Requirements (numbered, for Section 1.5 of the blueprint)
1. **Department:** each department has a unique DepartmentID and a name, contains a set of rooms, and employs a set of doctors.
2. **Doctor:** each doctor has a unique DoctorID, a name and a specialization, and belongs to exactly one department.
3. **Room:** each room has a unique RoomID and a room number (unique within its department), and belongs to one department.
4. **Bed and BedClass:** each bed has a BedNumber (unique within its room) and belongs to one room. Each bed has a class (General, Semi-Private, Private) with a non-negative daily cost.
5. **Patient:** each patient has a unique PatientID, a name, an address and a phone number, and may have many admissions over time.
6. **Admission:** each admission links one patient to exactly one bed, with a check-in date and an optional check-out date. A filled check-out date means the patient was discharged.
7. **Supervision:** an admission can be supervised by several doctors, and a doctor can supervise many admissions.
8. **Lab and ClinicalService:** each lab has a unique LabID, a name and a manager. A lab offers a set of lab tests. Imaging and operations are other service types. Every service has a type and a cost.
9. **ServiceRecord:** an admission can have many service records, and each record references one clinical service with the date/time performed.

## 3. Business Rules
| Rule | Definition |
|---|---|
| BR-01 | Each department has a unique ID; each doctor belongs to exactly one department. |
| BR-02 | Each department contains rooms; a room belongs to one department. |
| BR-03 | Each room contains beds; bed numbers are unique within their room. |
| BR-04 | Every bed has a bed class with a defined non-negative daily cost. |
| BR-05 | Each patient has a unique ID and may have multiple admissions over time. |
| BR-06 | Each admission allocates exactly one bed, with a check-in date and an optional check-out date. |
| BR-07 | A bed and a patient cannot each have two simultaneously open admissions. |
| BR-08 | An admission may be supervised by several doctors; a doctor can supervise many admissions. |
| BR-09 | Each lab offers a set of lab-test services; imaging and operations are other service types. |
| BR-10 | An admission can have many service records, each referencing one clinical service. |
| BR-11 | Check-out cannot precede check-in; discharge is a filled CheckOutDate. |

## 4. Entities, Attributes and Keys
| # | Entity | Attributes | PK | FK | Role |
|---|---|---|---|---|---|
| 1 | Department | DepartmentID, DepartmentName | DepartmentID | none | Organizes doctors and rooms |
| 2 | Doctor | DoctorID, DoctorName, Specialization, DepartmentID | DoctorID | DepartmentID → Department | Medical staff |
| 3 | Room | RoomID, RoomNumber, DepartmentID | RoomID | DepartmentID → Department | Physical rooms |
| 4 | BedClass | BedClassID, ClassName, DailyCost | BedClassID | none | Pricing category for beds |
| 5 | Bed | BedID, BedNumber, RoomID, BedClassID | BedID | RoomID → Room, BedClassID → BedClass | Allocatable bed |
| 6 | Lab | LabID, LabName, ManagerName | LabID | none | Labs that provide tests |
| 7 | ClinicalService | ServiceID, ServiceName, ServiceType, ServiceCost, LabID (nullable) | ServiceID | LabID → Lab | Tests, imaging, operations, other |
| 8 | Patient | PatientID, PatientName, PatientAddress, Phone | PatientID | none | Permanent patient data |
| 9 | Admission | AdmissionID, PatientID, BedID, CheckInDate, CheckOutDate, AdmissionReason | AdmissionID | PatientID → Patient, BedID → Bed | One stay of one patient |
| 10 | Supervision | AdmissionID, DoctorID | (AdmissionID, DoctorID) | both FKs | Resolves the M:N doctor–admission relationship |
| 11 | ServiceRecord | ServiceRecordID, AdmissionID, ServiceID, PerformedAt, Notes | ServiceRecordID | AdmissionID → Admission, ServiceID → ClinicalService | Services performed per stay |

## 5. Relationships
| Relationship | Cardinality | Implemented by |
|---|---|---|
| Department has Doctors | 1 : M | Doctor.DepartmentID |
| Department contains Rooms | 1 : M | Room.DepartmentID |
| Room contains Beds | 1 : M | Bed.RoomID |
| BedClass classifies Beds | 1 : M | Bed.BedClassID |
| Patient has Admissions | 1 : M | Admission.PatientID |
| Bed is used in Admissions (over time) | 1 : M | Admission.BedID |
| Doctor supervises Admission | M : N | Supervision table |
| Lab offers Clinical Services (lab tests) | 1 : M (optional) | ClinicalService.LabID (nullable) |
| Admission has Service Records | 1 : M | ServiceRecord.AdmissionID |
| Clinical Service is performed in Service Records | 1 : M | ServiceRecord.ServiceID |

## 6. Relational Schema
- Department(**DepartmentID**, DepartmentName)
- Doctor(**DoctorID**, DoctorName, Specialization, *DepartmentID*)
- Room(**RoomID**, RoomNumber, *DepartmentID*)
- BedClass(**BedClassID**, ClassName, DailyCost)
- Bed(**BedID**, BedNumber, *RoomID*, *BedClassID*)
- Lab(**LabID**, LabName, ManagerName)
- ClinicalService(**ServiceID**, ServiceName, ServiceType, ServiceCost, *LabID* NULL)
- Patient(**PatientID**, PatientName, PatientAddress, Phone)
- Admission(**AdmissionID**, *PatientID*, *BedID*, CheckInDate, CheckOutDate, AdmissionReason)
- Supervision(**AdmissionID**, **DoctorID**) (both are FKs)
- ServiceRecord(**ServiceRecordID**, *AdmissionID*, *ServiceID*, PerformedAt, Notes)

(Bold = primary key, italic = foreign key.)

## 7. Integrity Constraints in SQL Server
| Constraint | How it is enforced |
|---|---|
| Unique department name, bed class name, lab name, service name | UNIQUE |
| Room number unique within a department | UNIQUE (DepartmentID, RoomNumber) |
| Bed number unique within a room | UNIQUE (RoomID, BedNumber) |
| DailyCost ≥ 0, ServiceCost ≥ 0 | CHECK |
| ServiceType in (Lab Test, Imaging, Operation, Other) | CHECK |
| A Lab Test must belong to a lab | CHECK (ServiceType <> 'Lab Test' OR LabID IS NOT NULL) |
| CheckOutDate ≥ CheckInDate | CHECK |
| One open admission per bed and per patient | Filtered UNIQUE indexes WHERE CheckOutDate IS NULL |
| No orphan rows | FOREIGN KEY constraints |

## 8. Normalization Notes
- Doctors per admission are stored in Supervision, not as a repeated field in Admission (1NF).
- Bed-class cost is stored once in BedClass, not repeated per bed (2NF/3NF).
- Patient data is separated from stay data in Admission, so repeated stays do not duplicate personal data.
- Services are stored in ServiceRecord, so the same service can be performed many times in one stay.

## 9. Queries Included in the Script
1. Current inpatients 2. Available (free) beds 3. Total bill per admission (bed daily cost × days + services) 4. Patient admission history 5. Supervising doctors of current admissions 6. Services performed per patient 7. Service revenue by type 8. Bed occupancy per department 9. Doctors by department 10. Labs and their tests.

Also: views `vw_CurrentInpatients`, `vw_AvailableBeds`, `vw_AdmissionBill` and procedures `sp_AdmitPatient`, `sp_DischargePatient`, `sp_AssignDoctor`, `sp_AddServiceToAdmission`.

## 10. Design Assumptions
- Beds use an internal BedID plus a room-specific BedNumber, because the instructor asked for rooms.
- A patient has one bed per admission. Transfers during a stay would need a BedAssignment history table.
- ManagerName is an attribute of Lab, since no separate employee entity is defined.
- The number of doctors per admission is not limited by the source, so zero or more are allowed.
- Bill = bed daily cost × days stayed (minimum 1 day; open stays count to today) + the cost of all services.
