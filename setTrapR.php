<?php

include ('config.php');
#   class MyDB extends SQLite3 {
#      function __construct() {
#         $this->open('info.db');
#      }
#   }

$COMMUNITY=$_GET['community'];
$IP=$_GET['ip'];
$PORT=$_GET['port'];

   $db = new MyDB();
   $sql =<<<EOF
      CREATE TABLE GET
      (
      COMMUNITY     TEXT    NOT NULL,
      IP            INT     NOT NULL,
      PORT          INT     NOT NULL);
EOF;
$ret = $db->exec($sql);
if (isset($_GET['community'])&&($_GET['ip'])&&($_GET['port']))
{
   $sql =<<<EOF
      INSERT INTO GET (COMMUNITY, IP, PORT)
      VALUES ('$COMMUNITY', '$IP', '$PORT');
EOF;
$ret = $db->exec($sql);

   echo "OK\n";
}
else{
     echo "FALSE\n";
}
   
$db->close();
?>
