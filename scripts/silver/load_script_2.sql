/*
===============================================
Table: bronze.crm_prd_info || INTO silver layer
===============================================
*/

/*
===============================================
			MAIN TRANSFORMATION
===============================================
*/

select 
	   prd_id,
	   replace(substring(prd_key, 1, 5), '-', '_') AS cat_id,
	   SUBSTRING(prd_key, 7, len(prd_key)) as prd_key,
	   prd_nm,
	   isnull(prd_cost, 0) as prd_cost,
	   case upper(trim(prd_line))
			when 'M' then 'Mountain'
			when 'R' then 'Road'
			when 'S' then 'Other Sales'
			when 'T' then 'Touring'
			else 'n/a'
	   end prd_line,
	   cast(prd_start_dt as date) prd_start_dt,
	   cast(dateadd(day, -1, lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)) as date) as prd_end_dt
from bronze.crm_prd_info;

/*
===============================
		  TESTING
===============================
*/

select 
	   prd_id,
	   prd_key,
	   replace(substring(prd_key, 1, 5), '-', '_') AS cat_id,
	   SUBSTRING(prd_key, 7, len(prd_key)) as prd_key,
	   prd_nm,
	   isnull(prd_cost, 0) as prd_cost,
	   case when trim(prd_line) in ('m', 'M') then 'Mountain'
			when trim(prd_line) in ('r', 'R') then 'Road'
			when trim(prd_line) in ('s', 'S') then 'other Sales'
			when trim(prd_line) in ('t', 'T') then 'Touring'
	   end prd_line,
	   prd_start_dt,
	   dateadd(day, -1, lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)) as prd_end_dt
from bronze.crm_prd_info;

/*
======================================
Exploration: bronze.crm_prd_info
======================================
*/

-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
-- column: prd_id

	select prd_id,
		   count(*) Rep_prd_id
	from bronze.crm_prd_info
	group by prd_id
	having COUNT(*) > 1 or prd_id is null;
	-- Result: No Duplicate found (Data Quality)


-- Dividing the data from the prd_key
-- Expectation: To join the crm with the erp table in the gold layer.
              --divide the string that will connect to the erp tables (bronze.erp_px_cat_g1v2).

			  -- SELECT * FROM bronze.erp_px_cat_g1v2;
	

	-- joining to bronze.erp_px_cat_g1v2
		select replace(substring(prd_key, 1, 5), '-', '_') as cat_id
		from bronze.crm_prd_info;


		select * from bronze.erp_px_cat_g1v2;

		-- filter out unmatched data. 

		select distinct replace(substring(prd_key, 1, 5), '-', '_') as cat_id
		from bronze.crm_prd_info
		where replace(substring(prd_key, 1, 5), '-', '_') not in (select distinct id 
																  from bronze.erp_px_cat_g1v2);

	-- joining to bronze.crm_sales_details
		
		select sls_prd_key from bronze.crm_sales_details;

		select SUBSTRING(prd_key, 7, len(prd_key)) as prd_key
		from bronze.crm_prd_info;

		-- filter out unmatched data. 

		select distinct SUBSTRING(prd_key, 7, len(prd_key)) as prd_key
		from bronze.crm_prd_info
		where SUBSTRING(prd_key, 7, len(prd_key)) not in (select distinct sls_prd_key
																  from bronze.crm_sales_details);

-- check for unwanted Spaces
-- Expectation: No Results

	select prd_nm
	from bronze.crm_prd_info
	where prd_nm != trim(prd_nm);
	-- result: It contains 0 rows. (Data Quality)


-- check for NULLs or Negative Numbers
-- Expectation: No Result; column: prd_cost


	select isnull(prd_cost, 0)
	from bronze.crm_prd_info
	where prd_cost < 0 or prd_cost is null;
	-- result: Found out two rows contains NULLs values and replaced with 0.

-- check: Distinct value in the prd_line
-- Expectation: Must be low cardinality.; column: prd_line

	select distinct prd_line
	from bronze.crm_prd_info
	-- Result: Yes, It is low cardinality values and null values. 

-- check for invalid Date Orders (End date must not be earlier than the start date)

--	* End of the younger history must be smaller than the start date of next record. 
-- Expectation: No results

	select *
	from bronze.crm_prd_info
	where prd_end_dt < prd_start_dt;
	-- result: We have lot of date's that are invalid. 

	-- ignore the end date of the table. And derive it from the start date. 

	select prd_start_dt,
		   Lead(prd_start_dt) over(order by prd_start_dt) prd_end_dt
	from bronze.crm_prd_info;

		-- case test: 

		select prd_id,
			   prd_key,
			   prd_nm,
			   prd_start_dt,
			   dateadd(day, -1, lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)) prd_end_test_dt
		from bronze.crm_prd_info
		where prd_key in ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')


if OBJECT_ID('silver.crm_prd_info', 'U') is not null
begin
	DROP table silver.crm_prd_info;

	create table silver.crm_prd_info(
		prd_id int,
		cat_id nvarchar(50),
		prd_key nvarchar(50),
		prd_nm varchar(150),
		prd_cost int,
		prd_line nvarchar(50),
		prd_start_dt date,
		prd_end_dt date
	);
end;


/*
===========================================
INSERTITION: main transformation query
===========================================
*/

insert into silver.crm_prd_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
)
select 
	   prd_id,
	   replace(substring(prd_key, 1, 5), '-', '_') AS cat_id,
	   SUBSTRING(prd_key, 7, len(prd_key)) as prd_key,
	   prd_nm,
	   isnull(prd_cost, 0) as prd_cost,
	   case upper(trim(prd_line))
			when 'M' then 'Mountain'
			when 'R' then 'Road'
			when 'S' then 'Other Sales'
			when 'T' then 'Touring'
			else 'n/a'
	   end prd_line,
	   cast(prd_start_dt as date) prd_start_dt,
	   cast(dateadd(day, -1, lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)) as date) as prd_end_dt
from bronze.crm_prd_info;

/*
============================================
TESTING: with explored values
============================================
*/

select prd_id,
	   count(*) Rep_prd_id
from silver.crm_prd_info
group by prd_id
having COUNT(*) > 1 or prd_id is null;  -- (test: Okay)

select *
from silver.crm_prd_info
where prd_end_dt < prd_start_dt; -- (test: Okay)

select * from silver.crm_prd_info;
