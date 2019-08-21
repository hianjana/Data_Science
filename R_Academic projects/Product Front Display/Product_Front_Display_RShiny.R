#########################################################################################################
# Install required packages
#########################################################################################################

install.packages("shiny")
install.packages("dplyr")
install.packages("shinythemes")
install.packages("DT")
install.packages("mondate")

library(dplyr)
library(shiny)
library(shinythemes)
library(mondate)
library(DT)

#########################################################################################################
# Read the recommendations file and the product classifications file
#########################################################################################################

setwd("C:/Users/hianj/Documents/My studies/15_Leroy Merlin/data/")

dfRecommendation                      = read.csv("./Recommendations.csv", header = TRUE, sep = "|", quote = "")

dfProductClassifications              = read.csv("./dim_art.csv", header = TRUE, sep = ";", quote = "\"")
colnames(dfProductClassifications)    = c("Product_SKU", "Product_Desc", "Aisle_No", "Aisle_Desc", "Sub_Aisle_No", "Sub_Aisle_Desc",
                                          "Type_No", "Type_Desc", "Sub_Type_No", "Sub_Type_Desc", "Top_100")

dfProductInFront                      = read.csv("./products_in_front.csv", header = TRUE, sep = ",", quote = "\"")
colnames(dfProductInFront)            = c("End_Display_Id", "End_Display_Type", "Aisle_No", "Display_Start_Dt", "Display_End_Dt", 
                                          "Composition_Start_Dt", "Composition_End_Dt",  "Product_SKU")
dfProductInFront$Composition_Start_Dt = as.Date(dfProductInFront$Composition_Start_Dt)
dfProductInFront$Composition_End_Dt   = as.Date(dfProductInFront$Composition_End_Dt)
reqdcols                              = c("Product_SKU", "Aisle_No", "Composition_Start_Dt", "Composition_End_Dt")
dfProductInFront                      = dfProductInFront[,reqdcols]
dfProductInFront$Composition_End_Dt[is.na(dfProductInFront$Composition_End_Dt)] = as.character(Sys.Date())
dfProductInFront$Month                = month(dfProductInFront$Composition_Start_Dt)
dfProductInFront$Duration             = dfProductInFront$Composition_End_Dt - 
                                        dfProductInFront$Composition_Start_Dt

dfSales                               = read.csv("./sales.csv", header = TRUE, sep = ",", quote = "\"")
colnames(dfSales)                     = c("Store_No", "Sales_Dt",  "Product_SKU", "Quantity_Sold", "Amount_In_Euros")
dfSales                               = subset(dfSales, Quantity_Sold > 0)
dfProductSales                        = merge(dfProductInFront, dfSales, by = "Product_SKU")

dfProductSales$Sales_Dt               = as.Date(dfProductSales$Sales_Dt)
dfProductSales$Composition_Start_Dt   = as.Date(dfProductSales$Composition_Start_Dt)
dfProductSales$Composition_End_Dt     = as.Date(dfProductSales$Composition_End_Dt)
dfFrontRowSales                       = subset(dfProductSales, Sales_Dt>= Composition_Start_Dt & Sales_Dt<= Composition_End_Dt)

#########################################################################################################
# Data specific to each department
#########################################################################################################

dfElectricity                     = subset(dfProductClassifications, Aisle_No == 3)
dfTooling                         = subset(dfProductClassifications, Aisle_No == 10)
dfLighting                        = subset(dfProductClassifications, Aisle_No == 13)

#########################################################################################################
# Data subset with product sales and front display details
#########################################################################################################

dfMonths                              = c(1,2,3,4,5,6,7,8,9,10,11,12)  
dateRange                             = Sys.Date() - 365
dfProductInFront1year                 = subset(dfProductInFront, Composition_Start_Dt>= dateRange)
dfProductInFront1yearTotal            = aggregate(dfProductInFront1year$Duration, 
                                                  by =list(dfProductInFront1year$Product_SKU, dfProductInFront1year$Month ), 
                                                  FUN=sum)
