######################################################################################
# The tool will allow the user to upload a resume and parse it to extract the
# Job Titles, Skills and Companies/Universities present in the resume/CV.
#
# The tools use the 3 dictionaries which are created, prior to the run of the tool.
# The dictionaries required are:
#				Dictionary_Companies.txt
#				Dictionary_Skills.txt
#				Dictionary_JobTitles.txt
#
# The tool can only process resumes which are in text format(.txt). Also it assumes 
# that the company/university the candidate has worked/studied in is on the 2nd line.
#
######################################################################################

## Check if the required packages are present, else install.

pkgTest <- function(x)
{
  if (!require(x,character.only = TRUE))
  {
    install.packages(x)
  }
}

pkgTest("shiny")
pkgTest("RCurl")

library(shiny)
library(RCurl)

## To set the working directory. Change the value depending on where the dictionaries are placed.

setwd("/Users/saksham/OneDrive - IÉSEG/Documents/Modules/Social media analytics/project_datasets")

## To call all the dictionaries

CompanyDictio =  readLines("./Dictionary_Companies.txt")
SkillDictio =  readLines("./Dictionary_Skills.txt")
JobTitlesDictio = readLines("./Dictionary_JobTitles.txt")

#####################################################################################
#
#            The UI Component
#
#####################################################################################

ui <- fluidPage(
## To create the title
tags$head(
	tags$style(HTML("
			@import url('//fonts.googleapis.com/css?family=Lobster|Cabin:400,700');
			h1 {
				font-family: 'Lobster', cursive;
				font-weight: 500;
				line-height: 1.1;
				color: #48ca3b;
			   }

	    		"))
	),  
fluidRow(
	column(6, offset = 3, align="center",headerPanel("Resume Parser Tool"))
  	),
tags$p(),
tags$p(),
tags$p(),
wellPanel(
	style = "padding: 50px;",   
## File browser for the user to select the resume    
	fluidRow(
  	tags$p(),
 	column(5, offset = 4, fileInput("inFile",label = "Choose a resume"))
  	),
  	column(1, offset = 6, actionButton("parseButton", label = "Parse", class = "btn-primary"))
 ),
## To display the results  
titlePanel(tags$h4(tags$strong("Results"))),
fluidRow(
	column(3, tags$h5(tags$strong("Job Titles"))),
	column(3, offset = 1, tags$h5(tags$strong("Company/ University"))),
	column(3, offset = 1, tags$h5(tags$strong("Skills")))
        ),
fluidRow(
	column(3,tableOutput("jobtitles")),
	column(3, offset = 1, tableOutput("companies")),
	column(3, offset = 1, tableOutput("skills"))
        )
)

#####################################################################################
#
#            The server Component
#
#####################################################################################
#
# 1) The parsing will be done once the "Parse" button is clicked.
# 2) The input file is expected to be in the same path which is 
#    defined under "setwd" at the begining of the code.
# 3) The input file is parsed against the 3 dictionaries for
#    Job Titles, Company and Skills.
#
#####################################################################################

#####################################################################################
#
#                           Company extraction
#
# Input resume is expected to have company or university in the 2nd line.
# Each company present in Dictionary_Companies.txt is checked against the
# selected resume. If a match is found, it is displayed under "Company/ University".
#
######################################################################################

server <- function(input, output){
	observeEvent(input$parseButton, {
		if(is.null(input$inFile$name)) {
			return("   ")
		}
		else
			{ 
				inputFile = input$inFile$name
				FileNameToCompare = paste("./",inputFile,sep="")
				inputToCompare = readLines(FileNameToCompare)
				comp <- inputToCompare[seq(2, 2, 1)]
				comp1 = strsplit(comp, split = ",")
				comp2 = comp1[[1]][1]
				comp3 = strsplit(comp2, split = "-")
				comp4 = comp3[[1]][1]
				comp5 = strsplit(comp4, split = "\\(")
				comp6 = comp5[[1]][1]  
				comp7 = strsplit(comp6, split = ":")
				CompanyNameToCompare = comp7[[1]][1]    
				CompanyNameToCompare = trimws(CompanyNameToCompare)
				ToCompare = toupper(CompanyNameToCompare)
				
				listOfCompanies <- c()
				for (i in 1:length(CompanyDictio)) {
				ToCompareUpper = toupper(CompanyDictio[i])
				x = which(ToCompare == ToCompareUpper)
				if (length(x) > 0 && CompanyDictio[i] != "") {
					ExistsOrNot = ToCompareUpper %in% (toupper(listOfCompanies))
					if (ExistsOrNot == FALSE){
						listOfCompanies = append(listOfCompanies,CompanyDictio[i])
					}
				}
			} 
#####################################################################################
#
#                           Skill extraction
#
# Each skill present in Dictionary_Skills.txt is checked against the
# selected resume. If a match is found, it is displayed under "Skills".
#
#####################################################################################

				listOfSkills <- c()  
				ToCompare = toupper(inputToCompare)
				ToCompare = gsub("\\+", "Plus", ToCompare)
				for (skill in SkillDictio) {
							   skillUpper = toupper(trimws(skill))
							   skillUpper = gsub("\\+", "Plus", skillUpper)
							   skillToSearch = paste("\\b",skillUpper, "\\b",sep="")
							   skillMatch  = grep(skillToSearch,ToCompare, value = TRUE) 

							   if (!is.na(skillMatch) && length(skillMatch) > 0  && skill != ""){
								ExistsOrNot = skillUpper %in% (toupper(listOfSkills))
								if (ExistsOrNot == FALSE){
									listOfSkills = append(listOfSkills,skill)
								}
							   }
				}
  
#####################################################################################
#
#                           Job Titles extraction
#
# Each job title present in Dictionary_JobTitles.txt is checked against the
# selected resume. If a match is found, it is displayed under "Job Titles".
#
#####################################################################################
  
				listOfJobTitles <- c()  
				ToCompare = toupper(inputToCompare)
				ToCompare = gsub("\\+", "Plus", ToCompare)
				for (jobTitle in JobTitlesDictio) {
								jobTitleUpper = toupper(trimws(jobTitle))
								jobTitleUpper = gsub("\\+", "Plus", jobTitleUpper)
								jobToSearch = paste("\\b",jobTitleUpper, "\\b",sep="")
								jobMatch  = grep(jobTitleUpper,ToCompare, value = TRUE) 

								if (!is.na(jobMatch) && length(jobMatch) > 0  && skill != ""){
									ExistsOrNot = jobTitleUpper %in% (toupper(listOfJobTitles))
									if (ExistsOrNot == FALSE){
										listOfJobTitles = append(listOfJobTitles,jobTitle)
									}
								}
				}
## To write the matching Job Ttles, Companies and Skills found, back to the UI.
				output$companies <- renderTable({ 
								paste(listOfCompanies)
								},colnames = FALSE)
				output$skills <- renderTable({ 
								paste(listOfSkills)
							      },colnames = FALSE)
				output$jobtitles <- renderTable({ 
								paste(listOfJobTitles)
								}, colnames = FALSE)
			}
	})  
}

#########################################################################
#
#            Calling the ui and server components
#
#########################################################################

shinyApp(ui = ui, server = server)
