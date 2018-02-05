<?php
include ('config.php'); 
#  class MyDB extends SQLite3 {
#     function __construct() {
#       $this->open('info.db');
#   }
#   }
   
$db = new MyDB();

$sql =<<<EOF
      SELECT * from INFORMATION;
EOF;
$count = $db->querySingle("SELECT COUNT(*) as count FROM INFORMATION");
#echo $count;
if($count==0)
{
echo "FALSE";
}
else
{
$L =<<<EOF
   select * from INFORMATION; 
EOF;
   $ret = $db->query($L);
   while($column = $ret->fetchArray(SQLITE3_ASSOC) ) {
       $p= $column['DeviceName']." | ".$column['CurrentStatus']." | ".$column['ReportTime']." | ".$column['OldStatus']." | ".$column['OldReportTime'];
       echo "$p \n";     
   }

}   
   $db->close();
?>
