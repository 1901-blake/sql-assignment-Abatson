--2.1a Select all records from the Employee table.
select * from employee;
--2.1b Select all records from the Employee table where last name is King.
select * from employee
where lastname = 'King';
--2.1c Select all records from the Employee table where first name is Andrew and REPORTSTO is NULL.
select * from employee
where firstname = 'Andrew'
and reportsto is null;
--2.2a Select all albums in Album table and sort result set in descending order by title.
select * from album order by title desc;
--2.2b Select first name from Customer and sort result set in ascending order by city
select * from customer order by city asc;
--2.3a Insert two new records into Genre table
insert into genre (genreid, name)
values(26, 'indie/folk');
insert into genre (genreid, name)
values(27, 'EDM');
--2.3b Insert two new records into Employee table
insert into employee
values(9, 'b', 'c', 'mr', 4, null, null, '124', 'm', 'w', 'u', '12345', '5', '45', '@');
insert into employee
values(10, 'b', 'c', 'mrs', 4, null, null, '124', 'm', 'w', 'u', '12345', '5', '45', '@');
--2.3c Insert two new records into Customer table
insert into customer
values(61, 'a', 'b', 'r', '32', 'm', 'w', 'u', '54321', '2', '32', '@', 3);
insert into customer
values(62, 'a', 'b-c', 'r', '32', 'm', 'w', 'u', '54321', '2', '32', '@', 3);
--2.4a Update Aaron Mitchell in Customer table to Robert Walter
update customer set firstname ='Robert', lastname = 'Walter' where firstname = 'Aaron' and lastname = 'Mitchell';
--2.4b Update name of artist in the Artist table “Creedence Clearwater Revival” to “CCR”
update artist set name = 'CCR' where name = 'Creedence Clearwater Revival';
--2.5 Select all invoices with a billing address like T%
select * from invoice 
where billingaddress like 'T%';
--2.6a Select all invoices that have a total between 15 and 50
select * from invoice 
where total between 15 and 50;
--2.6b Select all employees hired between 1st of June 2003 and 1st of March 2004
select * from employee 
where hiredate between '2003-06-01' and '2004-03-01';
--2.7 Delete a record in Customer table where the name is Robert Walter (There may be constraints that rely on this, find out how to resolve them).
--we should just set up the tables with on delete cascade
alter table invoiceline drop constraint fk_invoicelineinvoiceid;
alter table invoice drop constraint fk_invoicecustomerid;
delete from invoiceline
where invoiceid in (select invoiceid from invoice 
	where customerid = (select customerid from customer 
		where firstname = 'Robert' and lastname = 'Walter'));
delete from invoice
where customerid = (select customerid from customer 
	where firstname = 'Robert' and lastname = 'Walter');
delete from customer 
where firstname = 'Robert' and lastname = 'Walter';
alter table invoice add constraint fk_invoicecustomerid
foreign key (customerid) references customer(customerid);
alter table invoiceline add constraint fk_invoicelineinvoiceid
foreign key (invoiceid)references invoice(invoiceid);

--3.1a Create a function that returns the current time.
create or replace function curr_Time() returns timestamp as $$
	select now()::timestamp;
$$ language sql;

select curr_Time();

--3.1b Create a function that returns the length of a mediatype from the mediatype table
create or replace function mtype_length(mtid int) returns int as $$
	select char_length((select name from mediatype where mediatypeid = mtid));
$$ language sql;

select mtype_length(1);
--3.2a Create a function that returns the average total of all invoices
create or replace function avg_invoice() returns numeric(10,2) as $$
	select avg(total) from invoice
$$ language sql;

select avg_invoice();
--3.2b Create a function that returns the most expensive track
create or replace function mexp_track() returns numeric(10,2) as $$
	select max(unitprice) from track
$$ language sql;

select mexp_track();

--3.3 Create a function that returns the average price of invoiceline items in the invoiceline table
create or replace function avg_iline() returns numeric(10,2) as $$
	select avg(unitprice) from invoiceline
$$ language sql;

select avg_iline();
--3.4 Create a function that returns all employees who are born after 1968.
create or replace function after_68() returns setof record as $$
	select * from employee where birthdate > '1968-12-31'
$$ language sql;

select after_68();

--4.1 Create a stored procedure that selects the first and last names of all the employees.
create or replace function empFullName() returns TABLE(firstname text, lastname text) as $$
	select firstname, lastname from employee;
$$ language sql;