colnames(dfProductInFront1yearTotal)  = c("Product_SKU", "Month" ,"Display_Duration_In_Days")

### For electricity 
dfElectriSales                        = inner_join(dfElectricity,dfSales, by = "Product_SKU")
dfElectriSales$Sales_Dt               = as.Date(dfElectriSales$Sales_Dt)
dfElectriSales1                       = subset(dfElectriSales, Sales_Dt>= dateRange)
dfElectriSales1$Month                 = month(dfElectriSales1$Sales_Dt)
dfElectriSalesSub                     = aggregate(dfElectriSales1$Quantity_Sold, by = list(dfElectriSales1$Product_SKU, dfElectriSales1$Month), FUN=sum)
colnames(dfElectriSalesSub)           = c("Product_SKU", "Month","Quantity_Sold")
dfElectricSummary                     = full_join(dfElectriSalesSub, dfProductInFront1yearTotal, by = c("Product_SKU", "Month"))
dfElectricSummary                     = dfElectricSummary[order(dfElectricSummary$Product_SKU, dfElectricSummary$Month),]
reqdcols                              = c("Product_SKU")
dfElectricityProducts                 = dfElectriSales1[,reqdcols]
dfElectricityProducts                 = unique(dfElectricityProducts)
dfElec12Months                        = merge(dfElectricityProducts,dfMonths, by=NULL)
colnames(dfElec12Months)              = c("Product_SKU", "Month")
dfElec12Months                        = dfElec12Months[order(dfElec12Months$Product_SKU),]
dfElectricalProducts                  = left_join(dfElec12Months, dfElectricSummary, by = c("Product_SKU", "Month"))
dfElectricalProducts[is.na(dfElectricalProducts)] = 0
dfPrdSubsetE                          = dfElectricalProducts$Product_SKU
dfPrdSubsetE                          = unique(dfPrdSubsetE)

### For Tooling
dfToolingSales                        = inner_join(dfTooling,dfSales, by = "Product_SKU")
dfToolingSales$Sales_Dt               = as.Date(dfToolingSales$Sales_Dt)
dfToolingSales1                       = subset(dfToolingSales, Sales_Dt>= dateRange)
dfToolingSales1$Month                 = month(dfToolingSales1$Sales_Dt)
dfToolingSalesSub                     = aggregate(dfToolingSales1$Quantity_Sold, by = list(dfToolingSales1$Product_SKU, dfToolingSales1$Month), FUN=sum)
colnames(dfToolingSalesSub)           = c("Product_SKU", "Month","Quantity_Sold")
dfToolingSummary                      = full_join(dfToolingSalesSub, dfProductInFront1yearTotal, by = c("Product_SKU", "Month"))
dfToolingSummary                      = dfToolingSummary[order(dfToolingSummary$Product_SKU, dfToolingSummary$Month),]
reqdcols                              = c("Product_SKU")
dfToolingProducts                     = dfToolingSales1[,reqdcols]
dfToolingProducts                     = unique(dfToolingProducts)
dfTool12Months                        = merge(dfToolingProducts,dfMonths, by=NULL)
colnames(dfTool12Months)              = c("Product_SKU", "Month")
dfTool12Months                        = dfTool12Months[order(dfTool12Months$Product_SKU),]
dfToolingProducts                     = left_join(dfTool12Months, dfToolingSummary, by = c("Product_SKU", "Month"))
dfToolingProducts[is.na(dfToolingProducts)] = 0
dfPrdSubsetT                          = dfToolingProducts$Product_SKU
dfPrdSubsetT                          = unique(dfPrdSubsetT)

