with sales as (

    select *
    from {{ ref('stg_sales') }}

),

flagged as (

    select
        *,

        case
            when order_id is null then 'missing_order_id'
            when order_date is null then 'invalid_or_missing_order_date'
            when store_id is null then 'missing_store_id'
            when customer_id is null then 'missing_customer_id'
            when product_id is null then 'missing_product_id'
            when quantity is null then 'missing_quantity'
            when quantity <= 0 then 'invalid_quantity'
            when unit_price is null then 'missing_unit_price'
            when unit_price < 0 then 'invalid_unit_price'
            when discount_amount is null then 'missing_discount_amount'
            when discount_amount < 0 then 'invalid_discount_amount'
            when net_amount is null then 'missing_net_amount'
            when net_amount < 0 then 'discount_greater_than_gross'
            else null
        end as rejection_reason

    from sales

)

select *
from flagged
where rejection_reason is not null
