unzip -d files files.all.csv.zip
cd files/
for l in $(ls -1 *.csv)
do
  cat $l | grep -e '^./javavm/' -e '^./jdk/' -e '^./rdbms/' | grep -v -e '^./rdbms/log/' -e '^./rdbms/audit/' > $l.new
  mv $l.new $l
done
zip -9 -m files.csv.zip *.csv
cd ..
mv files/files.csv.zip ./
rmdir files/