
/*
============================================
stored procedure: Load Bronze layer
============================================

script purpose:
    This stored procedure loads the data into the 'bronze' schema from external .CSV files.

    It performs the following actions:

     - Truncates the brone tables before loading the data.
     - Uses the 'BULK INSERT' commands to load data from csv files to bronze tables.

parameters:
    None.
    This stored procedure does not accept any parameters or return ant values.

Usage Examples:
    EXEC bronze.load_bronze

================================================
*/


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
