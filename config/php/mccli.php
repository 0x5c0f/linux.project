<?php
    $memcache = new Memcache;
    $memcache->connect('10.0.2.25',11211) or die ("Could not nonnect");
    $memcache->set('key_0','hello,memcache');
    $get_value = $memcache->get('key_0');
    echo $get_value;
?>