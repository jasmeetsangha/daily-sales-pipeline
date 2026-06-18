select *
from {{ ref('stg_sales') }}
where unit_price is not null
  and unit_price < 0
