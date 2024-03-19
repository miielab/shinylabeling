# Manual-Labeling

## Overview
This repository aims to faciliate the manual labeling of image data. In particular, it contains R code to run a Shiny application which sequentially displays images and asks/collects user responses about them. Note: this repo is not monitored.

## Requirements
- [RStudio](https://posit.co/download/rstudio-desktop/)
    - Required packages: "rstudioapi", "shiny", "shinydashboard", "shinyjs", "shinyalert", "shinyWidgets", "DT", "dplyr"

## Directory Set Up 
- Create "assignments.csv" file where each row corresponds to an image and at least one column contains the image path
- Create "directories.csv" where each row corresponds to an individual labeler. This should contain two columns: 1) a unique labeler ID and 2) their local path to the directory containing the images.
- Download the app.R script and place in the same directory as the above two files

## Customizing the Shiny App
- To change the user interface, you can add or remove questions in the "ui" portion of the code. The first value in a ui function, e.g., "selectInput()" or "checkboxGroupInput()", is the "id" of that input. If inputs are changed, the corresponding part of the server that processes that input will also need changing.
    - For example, suppose you added a new ui input with the id "clothing." The server code that writes responses to the csv, i.e., the first chunk of the code in the eventReactive "ntext <- eventReactive(input$goButton,{...", will need to be changed so that the new ui input is written to a cell in addition to the existing responses, e.g., clothing = input$cothing. 

## How to Use
1. Open \[Your Midway Path\]/miie/supplemental_data/manual_coding/faces/Spring 2024/app.R 
    - This can be done by opening a file browser and navigating to the directory or opening the file directly through RStudio 
2. Run app.R in RStudio by highlighting the code and running the selected lines or clicking on "Run App" in the upper right corner of the script quadrant.
3. Once prompted, choose cnetID and wait until first image loads
4. Provide responses in the left panel and hit "Next Image" when complete. Once a new image loads, you can be sure the response was recorded.
5. **You may close the application at any time and your progress will be saved.** To close, simply exit the R pop-up window or browser tab

## Notes
- The application opens initially in a R pop-up window, but you may open the program in a browser using the "Open in Browser" option at the top of the window
- Your file will be saved as "labels_[cnetID].csv" in the same directory as the R script 
- **In case of mislabel**: You can open up the "labels_[cnetID].csv" file in Excel and delete any rows where something was mislabeled
- Sometimes the images load slowly, I am unsure why this is at the moment and have only noticed this behavior on Windows OS.

## Errors 
- If it's your **first time running the app**, you may encounter some installation errors. If this is the case, try running the code again once or twice prior to troubleshooting and see if the errors disappear.
- If you encounter an error while setting the working directory, e.g., "Error in setwd(... cannot change working directory," try running the code again or restarting RStudio.
- If trouble loading images, ensure your cnetid and midway path appear correctly here: \[Your Midway Path\]/miie/supplemental_data/manual_coding/faces/Spring 2024/directories.csv 

