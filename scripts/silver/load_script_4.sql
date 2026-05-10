/*
=======================================
ERP Table: bronze.erp_cust_az12
=======================================
*/


/*
========================================================
Main Transformation: Query ---> silver.erp_cust_az12
========================================================
*/

select case 
		 when cid like 'NAS%' then substring(cid, 4, len(cid))
		 else cid
	   end cid,
	   case when bdate > GETDATE() then NULL
				 else bdate
			end bdate, -- Set future birthdates to NULL
	   case when trim(gen) in ('m', 'M', 'Male') then 'Male'
				when trim(gen) in ('f', 'F', 'Female') then 'Female'
				else 'n/a'
		   end gen -- Normalize gender values and handle unknown cases.
from bronze.erp_cust_az12;

/*
=====================================
Exploration: bronze.erp_cust_az12
=====================================
*/

-- To join to the table: 

select top 3 * from silver.crm_cust_info;
select top 3 * from bronze.erp_cust_az12;

-- check: The key to connect (silver.crm_cust_info ----> bronze.erp_cust_az12 [cst_key, cid])

		select 
			  case when cid like 'NAS%' then substring(cid, 4, len(cid))
					else cid
			   end cid,
			   bdate,
			   gen
		from bronze.erp_cust_az12;

		-- matching data:

		select 
			  case when cid like 'NAS%' then substring(cid, 4, len(cid))
					else cid
			   end cid,
			   bdate,
			   gen
		from bronze.erp_cust_az12
		where case when cid like 'NAS%' then substring(cid, 4, len(cid))
					else cid end not in (select cst_key from silver.crm_cust_info);


-- check: Invalid date in the bdate column
-- expectation: No result

     -- * check date with extremity ranges. (range check)

	 select bdate
	 from bronze.erp_cust_az12
	 where bdate < '1924-01-01'; -- low values

	 -- * To check the bdate in future.

	 select case when bdate > GETDATE() then NULL
				 else bdate
			end bdate
	 from bronze.erp_cust_az12
	 where bdate > GETDATE();

-- check: cardinality of the column(gen)
-- expectation: low cardinality

	select distinct gen
	from bronze.erp_cust_az12;
	-- result: This contain 'NULL', 'F', ' ', 'Male', 'M', 'Female'

	select case when trim(gen) in ('m', 'M', 'Male') then 'Male'
				when trim(gen) in ('f', 'F', 'Female') then 'Female'
				else 'n/a'
		   end gen
	from bronze.erp_cust_az12;


/*
==============================================
INSERTION: inserting into silver.erp_cust_az12
==============================================
*/

-- check: Select * from silver.erp_cust_az12

insert into silver.erp_cust_az12(
	cid,
	bdate,
	gen
)
select case 
		 when cid like 'NAS%' then substring(cid, 4, len(cid))
		 else cid
	   end cid,
	   case when bdate > GETDATE() then NULL
				 else bdate
			end bdate,
	   case when trim(gen) in ('m', 'M', 'Male') then 'Male'
				when trim(gen) in ('f', 'F', 'Female') then 'Female'
				else 'n/a'
		   end gen
from bronze.erp_cust_az12;

/*
===============================
	Data Quality: Checks
===============================
*/

select * from silver.erp_cust_az12;

select case when bdate > GETDATE() then NULL
			else bdate
		end bdate
from silver.erp_cust_az12
where bdate > GETDATE();

/*
=======================================
ERP Table: bronze.erp_loc_a101
=======================================
*/


/*
========================================================
Main Transformation: Query ---> silver.erp_loc_a101
========================================================
*/

select replace(cid, '-', '') as cid,
	   case when trim(cntry) = 'DE' then 'Germany'
			when trim(cntry) in ('US', 'USA') then 'United States'
			when trim(cntry) = '' or cntry is null then 'n/a'
			else trim(cntry)
	   end cntry  -- Normalize and handle missing or blank country codes
from bronze.erp_loc_a101;

/*
==========================================
			EXPLORATION
==========================================
*/

-- check: select cst_key from silver.crm_cust_info;

select top 3 * from bronze.erp_loc_a101;
select top 3 cst_key from silver.crm_cust_info;

-- check: To join silver.crm_cust_info key.
-- Expectation: format AW-00011000 --> AW00011000

		select replace(cid, '-', '') as cid
		from bronze.erp_loc_a101;
		-- result: formatted AW-00011000 --> AW00011000

		-- check match values.
		select replace(cid, '-', '') as cid
		from bronze.erp_loc_a101
		where replace(cid, '-', '') not in (select cst_key from silver.crm_cust_info);


-- check: COLUMN : cntry

		select distinct cntry
		from bronze.erp_loc_a101;


	   select distinct
	   case when trim(cntry) = 'DE' then 'Germany'
			when trim(cntry) in ('US', 'USA') then 'United States'
			when trim(cntry) = '' or cntry is null then 'n/a'
			else trim(cntry)
	   end cntry
	   from bronze.erp_loc_a101;

/*
=============================
		INSERTION
=============================
*/

insert into silver.erp_loc_a101(
	cid,
	cntry
)
select replace(cid, '-', '') as cid,
	   case when trim(cntry) = 'DE' then 'Germany'
			when trim(cntry) in ('US', 'USA') then 'United States'
			when trim(cntry) = '' or cntry is null then 'n/a'
			else trim(cntry)
	   end cntry
from bronze.erp_loc_a101;


/*
===============================
	  Data Quality check
===============================
*/

select * from silver.erp_loc_a101;

select replace(cid, '-', '') as cid
from bronze.erp_loc_a101
where replace(cid, '-', '') not in (select cst_key from silver.crm_cust_info);
