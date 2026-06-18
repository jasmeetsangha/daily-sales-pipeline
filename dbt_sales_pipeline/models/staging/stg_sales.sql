with source as (

    select *
    from {{ source('sales_raw', 'sales_daily') }}

),

cleaned as (

    select
        cast(order_id as string) as order_id,
        safe_cast(order_date as date) as order_date,
        cast(store_id as string) as store_id,
        cast(customer_id as string) as customer_id,
        cast(product_id as string) as product_id,
        safe_cast(quantity as int64) as quantity,
        safe_cast(unit_price as numeric) as unit_price,
        safe_cast(discount_amount as numeric) as discount_amount,
        lower(trim(cast(payment_method as string))) as payment_method,
        safe_cast(created_at as timestamp) as created_at,

        safe_cast(quantity as int64) * safe_cast(unit_price as numeric) as gross_amount,

        (
            safe_cast(quantity as int64) * safe_cast(unit_price as numeric)
        ) - safe_cast(discount_amount as numeric) as net_amount

    from source

)

select *
from cleaned
