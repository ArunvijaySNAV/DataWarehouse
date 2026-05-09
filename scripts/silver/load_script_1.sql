-- silver layer

select *
from bronze.crm_cust_info;

-- Check for Nulls or Duplicates in Primary Key.
-- Expectation: No Result

-- step1: Quality check (A primary key must be unique and not null)

select cst_id,
	   count(*) CountPerKey
from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id IS NULL;

-- Result: Not Satisfied the null values and primary key shouldn't repeat.

/*

since we have the data quality issue. 

* Explore into the value. 
	found: Primary key reduncany and solved.

* Explore into the values.
	found: Check for unwanted spaces in string values. 

*/

/*

==================================
MAIN TRANSFORMATIION: Silver layer
==================================

*/

select cst_id,
	   cst_key,
	   trim(cst_firstname) as cst_firstname, -- space removal
	   trim(cst_lastname) as cst_lastname,   -- space removal
	   case when trim(cst_material_status) in ('s', 'S') then 'Single'  -- standardization
			when trim(cst_material_status) in ('m', 'M') then 'Married' --		  |
			else 'n/a'													--        |
	   end cst_material_status,											--        |
	   case when trim(cst_gndr) in ('m', 'M') then 'Male'				--        |
			when trim(cst_gndr) in ('f', 'F') then 'Female'				--        |
			else 'n/a'													--        |
	   end cst_gndr,													-- standardization
	   cst_create_date
from (select *,
	  ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) flag_last
	  from bronze.crm_cust_info)t
where flag_last = 1;
 

/*

=================================
EXPLORATION: Silver Layer
================================

*/


select *,
	   ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) flag_last
from bronze.crm_cust_info;

-- check:
-- Exceptation: The flag_last must be containing 1. Primary key must be unique. 

		select *
		from (select *,
			   ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) flag_last
		from bronze.crm_cust_info)t
		where flag_last = 1; -- This return the duplicated key in the table. 


-- check for unwanted spaces.
-- Exceptation: No results

		select cst_firstname,
			   count(cst_firstname) over() SpaceInName
		from bronze.crm_cust_info
		where cst_firstname != trim(cst_firstname);
		-- result: We have firstname containing spacing of 18 rows.

		select cst_lastname,
			   count(cst_lastname) over() SpaceInName
		from bronze.crm_cust_info
		where cst_lastname != trim(cst_lastname);
		-- result: We have firstname containing spacing of 17 rows.


		-- low cardinality columns
		select cst_material_status,
			   count(cst_material_status) over() SpaceInName
		from bronze.crm_cust_info
		where cst_material_status != trim(cst_material_status);
		-- result: We have firstname containing spacing of 0 rows.(Data is quality...)

		-- low cardinality columns
		select cst_gndr,
			   count(cst_gndr) over() SpaceInName
		from bronze.crm_cust_info
		where cst_gndr != trim(cst_gndr);
		-- result: We have firstname containing spacing of 0 rows.(Data is quality...)

-- check: Data standardation & consistency.
-- Expection: Must contain similar data. 

			 -- for low cardinality: Values must be small and unqiue maintaining consistency.
			 -- for high cardinality: Values can be vast and must maintain consistency. 

		select distinct cst_gndr
		from bronze.crm_cust_info;

		select distinct cst_material_status
		from bronze.crm_cust_info;

/*

=========================================================================
INSERTION: inserting the data in the silver after transation is completed
=========================================================================

*/


-- insertion using the CTAS

if object_id('bronze.crm_cust_info', 'U') is not null
begin
	drop table bronze.crm_cust_info;

	select cst_id,
	   cst_key,
	   trim(cst_firstname) as cst_firstname, -- space removal
	   trim(cst_lastname) as cst_lastname,   -- space removal
	   case when trim(cst_material_status) in ('s', 'S') then 'Single'  -- standardization
			when trim(cst_material_status) in ('m', 'M') then 'Married' --		  |
			else 'n/a'													--        |
	   end cst_material_status,											--        |
	   case when trim(cst_gndr) in ('m', 'M') then 'Male'				--        |
			when trim(cst_gndr) in ('f', 'F') then 'Female'				--        |
			else 'n/a'													--        |
	   end cst_gndr,													-- standardization
	   cst_create_date
	into silver.crm_cust_info
	from (select *,
	  ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) flag_last
	  from bronze.crm_cust_info)t
	where flag_last = 1;

end;

-- insertion: normal insertion clause..

insert into silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_material_status,
	cst_gndr,
	cst_create_date)

select cst_id,
	   cst_key,
	   trim(cst_firstname) as cst_firstname, -- space removal
	   trim(cst_lastname) as cst_lastname,   -- space removal
	   case when trim(cst_material_status) in ('s', 'S') then 'Single'  -- standardization
			when trim(cst_material_status) in ('m', 'M') then 'Married' --		  |
			else 'n/a'													--        |
	   end cst_material_status,											--        |
	   case when trim(cst_gndr) in ('m', 'M') then 'Male'				--        |
			when trim(cst_gndr) in ('f', 'F') then 'Female'				--        |
			else 'n/a'													--        |
	   end cst_gndr,													-- standardization
	   cst_create_date
from (select *,
	  ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) flag_last
	  from bronze.crm_cust_info)t
where flag_last = 1;

-- check the table:

select *
from silver.crm_cust_info;

/*
========================================================
TEST: test with the explored queries
========================================================
*/

		select *,
			   ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) flag_last
		from bronze.crm_cust_info;

		-- check:
		-- Exceptation: The flag_last must be containing 1. Primary key must be unique. 

				select *
				from (select *,
					   ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) flag_last
				from bronze.crm_cust_info)t
				where flag_last = 1; -- This return the duplicated key in the table. 


		-- check for unwanted spaces.
		-- Exceptation: No results

				select cst_firstname,
					   count(cst_firstname) over() SpaceInName
				from bronze.crm_cust_info
				where cst_firstname != trim(cst_firstname);
				-- result: We have firstname containing spacing of 18 rows.

				select cst_lastname,
					   count(cst_lastname) over() SpaceInName
				from bronze.crm_cust_info
				where cst_lastname != trim(cst_lastname);
				-- result: We have firstname containing spacing of 17 rows.


				-- low cardinality columns
				select cst_material_status,
					   count(cst_material_status) over() SpaceInName
				from bronze.crm_cust_info
				where cst_material_status != trim(cst_material_status);
				-- result: We have firstname containing spacing of 0 rows.(Data is quality...)

				-- low cardinality columns
				select cst_gndr,
					   count(cst_gndr) over() SpaceInName
				from bronze.crm_cust_info
				where cst_gndr != trim(cst_gndr);
				-- result: We have firstname containing spacing of 0 rows.(Data is quality...)

		-- check: Data standardation & consistency.
		-- Expection: Must contain similar data. 

					 -- for low cardinality: Values must be small and unqiue maintaining consistency.
					 -- for high cardinality: Values can be vast and must maintain consistency. 

				select distinct cst_gndr
				from bronze.crm_cust_info;

				select distinct cst_material_status
				from bronze.crm_cust_info;

