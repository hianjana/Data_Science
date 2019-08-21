###############################################################################################
# 1) Installing required libraries
# 2) Setting work directory: setwd
#    The exact folder under which the CVs are present is captured as: mydir
#    The path need to be changed on where all the CVs required to create the dictionaries
#    are being placed.
# 3) Reading all the files present in the directory. Only text files are allowed as input.
# 4) Dictionary will be created for Company/University, Skills, Job Titles in a 3 step process
# 5) Company & Skills dictionaries will be created followed by Job Titles because it has a 
#    dependency on the other two.
###############################################################################################

install.packages("tm")
library(tm)

setwd("/Users/saksham/OneDrive - IÉSEG/Documents/Modules/Social media analytics/project_datasets")
mydir = "./concept_extraction_cvs"
listOfFiles = list.files(mydir)

######################################################################################
#
# 1) To create dictionary for Company/ University
# 2) Dictionary will be created with name Dictionary_Companies.txt
# 3) Output directory will be the same directory which is defined above under: setwd
#
######################################################################################

## Define an empty vector to store the company/ university name
Companies <- c()

####################################################################################################
#
# 1) Loop through all the files and extract the company/ university name from the 2nd line
# 2) For each file read, the records will be split for:
#                                                   , (comma)
#                                                   - (hyphen)
#                                                   ( (open bracket)
#                                                   : (collon)
# 3) Only that part of ths tring which falls on the left side of the delimiter would be extracted
# 4) For example if the 2nd line contains "Tata Consulting Services (TCS)", "(TCS)" would be ignored
#    and only "Tata Consulting Services" would be extracted and added to the dictionary.
#
#####################################################################################################

for(eachFile in listOfFiles){
	textfile = paste(mydir,"/",eachFile,sep="")
	file <- readLines(textfile)
	comp <- file[seq(2, 2, 1)]
	resultingCompany = strsplit(comp, split = ",")
	CompanyName = resultingCompany[[1]][1]
  	CompanyName1 = strsplit(CompanyName, split = "-")
  	CompanyFiltered = CompanyName1[[1]][1]
  	CompanyFiltered1 = strsplit(CompanyFiltered, split = "\\(")
  	CompanyFiltered2 = CompanyFiltered1[[1]][1]  
  	CompanyFiltered3 = strsplit(CompanyFiltered2, split = ":")
  	CompanyList = CompanyFiltered3[[1]][1]  
  	CompanyList = trimws(CompanyList)
## To prevent the same company name from getting added repeatedly
  	if (CompanyList != "" && !is.na(CompanyList)) 	{
    		Companies <- append(Companies,CompanyList)
  	}
}

## To create an output text file which is the dictionary with all companies extracted

outputFile = "./Dictionary_Companies.txt"
write.table(Companies, outputFile, row.names=FALSE, col.names=FALSE, quote=FALSE)

####################################################################################################
#
# 1)  To create dictionary for Skills
# 2)  Dictionary will be created with name Dictionary_Skills.txt
# 3)  Output directory will be the same directory which is defined above under: setwd
# 4)  The search pattern used to identify skillset is defined under: prefixSearch
# 5)  Using regular expressions, prefixSearch would be used against each line of each 
#     input file.
# 6)  Only those lines which start exactly with one of the patterns would be considered
#     as a candidate for skill extraction.
# 7)  For example, a sentence like "Experienced in: Java, Python, R" would be considered.
#     But a sentence like "I'm experienced in Java, Python, R" would not be a candidate.
# 8)  Files are read one by one, cleaned and processed immediately.
# 9)  All special characters are removed except semicolon(:), backslash (/), comma(,) and dot(.).
# 10) Once a pattern is matched, the part of sentence which found a matched is replaced
#     with "@@@@@". 
# 11) The sentence/line is then split using the delimiter "@@@@@".
# 12) The right hand portion of the line after the delimiter "@@@@@" is conisdered as 
#     the set of skills. This would be further split to obtain individual skills.
# 13) For example, consider a line is like this:
#     Technology used: R, SQL, Python
#     After 1st iteration it would become: @@@@@ R, SQL, Python
#     After 2nd iteration it would become: R, SQL, Python
#     After 3rd iteration, each skill be extracted and added to the dictionary seperately.
#
#####################################################################################################

## Patterns to search within the documents in order to retreive skills

prefixSearch <- c("^Environment.",
                  "^Environment:.",
                  "^Technology stack:.",
                  "^Technology used:.",
                  "^Technologies applied:.",
                  "^Technical skills :.",
                  "^Technology:.",                  
                  "^Technology :.", 
                  "^Technologies learned and worked on:.",
                  "^Experienced In:.",
                  "^Proficient Knowledge of:.",
                  "^Advanced Knowledge of:.",
                  "^Used Technical skills :.",
                  "^Technologies/Standards used:.",
                  "^Skills:.",
                  "^Skills :.",
                  "^Tools: ."
)

## Defining an empty vector to store all the skills

Skills <- c()

##To loop through all the files

