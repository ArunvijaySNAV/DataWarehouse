/*
=======================================
CRM Table: bronze.crm_sales_details
=======================================
*/


/*
========================================================
Main Transformation: Query ---> silver.crm_sales_details
========================================================
*/

select sls_ord_num,
	   sls_prd_key,
	   sls_cust_id,
	   case when sls_order_dt <= 0 then NULL
			when len(sls_order_dt) != 8 then NULL
			else cast(cast(sls_order_dt as varchar) as date) 
	   end sls_order_dt,
	   case when sls_ship_dt <= 0 then NULL
			when len(sls_ship_dt) != 8 then NULL
			else cast(cast(sls_ship_dt as varchar) as date) 
	   end sls_ship_dt,
	   case when sls_due_dt <= 0 then NULL
			when len(sls_due_dt) != 8 then NULL
			else cast(cast(sls_due_dt as varchar) as date) 
	   end sls_due_dt,	   
	   sls_sales,
	   sls_quantity,
	   sls_price
from bronze.crm_sales_details;


/*
=====================================
Exploration: bronze.crm_sales_details
=====================================
*/

-- check: Spacing in the sls_ord_num
-- Expectation: no rows

	select sls_ord_num
	from bronze.crm_sales_details
	where sls_ord_num != trim(sls_ord_num);
	-- result: 0 rows found. 

-- check: key belongs to silver.crm_prd_info
-- Expectation: no rows
-- used to join the tables. To join with silver.crm_prd_info

	select sls_prd_key
	from bronze.crm_sales_details
	where sls_prd_key not in (select prd_key from silver.crm_prd_info);
	-- result: 0 rows found


-- check: key belongs to silver.crm_cust_info
-- Expectation: no rows
-- used to join the tables. To join with silver.crm_cust_info

	select sls_cust_id
	from bronze.crm_sales_details
	where sls_cust_id not in (select cst_id from silver.crm_cust_info);
	-- result: 0 rows found

-- check: Invalid Dates

	-- COLUMN: sls_order_dt

		-- >> Check dates are less than are equal zero. 
		-- >> The length of the date rows must be only 8. Including the Year|Month|Date

		select nullif(sls_order_dt, 0) sls_order_dt
		from bronze.crm_sales_details
		where sls_order_dt <= 0 or len(sls_order_dt) != 8;
		-- result: The data is in the bad quality.

		-- >> Check for outliers by validating the boundaries of the range

		select nullif(sls_order_dt, 0) sls_order_dt
		from bronze.crm_sales_details
		where sls_order_dt > 20500101;
		-- result: O rows

		select nullif(sls_order_dt, 0) sls_order_dt
		from bronze.crm_sales_details
		where sls_order_dt < 19000101;

		-- finally:

		select nullif(sls_order_dt, 0) sls_order_dt
		from bronze.crm_sales_details
		where sls_order_dt <= 0 or
			  len(sls_order_dt) != 8 or
			  sls_order_dt > 20500101 or
			  sls_order_dt < 19000101;

	-- COLUMN: sls_ship_dt

			select nullif(sls_ship_dt, 0) sls_ship_dt
			from bronze.crm_sales_details
			where sls_ship_dt <= 0 or
				  len(sls_ship_dt) != 8 or
				  sls_ship_dt > 20500101 or
				  sls_ship_dt < 19000101;
			-- Result: 0 rows

	-- COLUMN: sls_due_dt

			select nullif(sls_due_dt, 0) sls_due_dt
			from bronze.crm_sales_details
			where sls_due_dt <= 0 or
				  len(sls_due_dt) != 8 or
				  sls_due_dt > 20500101 or
				  sls_due_dt < 19000101;
			-- Result: 0 rows

-- checK: The order date must be smaller than shipping date and due date. 

	select *
	from bronze.crm_sales_details
	where sls_order_dt > sls_ship_dt or
		  sls_order_dt > sls_due_dt
	-- result: 0 rows. 

-- check: Data Consistency: Between Sales, Quantity and price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.

	select sls_sales,
		   sls_quantity,
		   sls_price
	from bronze.crm_sales_details
	where sls_sales != sls_quantity * sls_price or
		  sls_sales is null or sls_quantity is null or sls_price is null
		  or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0
		  order by sls_sales, sls_quantity, sls_price

	-- result: 35 rows

	-- To rectify:
	-- As per business rules:

	--       * if sales is negative, zero, or null, derive it using Quantity and price.
	--       * if price is zero or null, calculate it using Sales and Quantity.
	--       * if price is negative, convert it to a positive value. 


	select sls_sales,
		   sls_quantity,
		   sls_price as old_sls_price,
		   case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
					then sls_quantity * abs(sls_price)
				else sls_sales
		   end sls_sales
	from bronze.crm_sales_details
	where sls_sales != sls_quantity * sls_price or
		  sls_sales is null or sls_quantity is null or sls_price is null
		  or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0
		  order by sls_sales, sls_quantity, sls_price
