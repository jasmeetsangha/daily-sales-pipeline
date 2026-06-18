select *
from {{ ref('stg_sales') }}
where discount_amount is not null
  and discount_amount < 0
