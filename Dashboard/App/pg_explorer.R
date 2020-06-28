BigNum <- function(x) format(as.numeric(as.character(x)), big.mark = "_", scientific = FALSE)

pg_explorerInput <- function(id) {
    ns <- NS(id)
    tagList(
        fluidRow(
            ## Input
            column(3,uiOutput(ns('schemas')))
            
          , column(3, uiOutput(ns('tables')))
          , column(3, numericInput(inputId=ns("maxRows"), label="Max Rows", value=100, min=0, max=NA, step=NA, width=NULL))
        )
       ,
        fluidRow(
            column(3,uiOutput(ns('filterColumn')))
          , column(3,uiOutput(ns("filterString")))
          ## , bsTooltip(ns("filterString"), 'Filter is using <a href="https://www.postgresql.org/docs/10/functions-matching.html">regular expressions</a>', trigger = "focus")
          , column(3,uiOutput(ns("caseSensitivity")))
        ), 
        hr(),
        ## fluidRow(
        ##   h5(sprintf("SQL to get dataset:")
        ##   , textOutput(ns("sql")))
        ## ),
        
        ## Output
        fluidRow(        
            h2(textOutput(ns("tableName")))
          , tabsetPanel(
                tabPanel("Data",
                         shiny::dataTableOutput(ns('result'))),
                tabPanel("Columns",
                         shiny::dataTableOutput(ns('columns')))
            )
        )
    )
}

## Server
pg_explorer <- function(input, output, session, con = .pg) {
    ns <- session$ns
    ## Schemas
    output$schemas <- renderUI({
        selectInput(ns("schemaSelection"),"Schema",sort(pg.schemas(con)$schema_name), selected = "public")
    }) 
    ## Tables in Schema
    output$tables <- renderUI({
        selectInput(ns("tableSelection"),"Table",pg.tables(schema=input$schemaSelection, con = con)$table_name)
    }) 
    ## Filter column
    output$filterColumn <- renderUI({
        req(input$tableSelection)
        flog.trace("Making filter column Input element")
        selectInput(ns("filterColumn"), "Filter Column", c("-- Select Column --",pg.columns(table=input$tableSelection, schema=input$schemaSelection, con=con)$column_name))
  })

  ## Filter string
    output$filterString <- renderUI({
        req(input$filterColumn != "-- Select Column --")
        flog.trace("Making filter string element")
        textInput(ns("filterStringSelection"),"Filter String")
  })

  ## Case sensitive filter?
    output$caseSensitivity <- renderUI({
        req(input$filterStringSelection)  
        checkboxInput(ns("caseSensitivitySelection"), "Case sensitive filter", value = FALSE)
    })
    
    ## Table Rows (for header)
    Rows_table <- reactive({
        req(input$tableSelection)
        req(input$tableSelection %in% pg.tables(schema=input$schemaSelection)$table_name)
        flog.trace("Counting rows. Approx estimate: %s",  pg.rows(schema=input$schemaSelection, table = input$tableSelection, exact = FALSE))
        q_rows <- pg.rows(schema=input$schemaSelection, table = input$tableSelection, exact = TRUE, con=con)
        flog.trace("Found %s rows in %s.%s", q_rows, input$schemaSelection, input$tableSelection)
        q_rows
    })
    ## Table name as header
    output$tableName <- renderText({
        req(input$tableSelection)
        req(input$tableSelection %in% pg.tables(schema=input$schemaSelection)$table_name)
        flog.trace("Making table name header")
        selected_rows <- nrow(Table())
        q_rows <- Rows_table()
        sprintf("%s.%s (%s / %s rows)",input$schemaSelection, input$tableSelection, BigNum(selected_rows), BigNum(q_rows))
    })
    
    ## SQL
    Sql <- reactive({
        req(input$tableSelection)
        req(input$tableSelection %in% pg.tables(schema=input$schemaSelection)$table_name)
        flog.trace("Making SQL query string")
        if (is.null(input$filterStringSelection) || input$filterStringSelection == "" || input$filterColumn == "-- Select Column --") {
            stmt <- sprintf("select * from \"%s\".\"%s\" order by id desc limit %s", input$schemaSelection,input$tableSelection,input$maxRows) 
            flog.trace("Sql returns: %s", stmt)
            return(stmt)
        }
        flog.trace("  sql string with filterning")
        cmp_string = "~*"
        if(input$caseSensitivitySelection)
            cmp_string = "~"
        sprintf("SELECT * FROM %s.%s WHERE \"%s\"::text %s '%s' ORDER BY \"%s\" LIMIT %s", input$schemaSelection, input$tableSelection, input$filterColumn, cmp_string, gsub("[']","",input$filterStringSelection), input$filterColumn, input$maxRows)
    })
    output$sql <- renderText({
        req(input$tableSelection)
        flog.trace("render sql")
        Sql()
    })
    
    ## Table
    Table <- reactive({
        req(input$schemaSelection)
        req(input$tableSelection)
        req(input$maxRows)
        flog.trace("generate table")
        pg.get(q=Sql())
    })
    output$result <- shiny::renderDataTable({
        req(input$schemaSelection)
        req(input$tableSelection)
        req(input$maxRows)
        flog.trace("Assign table to output")
        Table()
    },options = list(pageLength = 10))
  
    ## Columns
    output$columns <- shiny::renderDataTable({ ## DT always shows GMT
        req(input$tableSelection)
        flog.trace("generate columns list")
        pg.columns(table=input$tableSelection, schema=input$schemaSelection)
    },options = list(pageLength = 10))
    
    return()
}

