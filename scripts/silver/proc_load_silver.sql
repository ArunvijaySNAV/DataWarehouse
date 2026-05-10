/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

create or alter procedure silver.load_silver as
begin
	begin try
		declare @startTime datetime, @endTime datetime, 
		@DurationSilverStart datetime, @DurationSilverEnd datetime;
		/*
		==============================
		-- Table: silver.crm_cust_info
		==============================
		*/
		set @DurationSilverStart = GETDATE();

		print '========================';
		print 'loading the silver layer';
		print '=========================';

		print '===================';
		print 'loading CRM tables';
		print '===================';

		set @startTime = GETDATE();

		print '>> Truncating Table: silver.crm_cust_info';
		truncate table silver.crm_cust_info;
		print '>> Inserting Data Into: silver.crm_cust_info';
		insert into silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_material_status,
			cst_gndr,
			cst_create_date
		)
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

		set @endTime = GETDATE();

		print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar) + ' seconds';
		print '>> -------------';

		/*
		=============================
		-- Table: silver.crm_prd_info
		=============================
		*/

		set @startTime = GETDATE();

		print '>> Truncating Table: silver.crm_prd_info';
		truncate table silver.crm_prd_info;
		print '>> Inserting Data Into: silver.crm_prd_info';
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

		set @endTime = GETDATE();

		print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar) + ' seconds';
		print '>> -------------';

		/*
		==================================
		-- Table: silver.crm_sales_details
		==================================
		*/

		set @startTime = GETDATE();

		print '>> Truncating Table: silver.crm_sales_details';
		truncate table silver.crm_sales_details;
		print '>> Inserting Data Into: silver.crm_sales_details';
		insert into silver.crm_sales_details(
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				sls_order_dt,
				sls_ship_dt,
				sls_due_dt,
				sls_sales,
				sls_quantity,
				sls_price
		)
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
			   case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
					then sls_quantity * abs(sls_price)
					else sls_sales
			   end sls_sales,
			   sls_quantity,
			   case when sls_price <= 0 or sls_price is null 
					then sls_sales / nullif(sls_quantity, 0)
					else sls_price
			   end sls_price
		from bronze.crm_sales_details;

		set @endTime = GETDATE();

		print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar) + ' seconds';
		print '>> -------------';

		/*
		==============================
		-- Table: silver.erp_cust_az12
		==============================
		*/

		print '==================';
		print 'loading ERP tables';
		print '==================';

		set @startTime = GETDATE();

		print '>> Truncating Table: silver.erp_cust_az12';
		truncate table silver.erp_cust_az12;
		print '>> Inserting Data Into: silver.erp_cust_az12';
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

		set @endTime = GETDATE();

		print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar) + ' seconds';
		print '>> -------------';

		/*
		=============================
		-- Table: silver.erp_loc_a101
		=============================
		*/

		set @startTime = GETDATE();

		print '>> Truncating Table: silver.erp_loc_a101';
		truncate table silver.erp_loc_a101;
		print '>> Inserting Data Into: silver.erp_loc_a101';
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

		set @endTime = GETDATE();

		print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar) + ' seconds';
		print '>> -------------';

		/*
		================================
		-- Table: silver.erp_px_cat_g1v2
		================================
		*/

		set @startTime = GETDATE();

		print '>> Truncating Table: silver.erp_px_cat_g1v2';
		truncate table silver.erp_px_cat_g1v2;
		print '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		insert into silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		select id,
			   cat,
			   subcat,
			   maintenance
		from bronze.erp_px_cat_g1v2;

		set @endTime = GETDATE();

		print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar) + ' seconds';
		print '>> -------------';

		set @DurationSilverEnd = GETDATE();

		print '>> Duration of bronze layer: ' + cast(datediff(second, @DurationSilverStart, @DurationSilverEnd) as nvarchar)+ ' seconds';

	end try
	begin catch
        print '==================';
        print 'error occured';
        print '==================';

        print 'error message' + error_message();
        print 'error number' + cast(error_number() as nvarchar);
        print 'error state' + cast(error_state() as nvarchar);  
	end catch;
end;
