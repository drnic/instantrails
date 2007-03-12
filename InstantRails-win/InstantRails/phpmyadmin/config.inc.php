<?php

// $Id: config.inc.php$

if (!isset($old_error_reporting)) {
  error_reporting(E_ALL);
  @ini_set('display_errors', 1);
}

$cfg['blowfish_secret'] = 'Re4l secr3ts st4y for3ver'; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */

/* Authentication type */
$cfg['Servers'][1]['auth_type'] = 'config';
/* Server parameters */
$cfg['Servers'][1]['host'] = 'localhost';
$cfg['Servers'][1]['connect_type'] = 'tcp';
$cfg['Servers'][1]['compress'] = false;
/* Select mysqli if your server has it */
$cfg['Servers'][1]['extension'] = 'mysql';
/* User for advanced features */
$cfg['Servers'][1]['controluser'] = 'root';
$cfg['Servers'][1]['controlpass'] = '';

/* Advanced phpMyAdmin features
 *
 * Uncomment following lines if you use PHPMyAdmin tables.
 * For table creation just run scripts/create_tables.sql.
 *
 */

// $cfg['Servers'][1]['pmadb'] = 'phpmyadmin';
// $cfg['Servers'][1]['bookmarktable'] = 'pma_bookmark';
// $cfg['Servers'][1]['relation'] = 'pma_relation';
// $cfg['Servers'][1]['table_info'] = 'pma_table_info';
// $cfg['Servers'][1]['table_coords'] = 'pma_table_coords';
// $cfg['Servers'][1]['pdf_pages'] = 'pma_pdf_pages';
// $cfg['Servers'][1]['column_info'] = 'pma_column_info';
// $cfg['Servers'][1]['history'] = 'pma_history';
// $cfg['Servers'][1]['designer_coords'] = 'pma_designer_coords';

// local configuration
$cfg['Servers'][1]['user'] = 'root';
$cfg['Servers'][1]['password'] = '';

$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
?>
