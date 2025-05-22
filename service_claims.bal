import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4utils.ccdatofhir as ccdatofhir;
import wso2healthcare/health.ccdatojson;
import ballerina/uuid;

service / on new http:Listener(9090) {
    resource function get claims() returns r4:Bundle|error {
        string fileContent = check io:fileReadString("resources/CCDA_1_666a16fdd0295b55733596fd.xml");
        if fileContent.startsWith("<?xml version=\"1.0\" encoding=\"UTF-8\"?>") {
            int? indexOf = fileContent.indexOf("?>");
            if indexOf is int {
                fileContent = fileContent.substring(indexOf + 2);
            } else {
                log:printError("Error: XML declaration not found.");
            }
        }
        xml|error fromString = xml:fromString(fileContent);
        if fromString is xml {
            r4:Bundle|r4:FHIRError convertedBundle = ccdatofhir:ccdaToFhir(fromString);
            if convertedBundle is r4:Bundle {
                io:println("CCDA to FHIR conversion successful");
                io:println(convertedBundle);
                return convertedBundle;
            }
        }

        return error("CCDA to FHIR conversion failed");
    }

    resource function get claims/summary() returns string|error {
        string fileContent = check io:fileReadString("resources/CCDA_1_666a16fdd0295b55733596fd.xml");

        // Print results
        io:println("Content read from file: ", fileContent);
        ccdatojson:CCDSummary[] ccdSummaries = check ccdatojson:getCCDSummaries([fileContent]);
        foreach ccdatojson:CCDSummary summary in ccdSummaries {
            io:println("CCDSummary: ", summary);
        }
        string agentResponse = check deduplicateAgent->run(query = ccdSummaries.toJsonString(), sessionId = uuid:createType4AsString());
        io:println("Agent Response: ", agentResponse);
        return agentResponse;
    }
}
