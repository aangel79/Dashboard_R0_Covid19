#### INSTALL PACKAGES ###
#install.packages("shiny")
#install.packages("EpiEstim")
#install.packages("NobBS")}
#install.packages("jsonlite")
#install.packages("tidyverse")
#install.packages("ggplot2")
#install.packages("rsconnect") ## Connect with ShinyApps

### LOAD LIBRARIES ###
library(shiny)
library(dplyr)
library(jsonlite)
library(tidyverse)
library(ggplot2)
library(EpiEstim)

### DIRECTORY PARAMETERS ###
#file_path <- "C:/Users/Leonardo REGINO/Documents/DATAMINH/Covid19/Dashboards/Data"
#file_name <- "Covid19_Colombia.json"
#datosImport <- fromJSON(txt = paste(file_path, file_name, sep = "/") )

url <- "https://www.datos.gov.co/resource/gt2j-8ykr.json?$limit="
nb_limit <- "1000"
datosImport2 <- fromJSON(paste0(url,nb_limit))
  
datosImport$nb <-1 # To be able to count/aggregate

  

#datosImport <- datosImport %>% add_column(nb = 1)


#datosImport$fecha_de_notificaci_n <-  as.character(as.Date(datosImport$fecha_de_notificaci_n))
datosImport2$fecha_de_notificaci_n <- as.Date(datosImport2$fecha_de_notificaci_n)
for(i in c("nb")){
  datosImport2[,i] <- 1
}

datosImport <- data.frame(datosImport2)



ui <- fluidPage(
  
  titlePanel("Evolution of R0 - Covid19"),
  
  sidebarLayout(
    
    sidebarPanel(
      uiOutput("Dept_Filter"),
      uiOutput("City_Filter"),
      uiOutput("Date_Range")
      ), 
      mainPanel(
        plotOutput("ts_plot"),
        #tableOutput("test_data")
      )
    )
  )



server <- function(input, output) {
  
  data <- reactive({

    if (!is.null(input$Depto) & !is.null(input$City) ) {
      
      d = datosImport %>%
        filter(departamento == input$Depto) %>% 
        filter(ciudad_de_ubicaci_n == input$City) %>% 
        filter(fecha_de_notificaci_n > input$NotifDate[1] & fecha_de_notificaci_n < input$NotifDate[2] )
    }
    
    else{
      d = datosImport
    }
    # d = d %>% 
    #   group_by(fecha_de_notificaci_n) %>% 
    #   summarise_if(is.numeric, sum, na.rm=TRUE)
    
    d
  })
  
  output$Dept_Filter <- renderUI({
    
    selectizeInput('Depto', 'Select a Department', choices = c("Choose a Department" = "", levels(factor(datosImport$departamento) ) ) )
    
  })
  
  output$City_Filter <- renderUI({
  
    selectizeInput('City', 'Select a City', choices = c("Choose a city" = "", levels(factor(datosImport[ datosImport$departamento ==  input$Depto, 'ciudad_de_ubicaci_n'] ) ) ) )    
    
  })
  
  output$Date_Range <- renderUI({
    
    dateRangeInput('NotifDate',
                  label = 'Filter by Notification Date:',
                  start =  min(as.Date(datosImport$fecha_de_notificaci_n)) , end = max(as.Date(datosImport$fecha_de_notificaci_n))
    )
    
  })
  
  # plot time series
  output$ts_plot <- renderPlot({
    
    data <- data()
    
    data <- data %>% 
      group_by(fecha_de_notificaci_n) %>% 
      summarise_if(is.numeric, sum, na.rm=TRUE)
    
    
    data <- data[seq(4, nrow(data)),]
    data <- as.data.frame(data)
    
    
    data <- data %>%
      rename(
        dates = fecha_de_notificaci_n,
        I = nb
      )
    
    
    rest <- estimate_R(
      data,
      method = "uncertain_si",
      config = make_config(
        list(
          mean_si = 2.6, 
          std_mean_si = 1,
          min_mean_si = 1, 
          max_mean_si = 4.2,
          std_si = 1.5, 
          std_std_si = 0.5,
          min_std_si = 0.5, 
          max_std_si = 2.5,
          n1 = 100, n2 = 100
        )
      )
    )
    
    plot(rest)
    
  })
  
  output$test_data <- renderTable({
    data <- data()
    
    data
  })

}


shinyApp(ui = ui, server = server )

