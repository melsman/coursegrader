
drop sequence vu_person_id_sequence;
drop sequence vu_course_id_sequence;
drop sequence vu_problemset_id_sequence;
drop sequence vu_problem_id_sequence;

drop table vu_turn_in;
drop table vu_problemsets_grade;
drop table vu_grade_range;
drop table vu_problem_solution;
drop table vu_problem;
drop table vu_problemset;
drop table vu_grading_group;
drop table vu_student;
drop table vu_course_assistant;
drop table vu_course;
drop table vu_person;
drop table vu_semester;

create table vu_semester (
  semester char(5) primary key
);

insert into vu_semester (semester) values ('F1999');
insert into vu_semester (semester) values ('E1999');
insert into vu_semester (semester) values ('F2000');
insert into vu_semester (semester) values ('E2000');
insert into vu_semester (semester) values ('F2001');
insert into vu_semester (semester) values ('E2001');
insert into vu_semester (semester) values ('F2002');
insert into vu_semester (semester) values ('E2002');
insert into vu_semester (semester) values ('F2003');
insert into vu_semester (semester) values ('E2003');
insert into vu_semester (semester) values ('F2004');
insert into vu_semester (semester) values ('E2004');
insert into vu_semester (semester) values ('F2005');
insert into vu_semester (semester) values ('E2005');
insert into vu_semester (semester) values ('F2006');
insert into vu_semester (semester) values ('E2006');
insert into vu_semester (semester) values ('F2007');
insert into vu_semester (semester) values ('E2007');
insert into vu_semester (semester) values ('F2008');
insert into vu_semester (semester) values ('E2008');
insert into vu_semester (semester) values ('F2009');
insert into vu_semester (semester) values ('E2009');
insert into vu_semester (semester) values ('F2010');
insert into vu_semester (semester) values ('E2010');
insert into vu_semester (semester) values ('F2011');
insert into vu_semester (semester) values ('E2011');
insert into vu_semester (semester) values ('F2012');
insert into vu_semester (semester) values ('E2012');
insert into vu_semester (semester) values ('F2013');
insert into vu_semester (semester) values ('E2013');
insert into vu_semester (semester) values ('F2014');
insert into vu_semester (semester) values ('E2014');
insert into vu_semester (semester) values ('F2015');
insert into vu_semester (semester) values ('E2015');
insert into vu_semester (semester) values ('F2016');
insert into vu_semester (semester) values ('E2016');

create table vu_person (
  person_id integer primary key,
  email varchar(100) unique,
  name varchar(100) not null,
  password varchar(100) not null
);

create sequence vu_person_id_sequence start with 1;

insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'mael@itu.dk', 'Martin Elsman', 'ITU');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'paulin@itu.dk', 'John Paulin', 'dfdf3');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'nh@itu.dk', 'Niels Hallenberg', '34fsd');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'designco@post4.tele.dk', 'Klaus Bjerager', 'dfs3r');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'kenneth@itu.dk', 'Kenneth Riis', '234fdf');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'za@itu.dk', 'Zia Ashraf', 'sdfsg43');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'barkhuus@itu.dk', 'Louise Barkhuus', 'sdfpo9');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'susb@itu.dk', 'Susanne Bendixen', 'ds9983');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'kaspar@itu.dk', 'Kaspar Bøcher', 'cnfd3');
insert into vu_person (person_id, email, name, password)
values (vu_person_id_sequence.nextval, 'iwc@itu.dk', 'Ida Wang Carlsen', 'dq33');


create table vu_course (
   course_id     integer primary key,
   course_name   varchar(100) not null,
   course_url    varchar(100),
   semester      references vu_semester,
   responsible   references vu_person
);

create sequence vu_course_id_sequence start with 1;

insert into vu_course (course_id, course_name, course_url, semester, responsible)
values (vu_course_id_sequence.nextval, 'Webdesign I', 'http://www.itu.dk/courses/W1/F2000/Webdesign1.html', 'F2000', 2);
insert into vu_course (course_id, course_name, course_url, semester, responsible)
values (vu_course_id_sequence.nextval, 'Webdesign II', 'http://www.itu.dk/courses/W2/F2000/', 'F2000', 1);
insert into vu_course (course_id, course_name, course_url, semester, responsible)
values (vu_course_id_sequence.nextval, 'Grafisk Design', 'http://www.itu.dk/courses/GD/F2000/Grafisk_Design.html', 'F2000', 4);
insert into vu_course (course_id, course_name, course_url, semester, responsible)
values (vu_course_id_sequence.nextval, 'Grundlæggende Programmering', 'http://www.itu.dk/courses/GP/F2000/', 'F2000', 3);

