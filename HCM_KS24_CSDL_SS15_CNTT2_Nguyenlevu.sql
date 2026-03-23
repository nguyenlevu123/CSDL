create database if not exists HCM_KS24_CSDL_SS15_CNTT2_Nguyenlevu;
use HCM_KS24_CSDL_SS15_CNTT2_Nguyenlevu;

create table Students (
    StudentID CHAR(5) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    TotalDebt DECIMAL(10,2) DEFAULT 0
);

create table Subjects (
    SubjectID CHAR(5) PRIMARY KEY,
    SubjectName VARCHAR(50) NOT NULL,
    Credits INT CHECK (Credits > 0)
);

create table Grades (
    StudentID CHAR(5),
    SubjectID CHAR(5),
    Score DECIMAL(4,2) CHECK (Score BETWEEN 0 AND 10),
    PRIMARY KEY (StudentID, SubjectID),
    foreign key (StudentID) references Students(StudentID),
    foreign key (SubjectID) references Subjects(SubjectID)
);

create table GradeLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    StudentID CHAR(5),
    OldScore DECIMAL(4,2),
    NewScore DECIMAL(4,2),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- Câu 1
DELIMITER $$
create trigger tg_CheckScore
before insert on Grades
for each row
begin
if new.Score < 0 then
set new.Score = 0;
elseif new.Score > 10 then
set new.Score = 10;
end if;
end$$
DELIMITER ;

insert into students (studentid, fullname)
values ('sv01', 'nguyen van a');

insert into subjects (subjectid, subjectname, credits)
values ('mh01', 'co so du lieu', 3);

insert into grades (studentid, subjectid, score)
values ('sv01', 'mh01', -5);
select * from grades;


-- Câu 2
start transaction;
insert into Students (StudentID, FullName)
values ('SV02', 'Ha Bich Ngoc');

update Students
set TotalDebt = 5000000
where StudentID = 'SV02';
commit;

select * from Students where StudentID = 'SV02';

-- Câu 3
delimiter $$

create trigger tg_loggradeupdate
after update on grades
for each row
begin
    if old.score <> new.score then
insert into gradelog (studentid, oldscore, newscore, changedate)
values (old.studentid, old.score, new.score, now());
    end if;
end$$

delimiter ;
update Grades
set Score = 3
where StudentID = 'SV01' and SubjectID = 'MH01';

update Grades
set Score = 6
where StudentID = 'SV01' and SubjectID = 'MH01';

select StudentID, OldScore, NewScore
from GradeLog
order by LogID desc
limit 1;

-- Câu 4
update Students
set TotalDebt = 5000000
where StudentID = 'SV01';


delimiter $$

create procedure sp_paytuition()
begin
declare v_newdebt decimal(10,2);
start transaction;
update students
set totaldebt = totaldebt - 2000000
where studentid = 'sv01';
select totaldebt into v_newdebt
from students
where studentid = 'sv01';
if v_newdebt < 0 then
rollback;
    else
        commit;
    end if;
end$$

delimiter ;
select TotalDebt from Students where StudentID = 'SV01';
call sp_PayTuition();
select TotalDebt from Students where StudentID = 'SV01';


-- Câu 5
delimiter $$

create trigger tg_preventpassupdate
before update on grades
for each row
begin
    if old.score >= 4.0 then
        signal sqlstate '45000'
        set message_text = 'khong duoc phep sua diem khi sinh vien da qua mon';
    end if;
end$$

delimiter ;
update Grades
set Score = 9
where StudentID = 'SV01' and SubjectID = 'MH01';

-- cau 6
delimiter $$

create procedure sp_deletestudentgrade(
    in p_studentid char(5),
    in p_subjectid char(5)
)
begin
    declare v_score decimal(4,2);

    start transaction;

    select score into v_score
    from grades
    where studentid = p_studentid
      and subjectid = p_subjectid;

    if v_score is null then
        rollback;
    else
        insert into gradelog (studentid, oldscore, newscore, changedate)
        values (p_studentid, v_score, null, now());

        delete from grades
        where studentid = p_studentid
          and subjectid = p_subjectid;

        commit;
    end if;
end;

delimiter ;
call sp_DeleteStudentGrade('SV01', 'MH01');

select * from Grades
where StudentID = 'SV01' and SubjectID = 'MH01';

