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
	   prd_key,
	   replace(substring(prd_key, 1, 5), '-', '_') AS cat_id,
	   prd_nm,
	   prd_cost,
	   prd_line,
	   prd_start_dt,
	   prd_end_dt
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
	   prd_cost,
	   prd_line,
	   prd_start_dt,
	   prd_end_dt
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
