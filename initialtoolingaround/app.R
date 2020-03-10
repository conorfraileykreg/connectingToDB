#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinythemes)
library(odbc)
library(DBI)
library(dplyr)
library(dbplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(zoo)
library(reticulate)

# Load data
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

sales_value_by_channel <- sales %>%
    group_by(order_date, channel) %>%
    summarise(order_value = sum(order_value), 
              ship_value=sum(order_value), 
              backord_value=sum(backord_value))

sales_value_by_channel <- gather(sales_value_by_channel, 
                                 'order_value', 'ship_value', 'backord_value', 
                                 key = 'fulfillment_type', value = 'value')


# Define UI
ui <- fluidPage(theme = shinytheme("lumen"),
                titlePanel("Exploring Sales Order Values by Channel"),
                sidebarLayout(
                    sidebarPanel(
                        
                        # Select type of trend to plot
                        selectInput(inputId = "type", label = strong("Sales Order Value Type"),
                                    choices = unique(sales_value_by_channel$fulfillment_type),
                                    selected = "order_value"),
                        
                        # Select date range to be plotted
                        selectInput(inputId = "smoothing", label = strong("Smoothing days"),
                                    choices = c("1","7","14","28"),
                                    selected = "7"),
                        
                        )
                    ,
                    
                    # Output: Description, lineplot, and reference
                    mainPanel(
                        plotOutput(outputId = "lineplot", height = "300px"),
                        textOutput(outputId = "desc")
                    ))
                )

# Define server function
server <- function(input, output) {
    
    
    # Create scatterplot object the plotOutput function is expecting
    output$lineplot <- renderPlot({
        color = "#434343"
        par(mar = c(4, 4, 1, 1))
        sales_value_by_channel <- sales_value_by_channel %>%
            arrange(channel,order_date) %>%
            group_by(channel,fulfillment_type) %>%
            mutate(yd_mean_order_value = rollmeanr(value,as.integer(input$smoothing), fill = NA)) %>%
            ungroup()
        e <- ggplot(filter(sales_value_by_channel,fulfillment_type==input$type, !is.na(yd_mean_order_value),
                           channel %in% c('AMAZON','HOME DEPOT','LOWES','MENARDS','WOODCRAFT','OTHER DIRECT')))+
            geom_line(mapping = aes(x=order_date,y=yd_mean_order_value,colour=channel))
        e
        }
    )
    
    # Pull in description of trend
    output$desc <- renderText({
        trend_text <- filter(trend_description, type == input$type) %>% pull(text)
        paste(trend_text, "The index is set to 1.0 on January 1, 2004 and is calculated only for US search traffic.")
    })
}

# Create Shiny object
shinyApp(ui = ui, server = server)