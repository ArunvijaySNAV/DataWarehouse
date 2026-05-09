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
