###############################################################################
# FILE: compTriples-Shiny.R
# DESC: Create a table of triples that differ from an Object node to compare 
#         one TTL file with aonther.
#       Eg Usage: Compare TTL file generated from TopBraid with one created using R
# SRC : Based on VisClasses-Shiny.R and CompareTTL.R
# IN  : Browse to two .TTL files for comparison
# OUT : ShinyApp window
# REQ : rrdf
# NOTE: Includes display of the triples available from Ont,R, not just the ones
#         that do not match.
# TODO: Move prefixes specification to an external file.
#    ERROR: Display of triplesOnt, triplesR is NOT reactive     
#    Create new version used to query Stardog for both Ont and Der graphs.
###############################################################################
library(plyr)    #  rename
library(dplyr)   # anti_join. MUst load dplyr AFTER plyr!!
library(reshape) #  melt
library(rrdf)
library(shiny)
setwd("C:/_gitHub/CTDasRDF/data/rdf")
ui <- fluidPage(
  titlePanel("Compare TTLs from R and Ontology "),
  fluidRow (
      column(4, fileInput('fileOnt', 'TTL from Ont <filename>.TTL')),
      column(4, fileInput('fileR',   'TTL from R   <filename>-R.TTL')
      ),
      column(3, textInput('qnam', "Subject QName", value = "cdiscpilot01:Person_1"))
  ),
  radioButtons("comp", "Compare:",
                c("In R, not in Ontology" = "inRNotOnt",
                  "In Ontology, not in R" = "inOntNotR")),    
  h4("Comparison Result:",
    style= "color:#e60000"),
  hr(),    
  tableOutput('contents'), 
  h4("Ontology Triples",
    style= "color:#000099"),
  tableOutput('triplesOnt'),
  h4("R Triples",
    style= "color:#00802b"),
  tableOutput('triplesR')
    
)

server <- function(input, output) {
    output$contents <- renderTable({ 
        inFileR <<- input$fileR
        inFileOnt <<- input$fileOnt
        # Do not do anything until both FileR and FileOnt have been specified.
        if(is.null(inFileR) | is.null(inFileOnt) )
            return(NULL)
    
        #TODO Confirm these two steps
        file.rename(inFileR$datapath,
            paste(inFileR$datapath, ".ttl", sep=""))
        file.rename(inFileOnt$datapath,
            paste(inFileOnt$datapath, ".ttl", sep=""))

        query = paste0("PREFIX cd01p: <https://github.com/phuse-org/CTDasRDF/tree/master/data/rdf/cd01p#>
PREFIX cdiscpilot01: <https://github.com/phuse-org/CTDasRDF/tree/master/data/rdf/cdiscpilot01#>
PREFIX code:  <https://github.com/phuse-org/CTDasRDF/tree/master/data/rdf/code#>
PREFIX country: <http://psi.oasis-open.org/iso/3166/#>
PREFIX custom: <https://github.com/phuse-org/CTDasRDF/tree/master/data/rdf/custom#>
PREFIX meddra: <https://w3id.org/phuse/meddra#>
prefix owl:   <http://www.w3.org/2002/07/owl#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#> 
PREFIX sdtm: <https://github.com/phuse-org/SDTMasRDF/blob/master/data/rdf/sdtm#>
PREFIX sdtm-terminology: <https://github.com/phuse-org/CTDasRDF/tree/master/data/rdf/sdtm-terminology#> 
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX sp: <http://spinrdf.org/sp#> 
PREFIX spin: <http://spinrdf.org/spin#> 
PREFIX study:  <https://github.com/phuse-org/CTDasRDF/tree/master/data/rdf/study#>
PREFIX time:  <http://www.w3.org/2006/time#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#> 
SELECT ?s ?p ?o
WHERE {", input$qnam, " ?p ?o . 
  BIND(\"", input$qnam, "\" as ?s) } ")

       sourceR = load.rdf(paste(inFileR$datapath,".ttl",sep=""), format="N3")
       # Global assign for trouble shooting
       triplesR <<- as.data.frame(sparql.rdf(sourceR, query))
       
       sourceOnt = load.rdf(paste(inFileOnt$datapath,".ttl",sep=""), format="N3")
       triplesOnt <- as.data.frame(sparql.rdf(sourceOnt, query))
    
       # Remove cases where O is missing in the Ontology source(atrifact from TopBraid)
       triplesOnt <-triplesOnt[!(triplesOnt$o==""),]
       triplesOnt <<- triplesOnt[complete.cases(triplesOnt), ]
       if (input$comp=='inRNotOnt') {
           compResult <<-anti_join(triplesR, triplesOnt)
       }
       else if (input$comp=='inOntNotR') {
           compResult <- anti_join(triplesOnt, triplesR)
       }
  
       triplesOnt <- triplesOnt[with(triplesOnt, order(s,p,o)), ]
       triplesR   <- triplesR[with(triplesR, order(s,p,o)), ]
       
       output$triplesOnt <-renderTable({triplesOnt})    
       output$triplesR <-renderTable({triplesR})    

       compResult
    })
    # sort for visual compare in the interface
    output$triplesOnt <-renderTable({triplesOnt})    
    output$triplesR <-renderTable({triplesR})    
}


shinyApp(ui = ui, server = server)

