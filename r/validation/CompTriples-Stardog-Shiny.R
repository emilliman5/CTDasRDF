###############################################################################
# FILE: compTriples-Stardog-Shiny.R
# DESC: Compare instance data triples created by the Ontology Subteam with 
#       those created by the data derivation team using XPT conversion and SMS
#       mapping. 
#       Specify a SUBJECT value and compare the predicates and objects at that
#       level only (no traversal)
# SRC : 
# IN  : prefixList.csv, Stardog Graphs
# OUT : ShinyApp window
# REQ : data uploaded to graphs Stardog: CTDasRDFSMS,  CTDasRDFOnt
#       Prefixs file, IRI parsing function in Functions.R
# NOTE: Includes display of the triples available from both graphs, and those 
#       that are in one, but not in the other.
#   Full IRIs returned even if you specified PREFIX statements the query, so why 
#     note remove them from the query? They are needed to allow specification 
#     of different Subject nodes using their qnam and not full IRI  when 
#     validating different parts of the graph.
# TODO: 
###############################################################################
library(plyr)    # rename
library(dplyr)   # anti_join. MUst load dplyr AFTER plyr!!
library(DT)      # oh so pretty data table.
library(reshape) # melt
library(SPARQL)
library(shiny)

setwd("C:/_gitHub/CTDasRDF/r")
source("validation/Functions.R")

# Ontology and SMS graphs running on local server
epOnt = "http://localhost:5820/CTDasRDFOnt/query"
epSMS = "http://localhost:5820/CTDasRDFSMS/query"

# Read in the prefixes
prefixList <- read.csv(file="prefixList.csv", header=TRUE, sep=",")

# Create a combined prefix IRI column.
prefixList$prefix_ <- paste0("PREFIX ",prefixList$prefix, " ", prefixList$iri)

# Collapse into a single string
prefixBlock <- paste(prefixList$prefix_, collapse = "\n")

queryStart <- "SELECT ?p ?o "

ui <- fluidPage(
  titlePanel("Instance Data: Ontology vs SMS Map"),
  fluidRow (
    column(12, textInput('rootNode', "SUBJECT node", width='400px', value = "cd01p:Study_CDISCPILOT01"))
  ),
  fluidRow(
    column(HTML("Ontology P,O (all)"),
      div(
        dataTableOutput('triplesTableOnt'), style = "font-size:80%"
      ),  
      width = 5)
    ,
    column(HTML("SMS P,O (all)"),
      div(
        dataTableOutput('triplesTableSMS'), style = "font-size:80%"
      ),  
      width = 5)
  ),
  # Section for identifying triples in one graph and not the other.   
  fluidRow(
    column(h4("Comparison Result:",
    style= "color:#e60000"), width = 5)
  ),
  fluidRow(
    column(h3("In Ont, not in SMS"),
      dataTableOutput('OntNotSMS'), width = 6),
    column(h3("In SMS, not in Ont"),
      dataTableOutput('SMSNotOnt'), width = 6)
    
  )  
)

server <- function(input, output) {

  # Ontology Triples ----------------------------------------------------------   
      # QC of the query as a text render when debugging.
        #output$queryCheckOnt <- renderText({
        #  paste0(prefixBlock, queryStart, "
        # WHERE {", input$rootNodeOnt," ?p ?o . } ORDER BY ?p ?o "
        # )      
        # })
    
  triplesOnt <- reactive({ 
    queryOnt = paste0(prefixBlock, queryStart, "
      WHERE {", input$rootNode," ?p ?o . } ORDER BY ?p ?o "
    )

    # Query results dfs ----  
    qrOnt <- SPARQL(url=epOnt, query=queryOnt)
    #--------------------
    triplesOnt <- qrOnt$results
    # shorten from IRI to qnam
    triplesOnt <- IRItoPrefix(sourceDF=triplesOnt, colsToParse=c("p", "o"))
    # Sort the dataframe values for display
    triplesOnt<-triplesOnt[with(triplesOnt, order(p, o)), ]
  })
  
  output$triplesTableOnt <- DT::renderDataTable({triplesOnt()}, 
    options = list( pageLength = 10,
                    paging     = TRUE, 
                    scrollX    = TRUE, 
                    searching  = FALSE))    
  
  # SMS Triples -----------------------------------------------------------
  triplesSMS <- reactive({ 
    # print(input$rootNode)
    querySMS = paste0(prefixBlock, queryStart, "
      WHERE {", input$rootNode," ?p ?o . } ORDER BY ?p ?o "
    )

    # Query results dfs ----  
    qrSMS <- SPARQL(url=epSMS, query=querySMS)
    #--------------------
    triplesSMS <- qrSMS$results
    # shorten from IRI to qnam
    triplesSMS <- IRItoPrefix(sourceDF=triplesSMS, colsToParse=c("p", "o"))
    # Sort the dataframe values for display
    triplesSMS<-triplesSMS[with(triplesSMS, order(p, o)), ]
  })
  
  output$triplesTableSMS <- DT::renderDataTable({triplesSMS()}, 
    options = list(pageLength = 10,
                   paging     = TRUE, 
                   scrollX    = TRUE, 
                   searching  = FALSE))    

 # Comparsion to find in one graph and not in the other
  compResultSMS <- reactive({
      compResult <-anti_join(triplesSMS(), triplesOnt())
      
  })
  
  compResultOnt <- reactive({    
    compResult <- anti_join(triplesOnt(), triplesSMS())
  })
  
  output$OntNotSMS <- DT::renderDataTable({compResultOnt()},
    options = list(paging=FALSE, scrollX = TRUE, searching=FALSE))
  
  output$SMSNotOnt <- DT::renderDataTable({compResultSMS()},
    options = list(paging=FALSE, scrollX = TRUE, searching=FALSE))
  
} # End of server portion

shinyApp(ui = ui, server = server)