                   Instant Rails Readme
                   ====================

Instant Rails is a one-stop Rails runtime solution containing Ruby, Rails,
Apache, and MySQL, all preconfigured and ready to run. No installer, you
simply drop it into the directory of your choice and run it. It does not
modify your system environment.

This release of Instant Rails for Windows, but there are plans for ports
to Linux, BSD, and OSX. See the Release Notes for a list of everything
included in Instant Rails (including their version numbers). Install and
Verify Instant Rails

Instant Rails includes the full source code of the cookbook application
developed in the [Rolling with Ruby on Rails] tutorial. Once you have
installed Instant Rails, you can verify that everything is working properly
by running this cookbook application.

Upgrading
=========

If you have installed a previous version of Instant Rails, see the file
"How-to-upgrade.txt" for instructions on how to upgrade you installation
while retaining your data and cutomizations.

Install & Verify
================

Follow these steps to install Instant Rails and verify that it is working 
properly:

    * Download and unzip the Instant Rails zip file.

    * Make sure there are no space characters in the installation
      path, and then start InstantRails.exe.

    * Instant Rails will detect that it is being started from a new
      directory and ask if you want to have it update the paths in the
      all of the configuration files... Just say yes.

    * Click on the I button to drop down the main menu and select 
      Configure > Windows Hosts file.

    * In the editor that pops up, add this line to the end of the file:

         127.0.0.1   www.mycookbook.com

    * Save the change and exit the editor.

    * In the main menu, select Rails Applications > Manage Rails Applications...

    * Check the checkbox next to the cookbook application.

    * Click on the "Start with Mongrel" button.

    * Once the Mongrel server says "Mongrel available at 0.0.0.0:3001", open 
      our browser and go to:

      http://www.mycookbook.com/

You should now be using a running Rails application! Poke around in the menus 
to see what's there.
