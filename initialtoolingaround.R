
library(odbc)
library(DBI)
library(dplyr)
library(dbplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(zoo)
library(RMariaDB)

con <- dbConnect(RMariaDB::MariaDB(), user = 'Reports',
                 password = 'Build$om3thing',
                 host = 'starfire',
                 dbname = 'buildsomething')

adds <- dbGetQuery(con,
                   "
                   select count(1)
                   from tbladdress
                   ")




con <- dbConnect(odbc(),
              driver = 'SQL Server',
              server = 'iceman',
              database = 'SysproReporting',
              trusted_connection=TRUE)

sales <-  dbGetQuery(con,
"
select 
  som.OrderDate as order_date,
	sod.MStockCode as stock_code,
	sod.MStockDes stock_desc,
	sal.Name as channel,
	count(1) as order_freq,
	sum(sod.MOrderQty) as order_qty,
	sum(sod.MShipQty) as ship_qty,
	sum(sod.MBackOrderQty) as backord_qty,
	sum(sod.MOrderQty*sod.MPrice) as order_value,
	sum(sod.MShipQty*sod.MPrice) as ship_value,
	sum(sod.MBackOrderQty*sod.MPrice) as backord_value
from SysproReporting.dbo.SorMaster as som
inner join SysproReporting.dbo.SorDetail as sod
on sod.SalesOrder = som.SalesOrder
inner join SysproReporting.dbo.SalSalesperson as sal
on sal.Salesperson = som.Salesperson
where som.OrderDate >= dateadd(month, -6, getdate())
and som.OrderDate <= getdate()

group by 
	som.OrderDate,
	sod.MStockCode,
	sod.MStockDes,
	sal.Name

order by som.OrderDate
")

sales_volume <- sales %>%
  group_by(order_date) %>%
  summarise(order_qty = sum(order_qty))
a <- ggplot(sales_volume)
a <- a + geom_line(mapping = aes(x=order_date,y=order_qty))



sales_value_by_fulfillment <- sales %>%
  group_by(order_date) %>%
  summarise(order_value = sum(order_value), 
            ship_value=sum(order_value), 
            backord_value=sum(backord_value))

sales_value_by_fulfillment <- gather(sales_value_by_fulfillment, 
            'order_value', 'ship_value', 'backord_value', 
            key = 'fulfillment_type', value = 'value')

b <- ggplot(sales_value_by_fulfillment)
b <- b + geom_line(mapping = aes(x=order_date,y=value,colour=fulfillment_type))


filter(sales_value_by_fulfillment, order_date == ymd('2020-02-06'))

sales_value_by_channel <- sales %>%
  group_by(order_date, channel) %>%
  summarise(order_value = sum(order_value), 
            ship_value=sum(order_value), 
            backord_value=sum(backord_value))

sales_value_by_channel <- gather(sales_value_by_channel, 
                                  'order_value', 'ship_value', 'backord_value', 
                                  key = 'fulfillment_type', value = 'value')

c <- ggplot(filter(sales_value_by_channel,fulfillment_type=='order_value'))
c <- c + geom_line(mapping = aes(x=order_date,y=value,colour=channel))

d <- ggplot(filter(sales_value_by_channel,fulfillment_type=='order_value',
                   channel %in% c('AMAZON','HOME DEPOT','LOWES','MENARDS','WOODCRAFT','OTHER DIRECT')))
d <- d + geom_line(mapping = aes(x=order_date,y=value,colour=channel))

sales_value_by_channel <- sales_value_by_channel %>%
  arrange(channel,order_date) %>%
  group_by(channel,fulfillment_type) %>%
  mutate(yd_mean_order_value = rollmeanr(value,28, fill = NA)) %>%
  ungroup()

e <- ggplot(filter(sales_value_by_channel,fulfillment_type=='order_value', !is.na(yd_mean_order_value),
                   channel %in% c('AMAZON','HOME DEPOT','LOWES','MENARDS','WOODCRAFT','OTHER DIRECT')))
e <- e + geom_line(mapping = aes(x=order_date,y=yd_mean_order_value,colour=channel))