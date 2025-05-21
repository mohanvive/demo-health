// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerinax/ai;

final ai:AzureOpenAiProvider _deduplicateAgentModel = check new (serviceUrl = openAiServiceUrl, apiKey = openAiApiKey, deploymentId = openAiDeploymentId, apiVersion = openAiApiVersion, temperature = 0.2);
final ai:Agent deduplicateAgent = check new (
    systemPrompt = {
        role: "CCDA document Summarization Assistant",
        instructions: string `
        You are expert in analyzing CCDA summaries. You will receive an array of JSON objects representing summarized CCDA in json format.

        **Your task**: Summarize this operative note for health insurance claim processing with focus on procedure performed, diagnoses, and surgeon details.
        - Provide the summary of the key details in plain text.`
    },
    memory = new ai:MessageWindowChatMemory(10), 
    model = _deduplicateAgentModel, 
    tools = []
);
