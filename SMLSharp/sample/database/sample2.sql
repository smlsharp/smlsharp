CREATE TABLE department (
  id       int primary key,
  name     text not null
);

CREATE TABLE employee (
  name     text not null,
  age      int not null,
  salary   int not null,
  deptid   int not null
);

INSERT INTO department VALUES (1, 'Accounting');
INSERT INTO department VALUES (2, 'Personnel');
INSERT INTO department VALUES (3, 'Development');

INSERT INTO employee VALUES ('Alice',  24, 300, 1);
INSERT INTO employee VALUES ('Bob',    30, 500, 1);
INSERT INTO employee VALUES ('Carol',  26, 550, 1);
INSERT INTO employee VALUES ('Dave',   39, 700, 2);
INSERT INTO employee VALUES ('Eve',    23, 300, 2);
INSERT INTO employee VALUES ('Fran',   31, 450, 2);
INSERT INTO employee VALUES ('Gordon', 21, 250, 3);
INSERT INTO employee VALUES ('Isaac',  28, 500, 3);
INSERT INTO employee VALUES ('Justin', 40, 800, 3);
