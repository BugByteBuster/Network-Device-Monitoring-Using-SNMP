<?php
include ('config.php');
#   class MyDB extends SQLite3 {
#      function __construct() {
#         $this->open('info.db');
#      }
#   }
   
$db = new MyDB();

$sql =<<<EOF
      SELECT * from GET;
EOF;
$count = $db->querySingle("SELECT COUNT(*) as count FROM GET");
#echo $count;
if($count==0)
{
echo "FALSE";
}
else
{
$L =<<<EOF
   select * from GET order by rowid desc limit 1; 
EOF;
   $ret = $db->query($L);
   while($row = $ret->fetchArray(SQLITE3_ASSOC) ) {
        echo "$row[COMMUNITY]@$row[IP]:$row[PORT]";#@$row['IPADDRESS']:$row['PORT']";
}
}   
   $db->close();
?>
