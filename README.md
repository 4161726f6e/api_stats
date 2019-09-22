# api_stats
A bash script which parses Windows API information from Cuckoo dynamic malware analysis reports in JSON format.

The script assumes that it is within a directory containing one or more JSON Cuckoo analysis reports. A unique list of Windows APIs will be generated and a CSV will be populated with the number of API calls per malware sample. All JSON reports will then be archived.
