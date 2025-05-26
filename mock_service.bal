import ballerina/http;
import ballerina/io;

service /download on new http:Listener(8080) {
    resource function get ccda(string? id) returns string|error {
        // For demonstration purposes, return the same file content regardless of the ID
        string fileContent = check io:fileReadString("resources/CCDA_1_666a16fdd0295b55733596fd.xml");
        return fileContent;
    }
}