alter table vu_course add 
(grading_visibility varchar(100) default 'responsible' 
 check (grading_visibility in ('responsible', 'assistant')));


create table vu_course_assistant (
  course_id references vu_course,
  person_id references vu_person,
  unique(course_id,person_id) -- there can be more than one assistant for each course
);

insert into vu_course_assistant (course_id, person_id)
values (2, 5);


create table vu_student (
  person_id references vu_person,
  course_id references vu_course,
  unique(person_id, course_id)
);
  
insert into vu_student (person_id, course_id)
values (6, 2);
insert into vu_student (person_id, course_id)
values (7, 2);

-- table to be modified only by course administrators and used to calculate 
-- a grade for each student - I wonder how big this select is going to be...
create table vu_grading_group (
  name               varchar(100),
  course_id          references vu_course,
  primary key        (name,course_id),
  -- the weight of this grading group given in percent
  weight             integer check (weight >= 0 and weight <= 100),
  -- if NULL then all problem sets in the vu_grading_group_item for this 
  -- group counts
  items_that_counts  integer check (items_that_counts >= 0),
  turn_in_service    char(1) check (turn_in_service in ('t', 'f'))
);

-- table, to be altered only by course responsible
create table vu_problemset (
  problemset_id integer primary key,
  course_id references vu_course,  
  problemset_name varchar(100),
  grading_group varchar(100),
  unique(problemset_name, course_id)
);

create sequence vu_problemset_id_sequence start with 1; 

insert into vu_problemset (problemset_id, course_id, problemset_name, grading_group)
values (vu_problemset_id_sequence.nextval, 2, '1', 'Problem set');
insert into vu_problemset (problemset_id, course_id, problemset_name, grading_group)
values (vu_problemset_id_sequence.nextval, 2, '2', 'Problem set');

-- table, to be altered only by course responsible
create table vu_problem (
  problem_id integer primary key,
  problemset_id references vu_problemset,
  problem_name varchar(20),
  maxpoint integer,
  unique(problem_name, problemset_id)
);

create sequence vu_problem_id_sequence start with 1; 

insert into vu_problem (problem_id, problemset_id, problem_name, maxpoint)
values (vu_problem_id_sequence.nextval, 1, 'A', 20);
insert into vu_problem (problem_id, problemset_id, problem_name, maxpoint)
values (vu_problem_id_sequence.nextval, 1, 'B', 30);
insert into vu_problem (problem_id, problemset_id, problem_name, maxpoint)
values (vu_problem_id_sequence.nextval, 1, 'C', 15);
insert into vu_problem (problem_id, problemset_id, problem_name, maxpoint)
values (vu_problem_id_sequence.nextval, 1, 'D', 0);
insert into vu_problem (problem_id, problemset_id, problem_name, maxpoint)
values (vu_problem_id_sequence.nextval, 1, 'E', 15);
insert into vu_problem (problem_id, problemset_id, problem_name, maxpoint)
values (vu_problem_id_sequence.nextval, 1, 'F', 20);

-- entries can be edited by course responsible and assistant when the rigid flag is 'f'
create table vu_problem_solution (
   problem_id references vu_problem,
   person_id references vu_person,
   text varchar(1000),
   grade integer,
   -- rigid problem solution can be edited only by course responsible - not by assistant
   rigid char(1) default 'f' check(rigid in ('t', 'f')),
   last_changed_by references vu_person,
   last_changed_date date,
   unique(problem_id,person_id) -- each student can be associated with only one problem
);

alter table vu_problem_solution
modify text varchar(4000);

-- Grading Policy

-- a range [3,4[ is modeled as (first=3,last=3.5), a 
-- range ]10,20] is modeled as (first=10.5,last=20).
create table vu_grade_range (
       course_id references vu_course,
       first number,
       last number,
       grade varchar(100),
       unique(course_id, first, last),       
       constraint vu_grade_range
       check (last >= 0 and last <= 100 and first >= 0 
	      and first <= 100 and last >= first)
);
       
create table vu_problemsets_grade (
       course_id references vu_course primary key,
       text varchar(4000),
       which_to_grade integer
);

-- Turn-in service; each student can be associated with 
-- multiple messages for each problemset

