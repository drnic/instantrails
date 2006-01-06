<?php
/* $Id: phpinfo.php,v 2.3 2004/04/08 12:30:39 ne0x Exp $ */
// vim: expandtab sw=4 ts=4 sts=4:


/**
 * Gets core libraries and defines some variables
 */
require_once('./libraries/grab_globals.lib.php');
require_once('./libraries/common.lib.php');


/**
 * Displays PHP information
 */
$is_superuser = @PMA_DBI_try_query('USE mysql', $userlink);
if ($is_superuser || $cfg['ShowPhpInfo']) {
    phpinfo();
}
?>
