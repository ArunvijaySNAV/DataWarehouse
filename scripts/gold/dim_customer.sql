/*
============================
        GOLD LAYER
============================
*/

create view gold.dim_customers as 
select 
       ROW_NUMBER() over(order by ci.cst_id) as customer_key, -- surrogate key
       ci.cst_id as customer_id,
       ci.cst_key as customer_number,
       ci.cst_firstname as first_name,
       ci.cst_lastname as last_name,
       la.cntry as country,
       ci.cst_material_status as marital_status,
       case when ci.cst_gndr != 'n/a' then ci.cst_gndr
            else coalesce(ca.gen, 'n/a')
       end gender,
       ca.bdate as birthdate,
       ci.cst_create_date as create_date
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
    on ci.cst_key = ca.cid
left join silver.erp_loc_a101 la
    on ci.cst_key = la.cid
where ci.cst_key != 'PO25';


/*
===============================
        EXPLORATION
===============================
*/

select top 3 * 
from silver.crm_cust_info;

select top 3 *
from silver.erp_cust_az12;

select top 3 *
from silver.erp_loc_a101;




--- Data integretion: (Master table: CRM)

        select ci.cst_gndr,
               ec.gen,
               case when ci.cst_gndr != 'n/a' then ci.cst_gndr
                    else coalesce(ec.gen, 'n/a')
               end new_gen
        from silver.crm_cust_info ci
        left join silver.erp_cust_az12 ec
            on ci.cst_key = ec.cid