--drop function empFullName();

select * from empFullName();

--4.2a Create a stored procedure that updates the personal information of an employee.
create or replace function upd_emp(eid int, lname text, fname text, title text, reportsto int, birthdate timestamp, hiredate timestamp, address text, city text, state text, country text, postalcode text, phone text, fax text, email text) returns void as $$
begin
	update employee set lastname = lname, firstname = fname, title = title, reportsto = reportsto, birthdate = birthdate, hiredate = hiredate, address = address, city = city, state = state, country = county, postalcode = postalcode, phone = phone, fax = fax, email = email
	where employeeid = eid;
end;
$$ language plpgsql;


	
--4.2b Create a stored procedure that returns the managers of an employee.
create or replace function managerfind(eid int) returns record as $$
declare 
	rpt int;
	retrec record;
begin
	select reportsto from employee where eid = employeeid into rpt;
	select * from employee where reportsto = rpt into retrec;
	return retrec;
end;
$$ language plpgsql;

select managerfind(3);

--4.3 Create a stored procedure that returns the name and company of a customer.

create or replace function cname_comp(cid int, out fname text, out lname text, out comp text) returns record as $$
begin
	select firstname, lastname, company into fname, lname, comp from customer where customerid = cid;
end;
$$ language plpgsql;

select cname_comp(5);

--5.1 Create a transaction that given a invoiceId will delete that invoice (There may be constraints that rely on this, find out how to resolve them).
create or replace function delInvoice(invid int)returns void as $$
begin
	alter table invoiceline drop constraint fk_invoicelineinvoiceid;
	delete from invoice where invoiceid = invid;
	delete from invoiceline where invoiceid = invid;
	alter table invoiceline add constraint fk_invoicelineinvoiceid
	foreign key (invoiceid) references invoice(invoiceid);
end;
$$ language plpgsql;

select delInvoice(2);

--5.2 Create a transaction nested within a stored procedure that inserts a new record in the Customer table
create or replace function insertCustomer(idnumber int, lname text, fname text, company text, addr text, city text, state text, country text, pcode text, phone text,fax text, email text, suprepid int) 
returns void as $$
  	begin
        insert into customer (customerid, lastname, firstname, company, address, city, state, country, postalcode, phone, fax, email, supportrepid)
        values(idnumber, lname, fname, company, addr, city, state, country, pcode, phone, fax, email, suprepid);
	end;
$$ language plpgsql;

select insertCustomer(60, 'a', 'b', 'r', '1233 t', 'm', 'w', 'r', 't', 'u', 'l', 'k', 3);
-----6.0
create or replace function dummyFunction() returns trigger as $$
begin
	return new;
end;
$$ language plpgsql;

--drop function dummyFunction();
--6.1a Create an after insert trigger on the employee table fired after a new record is inserted into the table.

create trigger after_insert_employee
after insert on employee
for each row
execute procedure dummyFunction();

--6.1b Create an after update trigger on the album table that fires after a row is inserted in the table
create trigger after_update_album
after update on album
for each row
execute procedure dummyFunction();
--6.1c Create an after delete trigger on the customer table that fires after a row is deleted from the table.

create trigger after_delete_customer
after delete on customer
for each row
execute procedure dummyFunction();

--7.1 Create an inner join that joins customers and orders and specifies the name of the customer and the invoiceId.
Select I.invoiceid as "invoiceid", C.firstname as "fname", C.lastname as "lname" 
from customer C Inner join invoice I 
on c.customerid = i.customerid;
 
--7.2 Create an outer join that joins the customer and invoice table, specifying the CustomerId, firstname, lastname, invoiceId, and total.
select C.customerid as "customerid", C.firstname as "fname", C.lastname as "lname", I.invoiceid as "invoiceid", I.total as "total"
from invoice I full join customer C 
on C.customerid = I.customerid;

--7.3 Create a right join that joins album and artist specifying artist name and title.
select AR.name as "artistname", A.title as "title" 
from album A right join artist AR 
on A.artistid = AR.artistid;

--7.4 Create a cross join that joins album and artist and sorts by artist name in ascending order.
select AR.name as "artistname", A.title as "title" 
from album A cross join artist AR
order by name asc;

--7.5 Perform a self-join on the employee table, joining on the reportsto column.
select E.employeeid, E.firstname, E.lastname, E.reportsto, M.firstname, M.lastname 
from employee E inner join employee M 
on E.reportsto = M.employeeid;