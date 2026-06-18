with sales as (

    select *
    from {{ ref('valid_sales_records') }}
    where order_id is not null
      and order_date is not null
      and store_id is not null
      and customer_id is not null
      and product_id is not null
      and quantity > 0
      and unit_price >= 0
      and discount_amount >= 0
      and net_amount >= 0

),

final as (

    select
        order_date,
        store_id,
        count(distinct order_id) as total_orders,
        sum(quantity) as total_quantity,
        sum(gross_amount) as gross_sales,
        sum(discount_amount) as total_discount,
        sum(net_amount) as net_sales

    from sales
    group by order_date, store_id

)

select *
from final
