#!/bin/bash

# Generate a list of APIs found in Cuckoo JSON reports
echo "Discovering APIs..."
grep -h '"api":' *.json >> api_list.txt


# Remove unwanted text from list of APIs

# Remove "api":
sed 's!"api":!!g' api_list.txt > temp && mv temp api_list.txt
# Remove trailing comma
sed 's/,//g' api_list.txt > temp && mv temp api_list.txt
# Remove enclosing double quote pairs
sed 's!"!!g' api_list.txt > temp && mv temp api_list.txt
# Remove whitespace
sed 's/^ *//g' api_list.txt > temp && mv temp api_list.txt


# Generate list of unique API calls
cat api_list.txt | sort | uniq > temp && mv temp api_list.txt


# Generate csv containing every match for each unique api call for every json file
# Since it takes a while, include a process indicator
echo "Processing JSON files. This may take a while."
for filename in *.json; do while read l; do grep -c "$l" $filename | awk '{print}' OFS=, >> "${filename}.csv" ; done < api_list.txt ; done &
pid=$! # Process Id of the previous running command
while kill -0 $pid 2>/dev/null
do
  echo -n .
  sleep 2
done

# Transpose csv files to allow for concat by row versus column
for filename in *.json.csv; do tr '\n' , < $filename > temp && mv temp $filename; done


# Add file name of each csv to a new column at the beginning of each csv file
for file in *.json.csv; do awk '{print FILENAME (NF?",":"") $0}' $file > temp && mv temp $file; done


# Concatenate all csv files into one
printf "\nCreating report...\n"
for filename in *.json.csv; do (cat "${filename}"; echo) >> report.csv; done


# Remove file extension from filename identifiers
sed 's/.json.csv//g' report.csv > temp && mv temp report.csv


# Add header to csv with API names
tr '\n' , < api_list.txt > header.csv
# Remove whitespace
sed 's/ *,/,/g' header.csv > temp && mv temp header.csv

# Add one blank column to header, add newline at end of header
{ cat header.csv; echo "," ; } > temp && mv temp header.csv
{ echo -ne ","; cat header.csv; } > temp && mv temp header.csv
cat header.csv report.csv > temp && mv temp report.csv

# Remove blank rows
sed '/^$/d' report.csv > temp && mv temp report.csv

# Compress processed JSON files and write to log file
echo "Archiving JSON files..."
currentDate=`date +"%m%d%Y_%H%M"`
tar -czf $currentDate.tar.gz ./*.json
ls -t *.gz | head -1 >> processed.log
ls *.json >> processed.log
printf "\n\n" >> processed.log

# housekeeping
rm *.json
rm *.json.csv
rm header.csv
mv report.csv $currentDate.report.csv
rm api_list.txt
echo "Done."