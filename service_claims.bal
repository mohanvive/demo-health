import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.uscore501;
import ballerinax/health.fhir.r4utils.ccdatofhir as ccdatofhir;

import wso2healthcare/health.ccdatojson;

final http:Client alfrescoClient = check new (alfrescoApiUrl,
    auth = (tokenurl == "" || consumerkey == "" || consumersecret == "") ? () : {
            tokenUrl: tokenurl,
            clientId: consumerkey,
            clientSecret: consumersecret
        }
);

service / on new http:Listener(9090) {

    // Get patient summary
    resource function get r4/Patient/[string id]/summary() returns json|error {
        if !patientIdsToNodeIds.hasKey(id) {
            return error("Patient ID not found in the mapping");
        }
        string[]? nodeIds = patientIdsToNodeIds.get(id);
        if nodeIds is () {
            return error("Patient ID not found in the mapping");
        }
        string nodeId = (<string[]>nodeIds)[0];
        map<string|string[]> headers = {
            "Accept": "text/plain"
        };
        string fileContent = check alfrescoClient->/download.get(headers = headers, params = {
            "nodeId": nodeId
        });
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
                log:printInfo("CCDA to FHIR conversion successful", convertedBundle = convertedBundle);
                return convertedBundle.toJson();
            }
        }

        return error("CCDA to FHIR conversion failed");
    }

    // Read the patient resource by ID
    resource function get r4/Patient/[string id]() returns json|error {
        string fileContent;
        map<string|string[]> headers = {
            "Accept": "text/plain"
        };
        string[] nodeIds = patientIdsToNodeIds[id] ?: [];
        if nodeIds.length() == 0 {
            return error("Patient ID not found in the mapping");
        }

        fileContent = check alfrescoClient->/download.get(headers = headers, params = {
            "nodeId": nodeIds[0]
        });

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
                log:printInfo("CCDA to FHIR conversion successful");
                r4:BundleEntry[] entries = convertedBundle.entry ?: [];
                foreach r4:BundleEntry entry in entries {
                    log:printInfo("Processing Bundle Entry: ", entry = entry.toJson());
                    if entry?.'resource is uscore501:USCorePatientProfile {
                        log:printInfo("Converted Patient Resource: ", entry = entry?.'resource.toJson());
                        return (<uscore501:USCorePatientProfile>entry?.'resource).toJson();
                    }
                }
            }
        }

        return error("CCDA to FHIR conversion failed");
    }

    resource function get r4/Patient(string? _id) returns json|error {
        string fileContent;
        map<string|string[]> headers = {
            "Accept": "text/plain"
        };
        if _id is string {
            string[] nodeIds = patientIdsToNodeIds[_id] ?: [];
            if nodeIds.length() == 0 {
                return error("Patient ID not found in the mapping");
            }

            fileContent = check alfrescoClient->/download.get(headers = headers, params = {
                "nodeId": nodeIds[0]
            });
        } else {
            log:printInfo("Fetching Patient without specific ID");
            //iterate nodeIds and fetch the first one
            string[] keys = patientIdsToNodeIds.keys().first();
            if keys.length() == 0 {
                return error("No Patient IDs found in the mapping");
            }
            string[] nodeIds = patientIdsToNodeIds[keys[0]] ?: [];
            if nodeIds.length() == 0 {
                return error("No Node IDs found for the first Patient ID");
            }
            fileContent = check alfrescoClient->/download.get(headers = headers, params = {
                "nodeId": nodeIds[0]
            });
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
                return convertedBundle.toJson();
            }
        }

        return error("CCDA to FHIR conversion failed");
    }
}

service / on new http:Listener(8090) {

    resource function get claims/summary(string id) returns string|error {
        if !patientIdsToNodeIds.hasKey(id) {
            return error("Patient ID not found in the mapping");
        }
        string[]? nodeIds = patientIdsToNodeIds.get(id);
        if nodeIds is () {
            return error("Patient ID not found in the mapping");
        }
        string nodeId = (<string[]>nodeIds)[0];
        log:printInfo(string `Fetching claims summary for Patient ID: ${id} with Node ID: ${nodeId}`);
        map<string|string[]> headers = {
            "Accept": "text/plain"
        };
        // Fetch the file content from Alfresco using the nodeId
        log:printInfo(string `Fetching file content for Node ID: ${nodeId}`);
        string fileContent = check alfrescoClient->/download.get(headers = headers, params = {
            "nodeId": nodeId
        });

        log:printInfo(string `Content read from file: ${fileContent}`);
        ccdatojson:CCDSummary[] ccdSummaries = check ccdatojson:getCCDSummaries([fileContent]);
        foreach ccdatojson:CCDSummary summary in ccdSummaries {
            log:printInfo(string `CCDSummary: ${summary.toJsonString()}`);
        }
        string agentResponse = check deduplicateAgent->run(ccdSummaries.toJsonString(), uuid:createType4AsString());
        log:printInfo(string `Agent Response: " ${agentResponse}`);
        return agentResponse;
    }
}