create table vu_turn_in (
       person_id        references vu_person,
       course_id        references vu_course,
       problemset_id    references vu_problemset,
       -- some text provided by the student - perhaps the answers!
       text             varchar(4000),
       -- the date of the insertion
       insdate          date,
       -- a course responsible can delete a users turn-in message,
       -- which turns the status back to ``not turned-in'' and allows
       -- the student to turn in the problem set later.
       deleted_date     date
);

alter table vu_turn_in
add pg_num integer;

update vu_turn_in
set pg_num = 0;


create or replace function average_grade_n (n integer, 
                                            cid integer, 
                                            pid integer,
                                            ggroup varchar2)
  return number
  is
    mysum number;
    counter integer;
    res number;

    cursor grades is
       select sum(vu_problem_solution.grade) as total
       from vu_problemset, 
	    vu_problem_solution, 
	    vu_problem
       where vu_problem.problemset_id = vu_problemset.problemset_id
	 and vu_problem.problem_id = vu_problem_solution.problem_id (+)
	 and vu_problemset.course_id = cid
	 and vu_problem_solution.person_id (+) = pid
	 and vu_problemset.grading_group (+) = ggroup
	 and vu_problem_solution.grade is not null
       group by vu_problemset.problemset_id, 
		vu_problemset.course_id, 
		vu_problem_solution.person_id
       order by total desc;         
  begin
    mysum := 0.0;
    counter := 0;
    for grades_rec in grades
    loop 
      if counter = n then exit;
      end if;
      counter := counter + 1;
      mysum := mysum + grades_rec.total;
    end loop;
    if counter = 0 then res := 0.0;
    else res := mysum / n; 
    end if;
    return res;
  end;
/
-- show errors;


create or replace function vu_course_total (cid integer, 
                                            pid integer)
  return number
  is
   mysum number;
  begin
   select SUM((vu_grading_group.weight / 100) *
                  average_grade_n(vu_grading_group.items_that_counts, 
                                  cid,
                                  pid, 
                                  vu_grading_group.name))
   into mysum
   from vu_grading_group
   where vu_grading_group.course_id (+) = cid;
   
   return trunc(mysum,2);
  end;
/
-- show errors;


create or replace function vu_course_grade (cid integer, 
                                            pid integer)
  return varchar2
  is
   course_total number;
   thegrade varchar2(100);
  begin
   course_total := vu_course_total(cid,pid);

   select vu_grade_range.grade
   into thegrade
   from vu_grade_range
   where (vu_grade_range.first < ceil(course_total) or vu_grade_range.first = course_total)
   and (vu_grade_range.last > floor(course_total) or vu_grade_range.last = course_total)
   and vu_grade_range.course_id = cid;

   return thegrade;
  end;
/
-- show errors;


-- for use by students, we do not include information that appears in
-- flexible (non-rigid) problem-solutions

create or replace function vu_average_grade_n_rigid (n integer, 
                                                     cid integer, 
                                                     pid integer,
                                                     ggroup varchar2)
  return number
  is
    mysum integer;
    counter integer;

    cursor grades is
       select vu_problemset.problemset_id, sum(vu_problem_solution.grade) as total
       from vu_problemset, 
	    vu_problem_solution, 
	    vu_problem
       where vu_problem.problemset_id = vu_problemset.problemset_id
	 and vu_problem.problem_id = vu_problem_solution.problem_id (+)
	 and vu_problemset.course_id = cid
	 and vu_problem_solution.person_id (+) = pid
	 and vu_problemset.grading_group (+) = ggroup
       group by vu_problemset.problemset_id
       having not exists (select * 
                          from vu_problem_solution, vu_problem
                          where vu_problem_solution.person_id = pid
                            and vu_problem_solution.rigid='f'
                            and vu_problem_solution.problem_id = vu_problem.problem_id
                            and vu_problem.problemset_id = vu_problemset.problemset_id)
       order by total desc;         
  begin
    mysum := 0;
    counter := 0;
    for grades_rec in grades
    loop 
      if counter = n then exit;
      end if;
      counter := counter + 1;
      mysum := mysum + grades_rec.total;
    end loop;
    if counter = 0 then return 0;
    else return mysum / counter; 
    end if;
  end;
/
-- show errors;


create or replace function vu_course_total_rigid (cid integer, 
                                                  pid integer)
  return number
  is
   mysum number;
  begin
   select SUM((vu_grading_group.weight / 100) *
                  vu_average_grade_n_rigid(vu_grading_group.items_that_counts, 
                                           cid,
                                           pid, 
                                           vu_grading_group.name))
   into mysum
   from vu_grading_group
   where vu_grading_group.course_id (+) = cid;
   
   return trunc(mysum,2);
  end;
/
-- show errors;

