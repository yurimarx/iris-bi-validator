/// Validates all Pivot Tables and Dashboards in the current namespace and generates an HTML report.
Class dc.irisbivalidator.IrisBIValidator
{

/// Validates all Pivot Tables and Dashboards in the current namespace and generates an HTML report.
/// 
/// Parameters:
/// pFilename - The full path to the file where the HTML report will be saved.
ClassMethod ValidateAndGenerateReport(pFilename As %String) As %Status
{
    Set tResults = []
    
    Do ..validateCubes(.tResults)

    Do ..validatePivots(.tResults)
    
    Do ..validateDashboards(.tResults)
    
    Return ..generateHTMLReport(pFilename, .tResults)
}

/// Validation logic for Cubes
ClassMethod validateCubes(ByRef pResults As %DynamicArray) As %Status
{
    Kill tList
    Set tStatus = ##class(%DeepSee.Utils).%GetCubeList(.tList)
    Return:$$$ISERR(tStatus) tStatus
    
    Set tItemName = ""
    For {
        Set tItemName = $ORDER(tList(tItemName))
        Quit:tItemName=""

        Set tItemStatus = ##class(%DeepSee.Utils).%BuildCube(tItemName)
        
        Set tResult = {}
        Do tResult.%Set("type", "Cube")
        Do tResult.%Set("name", tItemName)
        Do tResult.%Set("status", tItemStatus)
        Do pResults.%Push(tResult)
    }

    Return $$$OK
}

/// Validation logic for Pivot Tables
ClassMethod validatePivots(ByRef pResults As %DynamicArray) As %Status
{
    Kill tList
    Set tStatus = ##class(%DeepSee.Utils).%GetPivotList(.tList)
    Return:$$$ISERR(tStatus) tStatus
    
    Set tItemName = ""
    For {
        Set tItemName = $ORDER(tList(tItemName))
        Quit:tItemName=""

        Set tLogicalPivotName = $LIST(tList(tItemName), 1) ; Extracts the logical name of the Pivot Table
        Set tItemStatus = $$$OK
        Set tMDX = ""
        
        Set tMDX = ##class(%DeepSee.Utils).%GetMDXFromPivot(tLogicalPivotName, .tItemStatus)
        
        If $$$ISOK(tItemStatus) && ($Get(tMDX) '= "") {
            Set tMDXRS = ##class(%DeepSee.ResultSet).%New()
            Set tItemStatus = tMDXRS.%PrepareMDX(tMDX)
            
            If $$$ISOK(tItemStatus) {
                // %Execute() returns the result object itself on success, or a %Status on error.
                Set tExecuteResult = tMDXRS.%Execute()
                // If the result is NOT an object, it means an error occurred and tExecuteResult contains the error status.
                If '$IsObject(tExecuteResult) {
                    Set tItemStatus = tExecuteResult
                } else {
                    Set tItemStatus = $$$OK 
                }
            }
        } ElseIf $$$ISOK(tItemStatus) && ($Get(tMDX) = "") {
            Set tItemStatus = $$$ERROR($$$GeneralError, "A Pivot está vazia ou não possui uma query MDX válida.")
        }
        
        Set tResult = {}
        Do tResult.%Set("type", "Pivot Table")
        Do tResult.%Set("name", tItemName)
        Do tResult.%Set("status", tItemStatus)
        Do pResults.%Push(tResult)
    }
    Return $$$OK
}

/// Validation logic for Dashboards
ClassMethod validateDashboards(ByRef pResults As %DynamicArray) As %Status
{
    Set tSQL = "SELECT fullName FROM %DeepSee_UserLibrary.FolderItem WHERE fullName LIKE '%.dashboard'"
    Set tStmt = ##class(%SQL.Statement).%New()
    Set tStatus = tStmt.%Prepare(tSQL)
    Return:$$$ISERR(tStatus) tStatus
    
    Set tRS = tStmt.%Execute()
    
    While tRS.%Next() {
        Set tItemName = tRS.%Get("fullName")
        Set tItemStatus = $$$OK
        
        // Tries to open the structural document of the Dashboard
        Set tDoc = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tItemName, .tItemStatus)
        
        If '$IsObject(tDoc) && $$$ISOK(tItemStatus) { // If it's not an object and the status is OK, it means an unknown failure occurred.
            Set tItemStatus = $$$ERROR($$$GeneralError, "Unknown failure instantiating the Dashboard XML/Document object.")
        }
        
        Set tResult = {}
        Do tResult.%Set("type", "Dashboard")
        Do tResult.%Set("name", tItemName)
        Do tResult.%Set("status", tItemStatus)
        Do pResults.%Push(tResult)
    }
    Return $$$OK
}

/// Generates the HTML report file
ClassMethod generateHTMLReport(pFilename As %String, ByRef pResults As %DynamicArray) As %Status
{
    Set tStream = ##class(%Stream.FileCharacter).%New()
    Set tStatus = tStream.LinkToFile(pFilename)
    Return:$$$ISERR(tStatus) tStatus

    Do tStream.Write("<html><head><title>IRIS BI Validation Report</title>")
    Do tStream.Write("<style>body{font-family:sans-serif;} table{border-collapse:collapse;width:100%;} th,td{border:1px solid #ddd;padding:8px;text-align:left;} th{background-color:#f2f2f2;} .success{color:green;} .error{color:red;} .warning{color:orange;}</style>")
    Do tStream.Write("</head><body>")
    Do tStream.Write("<h1>IRIS BI Validation Report</h1>")
    Do tStream.Write("<h2>Namespace: " _ $NAMESPACE _ "</h2>")
    Do tStream.Write("<table><tr><th>Type</th><th>Item</th><th>Status</th><th>Details</th></tr>")

    For i = 0 : 1 : pResults.%Size() - 1 {
        Set tResult = pResults.%Get(i)
        Set tStatus = tResult.status
        Do tStream.Write("<tr>")
        Do tStream.Write("<td>" _ tResult.type _ "</td>")
        Do tStream.Write("<td>" _ tResult.name _ "</td>")
        If $$$ISOK(tStatus) {
            Do tStream.Write("<td><strong class='success'>Success</strong></td><td>&nbsp;</td>")
        } Else {
            Set tErrorText = $System.Status.GetErrorText(tStatus)
            Do tStream.Write("<td><strong class='error'>Error</strong></td>")
            Do tStream.Write("<td>" _ tErrorText _ "</td>")
        }
        Do tStream.Write("</tr>")
    }

    Do tStream.Write("</table></body></html>")
    
    Return tStream.%Save()
}

}