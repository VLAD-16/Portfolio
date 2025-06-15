<?php
define( 'WP_CACHE', true );

/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the website, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'my-portfolio-git' );

/** Database username */
define( 'DB_USER', 'adminroot' );

/** Database password */
define( 'DB_PASSWORD', 'Asd456!' );

/** Database hostname */
define( 'DB_HOST', 'localhost' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'W,PpD)h+f KSqrL&l!)z3Np%LL{I@>[BpgV-gyJGcTF*QBr9FJx$t|7FYJZ_0$Ns' );
define( 'SECURE_AUTH_KEY',  'MeR@KJzzW|hAg=)-x=1i3k%.8r|ABfg<g|z6g NOeHW{s<g)k#gGdaGyzOD0xOrP' );
define( 'LOGGED_IN_KEY',    'Q/y~aNzY6}w)Gu3{qI.)C27fqv<sA*m.wKR/7^A~__8USW4k_nEgP5[j!{3J5(?g' );
define( 'NONCE_KEY',        'Y%U>eP?YfJ3.`%:aq<c.!%=L [ut}]VfmjM~/Ur+LzU#e5mJTXqx;kQp?!JhpKy2' );
define( 'AUTH_SALT',        '+J`Jd]gn %Q$GJ8Z~o7Q?iL94JxNyi.~9<wzJ%egw0SdI=&VQ6+8psCBTFbDC;ZL' );
define( 'SECURE_AUTH_SALT', 'xtbZZv.Jc4ZAHNR7d~kWUVFl_+2AIxHBg%F,ijX!y<Q|?!9H>r4_|Qf3Rhqdy)K4' );
define( 'LOGGED_IN_SALT',   'kKh[y< 6Kh-ATD3Ou%UFs34>y.}+^p,k5{2M:7,,9M90Gy{O:O%)I3el9rV619r=' );
define( 'NONCE_SALT',       'IkRi1YvEQ9@OCV`y8t*jVa<,&ILeYy.~sfPu0UL.k[Z)U miD<}6ZB2LZf;0:BA#' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 *
 * At the installation time, database tables are created with the specified prefix.
 * Changing this value after WordPress is installed will make your site think
 * it has not been installed.
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/#table-prefix
 */
$table_prefix = 'gvs_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/
 */
define( 'WP_DEBUG', false );

/* Add any custom values between this line and the "stop editing" line. */



/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