# ### For Lighting
dfLightingSales                       = inner_join(dfLighting,dfSales, by = "Product_SKU")
dfLightingSales$Sales_Dt              = as.Date(dfLightingSales$Sales_Dt)
dfLightingSales1                      = subset(dfLightingSales, Sales_Dt>= dateRange)
dfLightingSales1$Month                = month(dfLightingSales1$Sales_Dt)
dfLightingSalesSub                    = aggregate(dfLightingSales1$Quantity_Sold, by = list(dfLightingSales1$Product_SKU, dfLightingSales1$Month), FUN=sum)
colnames(dfLightingSalesSub)          = c("Product_SKU", "Month","Quantity_Sold")
dfLightingSummary                     = full_join(dfLightingSalesSub, dfProductInFront1yearTotal, by = c("Product_SKU", "Month"))
dfLightingSummary                     = dfLightingSummary[order(dfLightingSummary$Product_SKU, dfLightingSummary$Month),]
reqdcols                              = c("Product_SKU")
dfLightingProducts                    = dfLightingSales1[,reqdcols]
dfLightingProducts                    = unique(dfLightingProducts)
dfLight12Months                       = merge(dfLightingProducts,dfMonths, by=NULL)
colnames(dfLight12Months)             = c("Product_SKU", "Month")
dfLight12Months                       = dfLight12Months[order(dfLight12Months$Product_SKU),]
dfLightingProducts                    = left_join(dfLight12Months, dfLightingSummary, by = c("Product_SKU", "Month"))
dfLightingProducts[is.na(dfLightingProducts)] = 0
dfPrdSubsetL                          = dfLightingProducts$Product_SKU
dfPrdSubsetL                          = unique(dfPrdSubsetL)

#########################################################################################################
#
#            The UI Component
#
#########################################################################################################

