with sales as (

    select *
    from {{ ref('stg_sales') }}

),

valid as (

    select *
    from sales
    where order_id is not null
      and order_date is not null
      and store_id is not null
      and customer_id is not null
      and product_id is not null
      and quantity is not null
      and quantity > 0
      and unit_price is not null
      and unit_price >= 0
      and discount_amount is not null
      and discount_amount >= 0
      and net_amount is not null
      and net_amount >= 0

)

select *
from valid
