import ballerina/io;
import wso2healthcare/health.ccdatojson;
import ballerina/uuid;

public function main() returns error? {

    // Read from file
    string fileContent = check io:fileReadString("resources/CCDA_1_666a16fdd0295b55733596fd.xml");

    // Print results
    io:println("Content read from file: ", fileContent);
    ccdatojson:CCDSummary[] ccdSummaries = check ccdatojson:getCCDSummaries([fileContent]);
    foreach ccdatojson:CCDSummary summary in ccdSummaries {
        io:println("CCDSummary: ", summary);
    }
    string agentResponse = check deduplicateAgent->run(query = ccdSummaries.toJsonString(), sessionId = uuid:createType4AsString());
    io:println("Agent Response: ", agentResponse);
}