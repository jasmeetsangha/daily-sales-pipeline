select *
from {{ ref('stg_sales') }}
where quantity is not null
  and quantity <= 0
