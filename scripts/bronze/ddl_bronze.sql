/*
=========================================================
DDL Scripts: Create Bronze tables
=========================================================

script purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables
    if they already exist.

    Run this script to re-define the DDL structure of 'bronze' Tables.

=========================================================

*/



-- defining the DDL. Creating the tables with schema bronze for CRM. 

create table bronze.crm_cust_info(
	cst_id int,
	cst_key nvarchar(50),
	cst_firstname nvarchar(50),
	cst_lastname varchar(50),
	cst_material_status nvarchar(50),
	cst_gndr nvarchar(50),
	cst_create_date date
);

create table bronze.crm_prd_info(
	prd_id int,
	prd_key varchar(50),
	prd_nm varchar(50),
	prd_cost varchar(50),
	prd_line varchar(50),
	prd_start_dt date,
	prd_end_dt date
);

DROP TABLE bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     int,
    sls_order_dt    int,
    sls_ship_dt     int,
    sls_due_dt      int,
    sls_sales       int,
    sls_quantity    int,
    sls_price       int
);



-- defining the DDL. Creating the tables with schema bronze for ERP.
if object_ID('bronze.erp_cust_az12', 'U') is not null
begin 
    drop table bronze.erp_cust_az12;
    
    CREATE TABLE bronze.erp_cust_az12 (
    cid     VARCHAR(20),
    bdate   DATE,
    gen    VARCHAR(10)
    );
end;



if object_ID('bronze.erp_cust_az12', 'U') is not null
begin 
    drop table bronze.erp_loc_a101;

    CREATE TABLE bronze.erp_loc_a101 (
    cid    VARCHAR(20),
    cntry  VARCHAR(50)
    );

end;

if object_ID('bronze.erp_cust_az12', 'U') is not null
begin 
    drop table bronze.erp_px_cat_g1v2;
    CREATE TABLE bronze.erp_px_cat_g1v2 (
    id            VARCHAR(20),
    cat           VARCHAR(50),
    subcat        VARCHAR(100),
    maintenance   VARCHAR(10)
    );
end;


-- bulk insertion for the .csv file.

create or alter procedure bronze.load_bronze as 
begin
    begin try

        declare @startTime date, @endTime date, 
                @DurationBronzeStart date, @DurationBronzeEnd Date;

        set @DurationBronzeStart = GETDATE(); 
          
        print '========================';
        print 'loading the bronze layer';
        print '========================';

        print '------------------';
        print 'loading CRM tables';
        print '------------------';

        set @startTime  = getDate();

        print '>> Truncating Table: bronze.crm_cust_info';
        truncate table bronze.crm_cust_info;

        print '>> Inserting Data Into: bronze.crm_cust_info';
        bulk insert bronze.crm_cust_info
        from 'D:\DataWarehouse\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        with (
            firstrow = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        set @endTime = GETDATE();

        print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar)+' seconds';
        print '>> -------------'


        set @startTime = GETDATE();

        print '>> Truncating Table: bronze.crm_prd_info';
        truncate table bronze.crm_prd_info;

        print '>> Inserting Data Into: bronze.crm_cust_info';
        bulk insert bronze.crm_prd_info
        from 'D:\DataWarehouse\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        with (
            firstrow = 2,
            fieldterminator = ',',
            tablock
        );

        set @endTime = GETDATE();

        print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar)+' seconds';
        print '>> -------------'


        set @startTime = GETDATE();

        print '>> Truncating Table: bronze.crm_sales_details';
        truncate table bronze.crm_sales_details;

        print '>> Inserting Data Into: bronze.crm_sales_details';
        bulk insert bronze.crm_sales_details
        from 'D:\DataWarehouse\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        with (
                firstrow = 2,
                fieldterminator = ',',
                tablock
            );

        set @endTime = GETDATE();
                
        print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar)+' seconds';
        print '>> -------------'

        print '----------------------';
        print 'loading the erp tables';
        print '----------------------';

        set @startTime = GETDATE();
        
        print '>> Truncating Table: bronze.erp_cust_az12';
        truncate table bronze.erp_cust_az12;

        print '>> Inserting Data Into: bronze.erp_cust_az12';
        bulk insert bronze.erp_cust_az12
        from 'D:\DataWarehouse\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        with (
                firstrow = 2,
                fieldterminator = ',',
                tablock
            );

        set @endTime = GETDATE();

        print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar)+' seconds';
        print '>> -------------'

        set @startTime = GETDATE();

        print '>> Truncating Table: bronze.erp_loc_a101';
        truncate table bronze.erp_loc_a101;

        print '>> Inserting Data Into: bronze.erp_loc_a101';
        bulk insert bronze.erp_loc_a101
        from 'D:\DataWarehouse\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        with (
                firstrow = 2,
                fieldterminator = ',',
                tablock
            );

        set @endTime = GETDATE();

        print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar)+' seconds';
        print '>> -------------'

        set @startTime = GETDATE();

        print '>> Truncating Table: bronze.erp_px_cat_g1v2';
        truncate table bronze.erp_px_cat_g1v2;

        print '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        bulk insert bronze.erp_px_cat_g1v2
        from 'D:\DataWarehouse\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        with (
                firstrow = 2,
                fieldterminator = ',',
                tablock
            );

        set @endTime = GETDATE();

        print '>> Load duration: '+ cast(datediff(second, @startTime, @endTime) as nvarchar)+' seconds';
        print '>> -------------'


        set @DurationBronzeEnd = GETDATE();

        print '>> Duration of bronze layer: ' + cast(datediff(second, @DurationBronzeStart, @DurationBronzeEnd) as nvarchar)+ 'seconds';
    end try
    begin catch
        print '==================';
        print 'error occured';
        print '==================';

        print 'error message' + error_message();
        print 'error number' + cast(error_number() as nvarchar);
        print 'error state' + cast(error_state() as nvarchar); 
    end catch
end;

