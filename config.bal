import ballerina/os;

configurable string openAiApiKey = ?;
configurable string openAiApiVersion = ?;
configurable string openAiDeploymentId = ?;
configurable string openAiServiceUrl = ?;

configurable map<string[]> patientIdsToNodeIds = ?;
configurable string testKey = ?;

configurable string alfrescoApiUrl = os:getEnv("CHOREO_CONTENTMGTCONN_SERVICEURL");
configurable string consumerkey = os:getEnv("CHOREO_CONTENTMGTCONN_CONSUMERKEY");
configurable string consumersecret = os:getEnv("CHOREO_CONTENTMGTCONN_CONSUMERSECRET");
configurable string tokenurl = os:getEnv("CHOREO_CONTENTMGTCONN_TOKENURL");
configurable string choreoapikey = os:getEnv("CHOREO_CONTENTMGTCONN_APIKEY");