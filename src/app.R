# Source Code

{
  # Check if the following packages are installed
  packages <- c("rstudioapi", "shiny", "shinydashboard", 
                "shinyjs", "shinyalert", "shinyWidgets", 
                "DT", "dplyr")
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = F)) {
      install.packages(pkg)
    }
  }
  
  # load libraries
  library(rstudioapi)
  setwd(dirname(getActiveDocumentContext()$path)) # Set directory to location of this script
  library(shiny)
  library(shinydashboard)
  library(shinyjs)
  library(shinyalert)
  library(shinyWidgets)
  library(DT)
  library(dplyr)
  

  # Shiny app
  {
    
    ui <- fluidPage(
      useShinyjs(), # Required for "observeEvent" function to work in the server section
      
      headerPanel("Face Labeling"),
      
      sidebarPanel(
        
        selectInput("face", "Face Classification", 
                    choices = c(' ', 'humanoid', 'animal', 'non-face')),
        
        selectInput("color", "Image Color", 
                    choices = c(' ', 
                                "monochromatic (B&W, Sepia, etc)"="monochromatic", 
                                "polychromatic (color image)"="polychromatic")),
        
        selectInput("type", "Image Type", 
                    choices = c(' ', 'photograph', 'illustration')),
        
        hidden(selectInput("gender", 'Gender', 
                           choices = c(' ', 'male', 'female'))),
        
        hidden(selectInput("skin", "Skin Color", 
                           choices = c(' ', 'light', 'medium', 'dark'))),
        
        hidden(selectInput("race", 'Race', 
                           choices = c(' ', 
                                       'East/Southeast Asian (Japan, Philippines, etc)' = "Asian", 
                                       'Black', 
                                       'South Asian (India, Bangladesh, etc)' = "Indian", 
                                       'Latinx', 
                                       'Other', 
                                       'White'))),
        
        hidden(selectInput("age", 'Age', 
                           choices = c(' ', 'Adult', 'Child'))),
        
        hidden(selectInput("emotion", 'Emotion', 
                           choices = c(' ', 'Angry', 'Calm', 'Happy', 'Sad', 'Surprised'))),
        
        hidden(checkboxGroupInput("unsure", 'Were you unsure about any of the prior assignments?', 
                                  choices = c('Gender', 'Skin Color', 'Race', 'Age', 'Emotion'))),
        
        actionButton("goButton", "Next Image"),
        
        progressBar(id = "pb", value = 0, display_pct = T)
        
      ),
      
      
      mainPanel(
        verbatimTextOutput("nText"),
        
        # Render the image
        imageOutput("imageOutput", width = "100%", height = "100%")
      )
    )
    
    ##########################################
    server <- function(input, output,session) {
      
      # https://stackoverflow.com/questions/38302682/next-button-in-a-r-shiny-app
      # Initiating reactive values, these will remain through each event
      values <- reactiveValues(count=0, completed=0,
                               user_directory=NULL, user_file=NULL, 
                               user_list = NULL, user=NULL, df=NULL, 
                               columns=c('path', 'face', 'color', 'type',
                                                  'gender', 'skin', 'race', 'age',
                                                  'emotion', 'unsure'))
      paths <- reactiveValues(var=NULL, image=NULL, 
                              directory='directories.csv', 
                              assignments='assignments.csv')
      
      # On start up:
      if (isolate(values$count) == 0) {
        
        # Get user midway mapping
        ## Populate: values$user_directory and values$user_list
        values$user_directory <- read.csv(isolate(paths$directory))
        values$user_list <- as.character(isolate(values$user_directory$cnetid))
        
        # Have user choose their cnetid with pop-up dialog
        showModal(modalDialog(
          title = "Welcome!",
          "Please choose your cnetID:",
          radioButtons("cnetID", "", 
                       choices = isolate(values$user_list), 
                       selected=character(0)),
          footer = tagList(
            actionButton("ok", "OK")
          ),
          easyClose = F
        ))
        
        observeEvent(input$ok, {
          
          # Check if button (user) is selected
          if (length(input$cnetID) != 0) {
            
            # Remove pop-up
            removeModal()  
            
            # load data
            {
              
              # Find user-specific workding directory
              working_directory <- values$user_directory %>%
                filter(cnetid==input$cnetID) %>%
                select(2) %>%
                as.character()
              
              # Subset user assignments
              data_to_be_labeled <- read.csv(paths$assignments)
              ids_for_label <- data_to_be_labeled %>%
                filter(assigned==input$cnetID) %>%
                select(2)
              colnames(ids_for_label)[1] <- 'path'
              # Create full paths
              ids_for_label$path_full <- paste0(working_directory, ids_for_label$path)
              
              
              # Create file name!
              ## Populate: paths$user_file
              paths$user_file <- paste0('response_', input$cnetID, '.csv')
              
              # Create file if it does not exist
              if (!file.exists(paths$user_file)) {
                file.create(paths$user_file)
                write.table(t(values$columns),
                            file = paths$user_file,
                            sep = ",",
                            append = TRUE, quote = FALSE,
                            col.names = FALSE, row.names = FALSE)
                
                # Set difference unlabeled - labeled
                ## Populate: paths$var and paths$image
                paths$var <- ids_for_label$path
                paths$image <- ids_for_label$path_full
                
              }
              
              # Otherwise, take set difference between originally assigned and currently assigned
              else {
                
                # Read the existing data from the csv file
                ## Populate: values$df
                values$df <- read.csv(paths$user_file, header = TRUE)
                
                ids_labeled <- values$df %>% 
                  select(1) # First column should always be path
                colnames(ids_labeled)[1] <- 'path'
                
                # Set difference unlabeled - labeled
                ## Populate: paths$var and paths$image
                paths$var <- ids_for_label$path[!(ids_for_label$path %in% ids_labeled$path)]
                paths$image <- ids_for_label$path_full[!(ids_for_label$path %in% ids_labeled$path)]
                
                # Populate: values$completed
                values$completed <- nrow(values$df)
              }
              
            }
            
            values$count <- values$count + 1
          }
          
        })
        
      }
      
      # Show additional choices if humanoid is selected
      observeEvent(input$face,{
        if (input$face == 'humanoid') {
          show("gender")
          show("skin")
          show("race")
          show("age")
          show("emotion")
          show("unsure")
        } else {
          hide("gender")
          hide("skin")
          hide("race")
          hide("age")
          hide("emotion")
          hide("unsure")
        }
      })
      
      
      # Update progress
      observeEvent(values$count, {
        
        values$completed <- values$completed + 1
        
        # Update progress
        updateProgressBar(id = "pb", 
                          value = (values$completed/length(paths$image))*100)
        
      })
      
      
      # Reactive expression will only be executed when the button is clicked
      ntext <- eventReactive(input$goButton,{
        
        # Collect all results in dataframe
        Results <- data.frame(
          path = paths$var[values$count],
          face = input$face,
          color = input$color,
          type = input$type,
          gender = input$gender,
          skin = input$skin,
          race = input$race,
          age = input$age,
          emotion = input$emotion,
          unsure = list(paste(input$unsure, collapse = "; ")),
          stringsAsFactors = FALSE)
        
        # Rename columns to unify column names before appending
        colnames(Results) <- values$columns
        
        # Append new response row to existing responses
        write.table(Results, file = paths$user_file, sep = ',',
                    append = TRUE, quote = FALSE,
                    col.names = FALSE, row.names = FALSE)
        
        
        # Reset UI
        reset(id = "", asis = FALSE) 
        
        # Check if the counter `values$count` are not equal to the length of your questions
        # if not then increment quesions by 1 and return that question
        # Note that initially the button hasn't been pressed yet so the `ntext()` will not be executed
        if(values$count < length(paths$image)){
          values$count <- values$count + 1
          return(paths$image[values$count])
        }
        
        else{
          shinyalert("Congratulations, you're done!", 
                     "Thank you very much for your help, you may exit the program now.",
                     type = "success")
        }
        
      })
      
      
      # Display path
      output$nText <- renderText({
        req(paths$image)
        # The `if` statement below is to test if the button has been clicked or not for the first time,
        # recall that the button works as a counter, everytime it is clicked it gets incremented by 1
        # The initial value is set to 0 so we just going to return the first question if it hasnt been clicked
        
        if(input$goButton == 0){
          return(paths$image[1])
        }
        ntext()

      })
      
      
      # Render the selected image
      output$imageOutput <- renderImage({
        req(paths$image) # Require that a file is selected
        
        if (input$goButton == 0) {
          img <- paths$image[1]
        }
        else {
          img <- ntext()
        }
          
        # Display the image using an img tag
        list(src = img, #paths$image[values$count],
             width = "100%",  # Set width to 100% to fill the container
             height = "100%"  # Maintain aspect ratio
        )
      }, deleteFile = FALSE)

      
      session$onSessionEnded(function() { stopApp() }) #https://groups.google.com/g/shiny-discuss/c/HRi24M-RNU8
    }
    
   
    shinyApp(ui = ui, server = server)
    
  }
  
}
