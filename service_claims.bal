import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.uscore501;
import ballerinax/health.fhir.r4utils.ccdatofhir as ccdatofhir;
import wso2healthcare/health.ccdatojson;
import ballerina/uuid;

final http:Client alfrescoClient = check new (url = alfrescoApiUrl);

service / on new http:Listener(9090) {
    resource function get r4/Patient/[string id]/\$summary() returns r4:Bundle|error {
        map<string|string[]> queryParams = {
            "id": id
        };
        string fileContent = check alfrescoClient->/ccda.get(queryParams);
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

    resource function get r4/Patient(string? _id) returns uscore501:USCorePatientProfile|error {
        string fileContent;
        if _id is string {
            map<string|string[]> queryParams = {
                "id": _id
            };
            fileContent = check alfrescoClient->/ccda.get(queryParams);
        } else {
            log:printInfo("Fetching Patient without specific ID");
            fileContent = check alfrescoClient->/ccda.get();
        }

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
                r4:BundleEntry[] entries = convertedBundle.entry ?: [];
                anydata patient = entries.forEach(function (r4:BundleEntry entry) {
                    if entry?.'resource is uscore501:USCorePatientProfile {
                        io:println("Converted Patient Resource: ", entry?.'resource);
                        return <()>entry?.'resource;
                    }
                });
                if patient is uscore501:USCorePatientProfile {
                    return patient;
                } else {
                    return error("Patient resource not found in the converted bundle");
                }
            }
        }

        return error("CCDA to FHIR conversion failed");
    }

    resource function get claims/summary() returns string|error {
        string fileContent = check alfrescoClient->/ccda.get();

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