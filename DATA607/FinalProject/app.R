

library(shiny)
library(shinyWidgets)
library(httr)


#######################################
#
#    1) Method
#    2) Duration
#
#    --- 4 of the 6 Keplerian Elements ---  note 5 and 6 are very similar
#    3) Eccentricity - pl_orbeccen - shap of orbit
#    4) Distance = Semi Major Axis (Apoapsis + Periapsis/2) avg distance - pl_orbsmax  [au]
#    5) Inclination - pl_orbincl ( angle of orbit to our line of sight) [deg]
#    6) Orientation = Argument of Periastron - pl_orblper - [deg]
#
#    7) Release Date
#
#######################################


# ----------------  Mainline Code Executes Once  -----------------------------------


base_url="https://exoplanetarchive.ipac.caltech.edu/TAP/"

select_url="sync?query=select+pl_name,disc_locale,discoverymethod,"
select_url=paste0(select_url,"pl_orbper,pl_orbeccen,pl_orbsmax,pl_orbincl,pl_orblper,releasedate+")
where_url="from+ps+where+default_flag+=+1+and+pl_controv_flag+=+0+"
where_url=paste0(where_url,"order+by+pl_name+desc+&format=csv")
url=paste0(base_url,select_url,where_url)







# print(paste("Getting data from archive. Start: ", Sys.time()) )
exoplanet.raw <- GET(url)
# print(paste("Getting data from archive. End: ", Sys.time()) )







if (exoplanet.raw$status_code != 200) {
  
   print("Error occurred retrieving data. Please try another time.")
  
} else
{
  exoplanets.df  <- read.csv(text=content(exoplanet.raw))
}






# rename columns so the average ordinary person can understand

names(exoplanets.df) <- c("planet", "location", "method", "duration", "eccentricity", "distance", "inclination", "orientation", "release_date")



factor.methods <- levels( factor( exoplanets.df$method ) )
factor.methods <- c("ALL",factor.methods)

exoplanets.df$duration<-as.integer(exoplanets.df$duration)

exoplanets.df$inclination<-round(exoplanets.df$inclination,2)
exoplanets.df$distance<-round(exoplanets.df$distance,2)
exoplanets.df$eccentricity<-round(exoplanets.df$eccentricity,2)
exoplanets.df$orientation<-round(exoplanets.df$orientation,2)

# print(head(exoplanets.df))

min_duration=0
max_duration=max(exoplanets.df$duration,na.rm = TRUE)

min_eccentricity=min(exoplanets.df$eccentricity,na.rm = TRUE)
max_eccentricity=max(exoplanets.df$eccentricity,na.rm = TRUE)

min_inclination=min(exoplanets.df$inclination,na.rm = TRUE)
max_inclination=max(exoplanets.df$inclination,na.rm = TRUE)

min_orientation=min(exoplanets.df$orientation,na.rm = TRUE)
max_orientation=max(exoplanets.df$orientation,na.rm = TRUE)

min_release_date=min(exoplanets.df$release_date,na.rm = TRUE)
max_release_date=Sys.Date()


