# Brainstorming

This file is used to document your thoughts, approaches and research conducted across all tasks in the Technical Assessment.

## Firmware

## Spyder

## Cloud
### Overview of Implementation ###
1. Weather station transmits data via MQTT to AWS IoT Core 
2. Data is processed through AWS IoT rule and routed to multiple destinations 
3. Real time data ingested by a weather streaming service deployed in ECS fargate 
4. Data stored in DynamoDB weather table for structured queries and S3 for long-term storage
5. Users (ie. Engineers) can access the processed weather data through the Amplify hosted UI via an API Gateway
6. Terraform for provisioning infrastructure
7. AWS SNS for real time alerts that will be sent to engineers at the racetrack if dangerous weather conditions are detected, enabling near-instant decision making to adjust race strategy or tire selection. This is also more convenient as compared to constantly querying the database/API. 
8. Two-way connection of weather streaming cluster to Redis to allow for efficient data retrieval and processing 

### Architecture Updates + Justifications ###
* Added a new ECS cluster, weather-streaming, for weather data ingestion. I decided to do this instead of
integrating it with an existing ECS cluster so as to isolate different responsibilities, since existing clusters 
like streaming-service and car-gateway-service currently handle vehicle telemetry, which has different data processing needs. Additionally, it allows the weather system to be scaled based on incoming weather data volume, ensuring better performance in the
long-run. Having a different cluster also makes it easier to monitor/debug weather data ingestion issues. 

* Usage of MQTT to transmit data: Decided on using MQTT instead of HTTP because it's optimal for real time and low latency communication, making it suitable for IoT based data ingestion. Additionally, it has connection persistance, meaning that it ensures
reliable delivery of sensor data even if network conditions are unstable. Furthermore, MQTT is also lightweight, and as such it will minimise bandwidth usage and reduce AWS IoT core costs.

* Regarding security, identity access management (IAM) policies should be implemented (if they haven't already been implemented) to 
ensure secure data access and service permissions. Additionally, with S3, the weather data logs that are stored are encrypted with AES-256, ensuring security. Moreover, MQTT has TLS encryption, ensuring secure data transmissions from the local weather station, preventing man in the middle (MITM) attacks and protects data integrity.  

* I decided to leverage existing AWS infrastructure by adding a few new components (eg. AWS IoT, AWS SNS, new ECS cluster), instead of building a completely new system since it would be significantly cheaper to utilise an existing system. I also utilised Redis for short-term data to avoid overloading DynamoDB with queries and reducing database costs. Additionally, since AWS IoT core handles MQTT messaging without needing dedicated servers, this also reduces maintenance/operational costs. 

### Role of added AWS Components in the Architecture ###
* AWS IoT Core (MQTT): Manages incoming weather data streams from the weather station
* AWS IoT Rule: Routes data from IoT Core to other AWS services (ie. DynamoDB, S3, ECS cluster)
* DynamoDB Weather Table: Stores structured weather data that can be quickly retrieved and analysed 
* S3 for Weather Data Logs: Storage of raw weather logs for long-term reference which could possibly be used for machine learning projects that may enhance performance during future races
* ECS Fargate: Processes real time weather data and makes it available to the race team
* API Gateway: Exposes weather data to the Amplify hosted UI
* Amplify Hosted UI: Will display real time and historical weather data for the engineers