ui = navbarPage(
      theme = shinytheme("united"),
                  "Category",
                  tabPanel("Electricity",
                           tags$head(
                             tags$style(HTML("
                                             @import url('//fonts.googleapis.com/css?family=Lobster|Cabin:400,700');
                                             h1 {
                                             font-family: 'Lobster', cursive;
                                             font-weight: 500;
                                             line-height: 1.1;
                                             color: #000000;
                                             }
                                             
                                             "))
                             ), 
                           fluidRow(
                                    column(2, offset = 2, div(img(src = "https://lh3.googleusercontent.com/pXmTzdJXXIl491mE5ZYkaBdjAjWTVw7QQAynjcfkNBF7NqyeXuSUYRU_y4qfhPItl15MrMfCpLULnKEpJHsBszHkSOuRth85_Xt_0eU6KlklUEJumrfIUc1KJOz1s8mx0INdjitZkKpyhmximDBtXRCwT3SedUDJzjKaP5hgjFLftQlaOQaHNY6RHFR4KWKcYKka7ejZiFowD3RY1c96yVmLiexzgFhiw5t_NiLoA51HD28TQ4FqHBqNOYg6u9JJhA2XS6VsTa6TOAQCLaUZ1PjinPyezWVyYFRrcaShwGhuOvxKaL2DLreQ_XBq3MUi9sD20R-1osnd0rSzEi1Rws3TtXkvzRqR5OnjYT9Cro_-t5OlHvoAGddfVb4Bmo_jowu6UYeAgnK5tYqfwpTg1LRHSR7ndCt_bG9WUjYXCLFL9JniHtaXGfz3-lwvjMnltM0gaL2zE2_WVCIplDCtikkVqSY0amUuIsQn_35VBjPY9ideGtArqUrq7ZKVTCmBUDi43CL3brw1KgCsWkL7cMaJHJ2DiwXJji4o3KWa2xC9v1T1R6jvfBwBACJcQnzI6vT3rdXBYP1YefDoZUaGMwmkylLAnhmHdGtFN_iPJEH-G33jRZDsQQkfDRwclIiUIEQYE4CKoxlUnnQzzdEoEZdXQ2CEQPjBU7RxVxZoGRo=w273-h187-no", height = 70, width = 125), style="text-align: right;")),
                                    column(6, div(headerPanel("Product Display Recommendation Tool"), style="text-align: left;"))
                           ),
                           tags$p(),
                           tabsetPanel(
                                      tabPanel("Recommendations",
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               column(3,wellPanel(
                                                                  sliderInput("range1", "Range:", min = 1,  max = 20, value = 3)
                                                                  )
                                                      ),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               column(6, div(tableOutput("tblElectriRecomm"), style = "font-size:80%"))
                                              ),
                                      tabPanel("Analyze Past Displays",
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               column(3, wellPanel(
                                                                  dateInput("dateFrom", label = h6("From Date"), format = "yyyy-mm-dd"),
                                                                  dateInput("dateTo", label = h6("To Date"), format = "yyyy-mm-dd"),
                                                                  tags$p(),
                                                                  tags$p(),
                                                                  tags$p(),
                                                                  actionButton("btnSubmit", "Submit", class = "btn-primary")
                                                                  )
                                                      ),
                                               column(6, div(dataTableOutput("tblPrdtsSelected"), style = "font-size:80%"))
                                              ),
                                      tabPanel("Product Performance",
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               sidebarPanel(width=2,
                                                            selectInput(
                                                                'selIProductSKU1', 'Choose Product SKU', choices = dfPrdSubsetE, width = 200,
                                                            selectize = FALSE
                                                           )
                                               ),
                                               mainPanel(
                                                 plotOutput("electrSKUSoldPlot")
                                               )
                                      ),
                                      tabPanel("Product Details", 
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               div(dataTableOutput("tblElectricity"), style = "font-size:80%")
                                      )                                      
                           )
                  ),
                  tabPanel("Tooling",
                            fluidRow(
                                    column(2, offset = 2, div(img(src = "https://lh3.googleusercontent.com/pXmTzdJXXIl491mE5ZYkaBdjAjWTVw7QQAynjcfkNBF7NqyeXuSUYRU_y4qfhPItl15MrMfCpLULnKEpJHsBszHkSOuRth85_Xt_0eU6KlklUEJumrfIUc1KJOz1s8mx0INdjitZkKpyhmximDBtXRCwT3SedUDJzjKaP5hgjFLftQlaOQaHNY6RHFR4KWKcYKka7ejZiFowD3RY1c96yVmLiexzgFhiw5t_NiLoA51HD28TQ4FqHBqNOYg6u9JJhA2XS6VsTa6TOAQCLaUZ1PjinPyezWVyYFRrcaShwGhuOvxKaL2DLreQ_XBq3MUi9sD20R-1osnd0rSzEi1Rws3TtXkvzRqR5OnjYT9Cro_-t5OlHvoAGddfVb4Bmo_jowu6UYeAgnK5tYqfwpTg1LRHSR7ndCt_bG9WUjYXCLFL9JniHtaXGfz3-lwvjMnltM0gaL2zE2_WVCIplDCtikkVqSY0amUuIsQn_35VBjPY9ideGtArqUrq7ZKVTCmBUDi43CL3brw1KgCsWkL7cMaJHJ2DiwXJji4o3KWa2xC9v1T1R6jvfBwBACJcQnzI6vT3rdXBYP1YefDoZUaGMwmkylLAnhmHdGtFN_iPJEH-G33jRZDsQQkfDRwclIiUIEQYE4CKoxlUnnQzzdEoEZdXQ2CEQPjBU7RxVxZoGRo=w273-h187-no", height = 70, width = 125), style="text-align: right;")),
                                    column(6, div(headerPanel("Product Display Recommendation Tool"), style="text-align: left;"))
                                    ),
                            tags$p(),
                            tabsetPanel(
                                      tabPanel("Recommendations",
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               column(3,wellPanel(
                                                                  sliderInput("range2", "Range:", min = 1,  max = 20, value = 3)
                                                                  )
                                                      ),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               column(6, div(tableOutput("tblToolingRecomm"), style = "font-size:80%"))
                                            ),
                                      tabPanel("Analyze Past Displays",
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               column(3, wellPanel(
                                                 dateInput("dateFrom2", label = h6("From Date"), format = "yyyy-mm-dd"),
                                                 dateInput("dateTo2", label = h6("To Date"), format = "yyyy-mm-dd"),
                                                 tags$p(),
                                                 tags$p(),
                                                 tags$p(),
                                                 actionButton("btnSubmit2", "Submit", class = "btn-primary")
                                               )
                                               ),
                                               column(6, div(dataTableOutput("tblPrdtsSelected2"), style = "font-size:80%"))
                                      ),    
                                      tabPanel("Product Performance",
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               sidebarPanel(width=2,
                                                            selectInput(
                                                              'selIProductSKU2', 'Choose Product SKU', choices = dfPrdSubsetT, width = 200,
                                                              selectize = FALSE
                                                            )
                                               ),
                                               mainPanel(
                                                 plotOutput("toolSKUSoldPlot")
                                               )
                                      ),
                                      tabPanel("Product Details", 
                                               tags$p(),
                                               tags$p(),
                                               tags$p(),
                                               div(dataTableOutput("tblTooling"), style = "font-size:80%")
                                      )                                      
                            )
                           ),
                  tabPanel("Lighting",
                            fluidRow(
                                    column(2, offset = 2, div(img(src = "https://lh3.googleusercontent.com/pXmTzdJXXIl491mE5ZYkaBdjAjWTVw7QQAynjcfkNBF7NqyeXuSUYRU_y4qfhPItl15MrMfCpLULnKEpJHsBszHkSOuRth85_Xt_0eU6KlklUEJumrfIUc1KJOz1s8mx0INdjitZkKpyhmximDBtXRCwT3SedUDJzjKaP5hgjFLftQlaOQaHNY6RHFR4KWKcYKka7ejZiFowD3RY1c96yVmLiexzgFhiw5t_NiLoA51HD28TQ4FqHBqNOYg6u9JJhA2XS6VsTa6TOAQCLaUZ1PjinPyezWVyYFRrcaShwGhuOvxKaL2DLreQ_XBq3MUi9sD20R-1osnd0rSzEi1Rws3TtXkvzRqR5OnjYT9Cro_-t5OlHvoAGddfVb4Bmo_jowu6UYeAgnK5tYqfwpTg1LRHSR7ndCt_bG9WUjYXCLFL9JniHtaXGfz3-lwvjMnltM0gaL2zE2_WVCIplDCtikkVqSY0amUuIsQn_35VBjPY9ideGtArqUrq7ZKVTCmBUDi43CL3brw1KgCsWkL7cMaJHJ2DiwXJji4o3KWa2xC9v1T1R6jvfBwBACJcQnzI6vT3rdXBYP1YefDoZUaGMwmkylLAnhmHdGtFN_iPJEH-G33jRZDsQQkfDRwclIiUIEQYE4CKoxlUnnQzzdEoEZdXQ2CEQPjBU7RxVxZoGRo=w273-h187-no", height = 70, width = 125), style="text-align: right;")),
                                    column(6, div(headerPanel("Product Display Recommendation Tool"), style="text-align: left;"))
                                    ),
                           tags$p(),
                            tabsetPanel(
                                       tabPanel("Recommendations",
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                column(3,wellPanel(
                                                          sliderInput("range3", "Range:", min = 1,  max = 20, value = 3)
                                                                  )
                                                      ),
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                column(6, div(tableOutput("tblLightingRecomm"), style = "font-size:80%"))
                                                ),
                                       tabPanel("Analyze Past Displays",
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                column(3, wellPanel(
                                                  dateInput("dateFrom3", label = h6("From Date"), format = "yyyy-mm-dd"),
                                                  dateInput("dateTo3", label = h6("To Date"), format = "yyyy-mm-dd"),
                                                  tags$p(),
                                                  tags$p(),
                                                  tags$p(),
                                                  actionButton("btnSubmit3", "Submit", class = "btn-primary")
                                                )
                                                ),
                                                column(6, div(dataTableOutput("tblPrdtsSelected3"), style = "font-size:80%"))
                                       ),    
                                       tabPanel("Product Performance",
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                sidebarPanel(width=2,
                                                             selectInput(
                                                               'selIProductSKU3', 'Choose Product SKU', choices = dfPrdSubsetL, width = 200,
                                                               selectize = FALSE
                                                             )
                                                ),
                                                mainPanel(
                                                  plotOutput("lightSKUSoldPlot")
                                                )
                                       ),
                                        tabPanel("Product Details", 
                                                tags$p(),
                                                tags$p(),
                                                tags$p(),
                                                div(dataTableOutput("tblLighting"), style = "font-size:80%")
                                                )                                       
                                        )
                         )  
)


#########################################################################################################
#
#            The Server Component
#
#########################################################################################################

server <- function(input, output){
                output$tblElectricity = renderDataTable({ dfElectricity }, server = TRUE )
                output$tblTooling     = renderDataTable({ dfTooling }, server = TRUE )
                output$tblLighting    = renderDataTable({ dfLighting }, server = TRUE )

                # Sort in descending order of Increase_Qty_Sales for Electricity
                dfRecommElectri  = subset(dfRecommendation, Aisle_No == 3)
                dfRecommElectri  = dfRecommElectri[order(-dfRecommElectri$Increase_Qty_Sales),]
                reqdcols         = c("Product_SKU", "Product_Desc", "Recomm_Prdt1", "Recomm_Prdt2", "Recomm_Prdt3")
                dfRecommElec     = dfRecommElectri[,reqdcols]
                dfRecommElec$Recomm_Prdt1[is.na(dfRecommElec$Recomm_Prdt1)] = ""
                dfRecommElec$Recomm_Prdt2[is.na(dfRecommElec$Recomm_Prdt2)] = ""
                dfRecommElec$Recomm_Prdt3[is.na(dfRecommElec$Recomm_Prdt3)] = ""
                colnames(dfRecommElec) = c("Product SKU", "Description", "Assosicated Product 1", "Assosicated Product 2", "Assosicated Product 3")
                output$tblElectriRecomm = renderTable({ head(dfRecommElec, n = input$range1) }, server = TRUE)
      
                # Sort in descending order of Increase_Qty_Sales for Tooling
                dfRecommTooling  = subset(dfRecommendation, Aisle_No == 10)
                dfRecommTooling  = dfRecommTooling[order(-dfRecommTooling$Increase_Qty_Sales),]
                reqdcols         = c("Product_SKU", "Product_Desc", "Recomm_Prdt1", "Recomm_Prdt2", "Recomm_Prdt3")
                dfRecommTool     = dfRecommTooling[,reqdcols]
                dfRecommTool$Recomm_Prdt1[is.na(dfRecommTool$Recomm_Prdt1)] = ""
                dfRecommTool$Recomm_Prdt2[is.na(dfRecommTool$Recomm_Prdt2)] = ""
                dfRecommTool$Recomm_Prdt3[is.na(dfRecommTool$Recomm_Prdt3)] = ""
                colnames(dfRecommTool) = c("Product SKU", "Description", "Assosicated Product 1", "Assosicated Product 2", "Assosicated Product 3")
                output$tblToolingRecomm = renderTable({ head(dfRecommTool, n = input$range2) }, server = TRUE)

                # Sort in descending order of Increase_Qty_Sales for Lighting
                dfRecommLighting = subset(dfRecommendation, Aisle_No == 13)
                dfRecommLighting = dfRecommLighting[order(-dfRecommLighting$Increase_Qty_Sales),]
                reqdcols         = c("Product_SKU", "Product_Desc", "Recomm_Prdt1", "Recomm_Prdt2", "Recomm_Prdt3")
                dfRecommLight    = dfRecommLighting[,reqdcols]
                dfRecommLight$Recomm_Prdt1[is.na(dfRecommLight$Recomm_Prdt1)] = ""
                dfRecommLight$Recomm_Prdt2[is.na(dfRecommLight$Recomm_Prdt2)] = ""
                dfRecommLight$Recomm_Prdt3[is.na(dfRecommLight$Recomm_Prdt3)] = ""
                colnames(dfRecommLight) = c("Product SKU", "Description", "Assosicated Product 1", "Assosicated Product 2", "Assosicated Product 3")
                output$tblLightingRecomm = renderTable({ head(dfRecommLight, n = input$range3) }, server = TRUE)
                

                observeEvent(input$btnSubmit, {
                                              fromDate            = format(input$dateFrom)
                                              toDate              = format(input$dateTo)
                                              dfFrontRowSalesSub  = subset(dfFrontRowSales, Sales_Dt >= fromDate & Sales_Dt <= toDate & Aisle_No == 3)
                                              if (nrow(dfFrontRowSalesSub) > 0) {
                                                dfTotalQuantitySold = aggregate(dfFrontRowSalesSub$Quantity_Sold, by = list(dfFrontRowSalesSub$Product_SKU), FUN = sum)
                                                colnames(dfTotalQuantitySold) = c("Product_SKU", "Qty")
                                                dfTotalAmountSold   = aggregate(dfFrontRowSalesSub$Amount_In_Euros, by = list(dfFrontRowSalesSub$Product_SKU), FUN = sum)
                                                colnames(dfTotalAmountSold) = c("Product_SKU", "Sales")
                                                dfAllDetails            = merge(dfTotalQuantitySold, dfTotalAmountSold, by ="Product_SKU")
                                                dfAllDetailsSrt          = dfAllDetails[order(-dfAllDetails$Qty),]
                                                colnames(dfAllDetailsSrt) = c("Product SKU", "Total quantitiy sold", "Total amount in Euros")
                                                output$tblPrdtsSelected = renderDataTable({ dfAllDetailsSrt }, server = TRUE)                                                
                                              }
                              })   

                observeEvent(input$btnSubmit2, {
                  fromDate2            = format(input$dateFrom2)
                  toDate2              = format(input$dateTo2)
                  dfFrontRowSalesSub2  = subset(dfFrontRowSales, Sales_Dt >= fromDate2 & Sales_Dt <= toDate2 & Aisle_No == 10)
                  if (nrow(dfFrontRowSalesSub2) > 0) {
                    dfTotalQuantitySold2 = aggregate(dfFrontRowSalesSub2$Quantity_Sold, by = list(dfFrontRowSalesSub2$Product_SKU), FUN = sum)
                    colnames(dfTotalQuantitySold2) = c("Product_SKU", "Qty")
                    dfTotalAmountSold2   = aggregate(dfFrontRowSalesSub2$Amount_In_Euros, by = list(dfFrontRowSalesSub2$Product_SKU), FUN = sum)
                    colnames(dfTotalAmountSold2) = c("Product_SKU", "Sales")
                    dfAllDetails2            = merge(dfTotalQuantitySold2, dfTotalAmountSold2, by ="Product_SKU")
                    dfAllDetailsSrt2          = dfAllDetails2[order(-dfAllDetails2$Qty),]
                    colnames(dfAllDetailsSrt2) = c("Product SKU", "Total quantitiy sold", "Total amount in Euros")
                    output$tblPrdtsSelected2 = renderDataTable({ dfAllDetailsSrt2 }, server = TRUE)                                                
                  }
                })   
                
                observeEvent(input$btnSubmit3, {
                  fromDate3            = format(input$dateFrom3)
                  toDate3              = format(input$dateTo3)
                  dfFrontRowSalesSub3  = subset(dfFrontRowSales, Sales_Dt >= fromDate3 & Sales_Dt <= toDate3 & Aisle_No == 13)
                  if (nrow(dfFrontRowSalesSub3) > 0) {
                    dfTotalQuantitySold3 = aggregate(dfFrontRowSalesSub3$Quantity_Sold, by = list(dfFrontRowSalesSub3$Product_SKU), FUN = sum)
                    colnames(dfTotalQuantitySold3) = c("Product_SKU", "Qty")
                    dfTotalAmountSold3   = aggregate(dfFrontRowSalesSub3$Amount_In_Euros, by = list(dfFrontRowSalesSub3$Product_SKU), FUN = sum)
                    colnames(dfTotalAmountSold3) = c("Product_SKU", "Sales")
                    dfAllDetails3            = merge(dfTotalQuantitySold3, dfTotalAmountSold3, by ="Product_SKU")
                    dfAllDetailsSrt3          = dfAllDetails3[order(-dfAllDetails3$Qty),]
                    colnames(dfAllDetailsSrt3) = c("Product SKU", "Total quantitiy sold", "Total amount in Euros")
                    output$tblPrdtsSelected3 = renderDataTable({ dfAllDetailsSrt3 }, server = TRUE)                                                
                  }
                })       
                
                ### Reactive bar plot for Product SKUs in Electricity department
                observeEvent(input$selIProductSKU1, {
                  inputSKU   = input$selIProductSKU1
                  dfElectricForPlot = subset(dfElectricalProducts, Product_SKU == inputSKU)
                  output$electrSKUSoldPlot <- renderPlot({
                              barplot(dfElectricForPlot$Quantity_Sold, dfElectricForPlot$Month,
                                      width = 0.7, col = "lightgreen",
                                      main = "Quantity sold in the last one year",
                                      ylab="Quantity Sold", xlab="Month", space = 0.7, legend.text = FALSE,
                                      names.arg = c("Jan", "Feb", "Mar", "Apr",
                                                    "May", "Jun", "Jul", "Aug", "Sep",
                                                    "Oct", "Nov", "Dec"))
                                      })
                  
              })
                
                ### Reactive bar plot for Product SKUs in Tooling department
                observeEvent(input$selIProductSKU2, {
                  inputSKU2   = input$selIProductSKU2
                  dfToolingForPlot = subset(dfToolingProducts, Product_SKU == inputSKU2)
                  output$toolSKUSoldPlot <- renderPlot({
                    barplot(dfToolingForPlot$Quantity_Sold, dfToolingForPlot$Month,
                            width = 0.7, col = "lightgreen",
                            main = "Quantity sold in the last one year",
                            ylab="Quantity Sold", xlab="Month", space = 0.7, legend.text = FALSE,
                            names.arg = c("Jan", "Feb", "Mar", "Apr",
                                          "May", "Jun", "Jul", "Aug", "Sep",
                                          "Oct", "Nov", "Dec"))
                  })

                })
                
                ### Reactive bar plot for Product SKUs in Lighting department
                observeEvent(input$selIProductSKU3, {
                  inputSKU3   = input$selIProductSKU3
                  dfLightingForPlot = subset(dfLightingProducts, Product_SKU == inputSKU3)
                  output$lightSKUSoldPlot <- renderPlot({
                    barplot(dfLightingForPlot$Quantity_Sold, dfLightingForPlot$Month,
                            width = 0.7, col = "lightgreen",
                            main = "Quantity sold in the last one year",
                            ylab="Quantity Sold", xlab="Month", space = 0.7, legend.text = FALSE,
                            names.arg = c("Jan", "Feb", "Mar", "Apr",
                                          "May", "Jun", "Jul", "Aug", "Sep",
                                          "Oct", "Nov", "Dec"))
                  })

                })
                                                
      }


#########################################################################
#
#            Calling the ui and server components
#
#########################################################################
#shinyApp(ui = ui, server = server, options(shiny.port = 5010))
shinyApp(ui = ui, server = server)