for (eachFile in listOfFiles) {
	textfile = paste(mydir,"/",eachFile,sep="")
  	CV = readLines(textfile) 
##Cleaning of each file to remove unwanted special characters except comma and dot  
  	CVCleaned <- gsub("[^a-zA-Z0-9+:,/\\.]"," ",CV)  
  	resultingText =  strsplit(CVCleaned, "  ")
  	unlisted = unlist(resultingText)
##To retrive the number of sentences which need to be parsed
  	lengthToParse = length(unlisted)
##Processing one line at a time. A line/sentence is processed if it is not empty
  	for (eachLine in unlisted) {
    		if (eachLine != "") {
      			eachLineClean = trimws(eachLine)
##Starting pattern search in all the lines      
      			for (prefix in prefixSearch) {
        			posMatch = grep(prefix, eachLineClean, perl=TRUE, value = TRUE)
        			if (length(posMatch) > 0) {
          				eachLineCleansed = gsub(prefix, "@@@@@", eachLineClean)
          				resultStr = strsplit(eachLineCleansed, split = "@@@@@")
          				resultingString = resultStr[[1]][2]
          				resultingWords = strsplit(as.character(resultingString), ",")
          				unlistedWords = unlist(resultingWords)
          				result = ""
          				for (eachWord in unlistedWords) { 
            					eachWord = trimws(eachWord)
            					match = regexpr("^[A-Z]", eachWord, perl=TRUE, ignore.case = FALSE)
##Check if the skill is already added to the list. If yes, skip else add to the vector         
            					if (!is.na(match) && (attr(match, "match.length") > 0)) {
              						if (length(result) > 0) { 
                						result = stripWhitespace(result)
                						result = gsub("\\s/\\s", "/", result)
                						if (result != "" && result != " ") {
                  							skillUpper = toupper(result)
                  							ExistsOrNot = skillUpper %in% (toupper(Skills))
                  							if (ExistsOrNot == FALSE){
                    								Skills = append(Skills, result)
                  							}
                						}
                							result = ""
              						}
              							result = eachWord
            					} 
          			}
        		}
      			}
    		}
	}
}

## Creates an output text file which is the dictionary with all skills extracted
outputFile = "./Dictionary_Skills.txt"
write.table(Skills, outputFile, row.names=FALSE, col.names=FALSE, quote=FALSE)

######################################################################################
#
# 1) To create dictionary for Job Titles from the 1st line
# 2) Dictionary will be created with name Dictionary_JobTitles.txt
# 3) Output directory will be the same directory which is defined above under: setwd
#
######################################################################################

## Define an empty vector to store all the Job Titles
## Define other empty vectors which are place holders

JobTitles <- c()
positions <- c()
jobsExtracted <- c()

## Loop through all the files and extract the job titles from the 1st line
for(eachFile in listOfFiles){
	textfile = paste(mydir,"/",eachFile,sep="")
  	fileRead <- readLines(textfile)
  	positions = append (positions,fileRead[1])
}

##############################################################
#
# 1) Cleansing and standardizing
# 2) Replacing some of the characters with "@".
# 3) Later, "@" would be used to split the lines/sentences.
# 4) Standardizing the abbreviations
#
##############################################################

positions1 = gsub("r/","r@", positions)
positions2 = gsub(",", "@", positions1)
positions3 = gsub("and", "@", positions2)
positions4 = gsub("[;]", "@", positions3)
positions5 = gsub("[|]", "@", positions4)
positions6 = gsub("Jr", "Junior", positions5)
positions7 = gsub("Sr", "Senior", positions6)

#######################################################################
#
# 1) After cleansing and standardizing is complete, the line will be
#    split at the character "(". 
# 2) The portion which falls on the left hand side of the "(" will be 
#    considered for further processing.
# 3) For exmaple, consider a line:
#				Senior Software Engineer (SQL)
# 4) Only "Senior Software Engineer" will be considered after the split 
#    and "(SQL) will be omitted from further processing.
#
########################################################################

splitPositions = strsplit(positions7, split = "\\(")

for (x in 1:length(splitPositions)){
	jobsExtracted = append(jobsExtracted, splitPositions[[x]][1])
}

#########################################################################
#
# 1) Once the split is complete using "(", further cleansing is done.
# 2) A pattern " / " will be replaced with "@".
# 3) Dot(.) and Ambersand(&) are removed.
# 4) Split is done again on the character "@".
#########################################################################

jobsExtracted1 = gsub("\\s/\\s", "@", jobsExtracted)
jobsExtracted2 = gsub("[.]", "", jobsExtracted1)
jobsExtracted3 = gsub("[&]", "", jobsExtracted2)
jobsExtractedSplit = strsplit(jobsExtracted3, split = "@")

## To find the number of lines to loop through

unlistedJobs = unlist(jobsExtractedSplit)
lengthofUnlisted = length(unlistedJobs)

######################################################################################################
#
# 1) Looping through all the job titles.
# 2) Any job title which contains "-" is eliminated from adding to the dictionary.
# 3) Any job title which has length less than 2 is eliminated from adding to the dictionary.
# 4) If any of the job titles exist under the Skills or Company dictionary already, it is
#    eliminated from adding to the dictionary.
# 5) The above steps are done in order to reduce the noise in the dictionary.
#
######################################################################################################

for (i in 1:lengthofUnlisted) {
  if (i != "") {
	jobtitle = trimws(unlistedJobs[[i]][1])
	hyPhenMatch = grepl("-", jobtitle)
  	if (jobtitle != "" && !is.na(jobtitle) && hyPhenMatch == FALSE) {
    		jobTitleUpper = toupper(jobtitle)
    		ExistsOrNot = jobTitleUpper %in% (toupper(JobTitles))
    		ExistsInSkill = jobTitleUpper %in% (toupper(Skills))
    		ExistsInCompany = jobTitleUpper %in% (toupper(Companies))
    		jobtitleLength = nchar(jobtitle)
    		if (ExistsOrNot == FALSE && 
    		    ExistsInSkill == FALSE && 
    		    ExistsInCompany == FALSE &&
        	    jobtitleLength > 2)
    		{
    	  		JobTitles <- append(JobTitles,jobtitle)
    		}
  	} 
  }
}

## To create an output text file which is the dictionary with all the job titles extracted

outputFile = "./Dictionary_JobTitles.txt"
write.table(JobTitles, outputFile, row.names=FALSE, col.names=FALSE, quote=FALSE)
