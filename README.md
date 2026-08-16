## iris-bi-validator
This application generates an HTML report that validates whether each BI artifact in the namespace is functioning and identifies any errors encountered.

## Prerequisites
Are required a BI project deployed into any namespace

## Installation 

From your IRIS BI app, go to your IRIS terminal and execute:

```
$ zpm "install iris-bi-validator"
```

Or include as a dependency into your project module.xml file. See a sample:

```
<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25">
  <Document name="yourproject.ZPM">
    <Module>
      <Name>yourproject</Name>
      <Version>1.0.0</Version>
      <Dependencies>
        <ModuleReference>
          <Name>iris-bi-validator</Name>
          <Version>*</Version>
        </ModuleReference>
      </Dependencies>
      <Packaging>module</Packaging>
      <SourcesRoot>src</SourcesRoot>
    </Module>
  </Document>
</Export>
```

## How to Run it

1. Open IRIS terminal:

```
Do ##class(dc.irisbivalidator.IrisBIValidator).ValidateAndGenerateReport("/home/irisowner/dev/validation_report.html")
```
According to the mapping in docker-compose.yml

** The path of the report can be any valid path in your environment (i used the path mapped in docker-compose.yml **

2. Open the generated report and see the results:
<img src="https://github.com/yurimarx/iris-bi-validator/blob/master/images/report.png?raw=true">