ui <- fluidPage(
  titlePanel("                                        Exoplanets"),
  
  # Sidebar layout contains sidebar panel and main panel
  sidebarLayout(  
    sidebarPanel(

      selectInput("method","Choose the method",  choices = factor.methods, selected = factor.methods[1]),
      
      br(),br(),br(),

      selectInput("location","Choose the location",  choices = c("ALL", "Ground", "Space"), selected = "ALL"),
      
      br(),br(),br(),

      numericRangeInput(
        inputId = "eccentricity_id", label = "Eccentricity Range:",
        value = c( 0, 1),
        min=0,  max=1,    step=.01
      ),      
      br(),br(),br(),

      numericRangeInput(
        inputId = "duration_id", label = "Duration Range (Days):",
       value=c(min_duration,max_duration),
       min=0, step=1000
      ),

      br(),br(),br(),
      
      numericRangeInput(
        inputId = "inclination_id", label = "Inclination (Degrees):",
        value=c(min_inclination,max_inclination)
        
      ),
      
      br(),br(),br(),
      
      
     dateRangeInput("date_range", "Release-Date Range", start  = min_release_date, end=max_release_date),
 
      em("Check To Omit Records with No Value"),
      checkboxInput("rm.na_inclination", label = "Inclination", value = FALSE),
      checkboxInput("rm.na_orientation", label = "Orientation", value = FALSE),
    
      br(),br(),br(),
      actionButton("submitter","Submit"),
      actionButton("reset_input", "Reset")
      
      ),             # end of sidebar panel
    
 
    mainPanel(
      tabsetPanel(
        tabPanel("Summaries",
                 br(),br(),
                 h1("                      Summary Data "),
                 textOutput("exo.subset.rows", inline = TRUE),
                 br(),br(),
                 br(),br(),
                 tableOutput("exo.table"),
                 br(),br()
          ),
        tabPanel("Details",
                 br(),br(),
                 h1("                      Detail Data "),
                 br(),br(),
                 br(),br(),
                 
                 dataTableOutput("exo.data.table")),
     
         tabPanel("Graphics",
               plotOutput("plot"),            # duration
               br(),br(),
               plotOutput("plot4"),           # distance
               br(),br(),
               plotOutput("plot2"),           # eccentricity
               br(),br(),
               plotOutput("plot3")            # inclination
            ),
        tabPanel("Reference",
                 br(),br(),
                 br(),br(),br(),br(),br(),
                 
                 HTML('
                       <style type="text/css">
                      .tab { margin-left: 40px; }
                      </style>

                      <b>Duration</b> 
                      <p class="tab">The number of Earth days it takes for the planet to orbit its star.</p>
                      <br><br>

                      <b>Distance</b> 
                      <p class="tab">The scientific term is the Semi Major Axis.
                      <br>
                      Calculated as (Apoapsis + Periapsis/2)  
                      <br>
                      Its the halfway point between the shortest and furthest points between the planet and the star.
                      <br>
                      Measured in Astronomical Units. (AUs)
                      </p>
                      <br><br>

                      <b>Eccentricity</b> 
                      <p class="tab">measures how "squashed" an orbit is from a perfect circle.
                      <br>
                      0 = perfect circle. 1 = straight line.  
                      <br>
                      In practice most orbits are less than .1 and cant exceed .95
                      </p>
                      <br><br>

                      <b>Inclination</b> 
                      <p class="tab">Angle of orbit to our line of sight.
                      <br>
                      Measured in degrees 
                      <br>
                      </p>
                      <br><br>
                      
                      <b>Orientation</b> 
                      <p class="tab">Scientific term is Argument of Periastron.
                      <br>
                      Its also an angle of orbit to the plane of the system but it includes a longitudinal element. This definition is not confirmed.
                      <br>
                      Measured in longitidinal degrees 
                      <br>
                      </p>
                      <br><br>
                      '),
    
                 br(),br(),br(), 
                 
                 helpText(a(href="http://stat.duke.edu/~mc301/shiny/applets.html", target="_blank", "View Presentation"))
    
        )
      
        
        )
      )        # end of main panel
    
  )            # end of sidebar layout
)


server <- function(input, output, session) {

  # -------------------------       SUBMIT : RUN SUBSET QUERY        -----------------------------------  
  
   tmp.ra <- reactive({                 # tmp.ra  is a "reactive expression"

    
    input$submitter                  # putting it here means each time you click 
    
    isolate({            # putting isolate here means this function wont invoke when input$method is changed
      
      
      if ( input$method == "ALL")
      {
        ss_tmp.df<-exoplanets.df
      }
      else
      {
      ss_tmp.df<-subset(exoplanets.df, method %in%  input$method)
      }
      print(nrow(ss_tmp.df))

      if ( input$location == "Ground")
      {
        ss_tmp.df<-subset(exoplanets.df, location=="Ground")
      }
      print(nrow(ss_tmp.df))
      
      
      if ( input$location == "Space")
      {
        ss_tmp.df<-subset(exoplanets.df, location=="Space")
      }
      print(nrow(ss_tmp.df))
      
      
      ss_tmp.df<-subset(ss_tmp.df, release_date >= input$date_range[1] & release_date <= input$date_range[2] )
      print(nrow(ss_tmp.df))


      ss_tmp.df<-subset(ss_tmp.df, duration >= input$duration_id[1] & duration <= input$duration_id[2] )
      print(nrow(ss_tmp.df))

      
      
      ss_tmp.df<-subset(ss_tmp.df, is.na(inclination) | (inclination >= input$inclination_id[1] & inclination <= input$inclination_id[2]) )
      print(nrow(ss_tmp.df))

      
      ss_tmp.df<-subset(ss_tmp.df, is.na(eccentricity) | (eccentricity >= input$eccentricity_id[1] & eccentricity <= input$eccentricity_id[2]) )
      print(nrow(ss_tmp.df))
      
      if (input$rm.na_inclination) {
        ss_tmp.df<- ss_tmp.df[!is.na(ss_tmp.df$inclination), ]    
      }
      
      if (input$rm.na_orientation) {
        ss_tmp.df<- ss_tmp.df[!is.na(ss_tmp.df$orientation), ]    
      }

      return(ss_tmp.df)
    })
   
    
  })
  
 
  output$exo.data.table <- renderDataTable({
    tmp.ra()
  })
  
  
  output$exo.subset.rows <- renderText({
    rt.df<-tmp.ra()
    n_ss<-nrow(rt.df)
    n_tot<-nrow(exoplanets.df)
    n_txt<-paste(" ", n_ss, " rows in subset. ", n_tot, " rows in total set.")
    return(n_txt)
  })
  
 
# -------------------------       GRAPHICS        -----------------------------------  
    
  output$plot <- renderPlot({
    rp.df<-tmp.ra()
    
    hist(rp.df$duration, main="Orbital Duration (Days)",
         xlab="Earth Days", freq=TRUE, breaks=100)
  })
  
  
  
  output$plot2 <- renderPlot({
    rp.df<-tmp.ra()
    
    hist(rp.df$eccentricity, main="Orbital Eccentricity",
         xlab="Eccentricity", freq=TRUE, breaks=100)
  })
  
  
  output$plot3 <- renderPlot({
    rp.df<-tmp.ra()
    
    hist(rp.df$inclination, main="Orbital Inclination",
         xlab="Inclination", freq=TRUE, breaks=100)
  })
  
  
  output$plot4 <- renderPlot({
    rp.df<-tmp.ra()
    
    hist(rp.df$distance, main="Orbital Distance (AUs)",
         xlab="Distance", freq=TRUE, breaks=100)
  })
  
  
 
  # -------------------------       SUMMARY TABLE        -----------------------------------  
  
  
  output$exo.table <- renderTable({
    
    tmp.df=tmp.ra()
    
    # average orbital period (where orbital period is not null)
    
    duration_m<-round(mean(tmp.df$duration[!is.na(tmp.df$duration)]),3)
    
    if (is.na(duration_m)) 
    { 
      duration_m<-0 
    }
    
   
    # number of rows where orbital period is not null
    duration_n<-length(tmp.df$duration[!is.na(tmp.df$duration)])
    
    if (is.na(duration_n)) 
    { 
      duration_n<-0 
    }
    
    min_duration_s=min(tmp.df$duration,na.rm = TRUE)
    max_duration_s=max(tmp.df$duration,na.rm = TRUE)
    
    
    # --------- orbital distance
    
    # average distance (where distance is not null)
    
    distance_m<-round(mean(tmp.df$distance[!is.na(tmp.df$distance)]),3)
    
    if (is.na(distance_m)) 
    { 
      distance_m<-0 
    }
    
    
    # number of rows where orbital period is not null
    distance_n<-length(tmp.df$distance[!is.na(tmp.df$distance)])
    
    if (is.na(distance_n)) 
    { 
      distance_n<-0 
    }
    
    min_distance_s=min(tmp.df$distance,na.rm = TRUE)
    max_distance_s=max(tmp.df$distance,na.rm = TRUE)
  
    
    
    # --------- orbital inclination
    
    # average orbital period (where orbital period is not null)
    
    inclination_m<-round(mean(tmp.df$inclination[!is.na(tmp.df$inclination)]),3)
    
    if (is.na(inclination_m)) 
    { 
      inclination_m<-0 
    }
    
    
    # number of rows where orbital period is not null
    inclination_n<-length(tmp.df$inclination[!is.na(tmp.df$inclination)])
    
    if (is.na(inclination_n)) 
    { 
      inclination_n<-0 
    }

    min_inclination_s=min(tmp.df$inclination,na.rm = TRUE)
    max_inclination_s=max(tmp.df$inclination,na.rm = TRUE)
    
    
    # --------- orbital eccentricity
    
    # average orbital eccentricity (where orbital eccentricity is not null)
    
    eccentricity_m<-round(mean(tmp.df$eccentricity[!is.na(tmp.df$eccentricity)]),3)
    
    if (is.na(eccentricity_m)) 
    { 
      eccentricity_m<-0 
    }
    
    
    # number of rows where orbital eccentricity is not null
    eccentricity_n<-length(tmp.df$eccentricity[!is.na(tmp.df$eccentricity)])
    
    if (is.na(eccentricity_n)) 
    { 
      eccentricity_n<-0 
    }
    
    
    min_eccentricity_s=min(tmp.df$eccentricity,na.rm = TRUE)
    max_eccentricity_s=max(tmp.df$eccentricity,na.rm = TRUE)
    
 
    
    
    # total rows 
    orbtot_n<-nrow(tmp.df)

   
    # average orientation (where orientation is not null)
    
    orientation_m<-round(mean(tmp.df$orientation[!is.na(tmp.df$orientation)]),3)
    
    if (is.na(orientation_m)) 
    { 
      orientation_m<-0 
    }
    
    
    # number of rows where orbital period is not null
    orientation_n<-length(tmp.df$orientation[!is.na(tmp.df$orientation)])
    
    if (is.na(orientation_n)) 
    { 
      orientation_n<-0 
    }
    
    min_orientation_s=min(tmp.df$orientation,na.rm = TRUE)
    max_orientation_s=max(tmp.df$orientation,na.rm = TRUE)
    
    
    
    exo.table.df <- data.frame(               				# create the dataframe schema
      category=character(),
      missing_values=integer(),
      mean=double(),
      min=double(),
      max=double()
      
    )
  
    
    exo.table.df<-rbind(exo.table.df, data.frame(category="Duration (Days)", missing_values=orbtot_n-duration_n, mean=duration_m, min=min_duration_s, max=max_duration_s))
    exo.table.df<-rbind(exo.table.df, data.frame(category="Distance (AUs)", missing_values=orbtot_n-distance_n, mean=distance_m, min=min_distance_s, max=max_distance_s))
    exo.table.df<-rbind(exo.table.df, data.frame(category="Eccentricity", missing_values=orbtot_n-eccentricity_n, mean=eccentricity_m, min=min_eccentricity_s, max=max_eccentricity_s))
    exo.table.df<-rbind(exo.table.df, data.frame(category="Inclination (Degrees)", missing_values=orbtot_n-inclination_n, mean=inclination_m, min=min_inclination_s, max=max_inclination_s))
    exo.table.df<-rbind(exo.table.df, data.frame(category="Orientation (Degrees)", missing_values=orbtot_n-orientation_n, mean=orientation_m, min=min_orientation_s, max=max_orientation_s))
    
    
    return(exo.table.df)
  }
  
  )
  
  
  
}

# Run the application 
shinyApp(ui = ui, server = server)

