# Vagrant WordPress

Use [Vagrant](http://www.vagrantup.com/) to develop your WordPress plugins, themes and websites.

## What

When you bring the virtual machine up, you will have a Fedora based server running WordPress on the IP address specified in the `Vagrantfile`. The website can be accessed through the URL defined in the HOME\_URL variable that appearis in `vagrant-bootstrap.sh`.

If you plan to write unit tests (and you should), you would like to know that the server comes with PHPUnit, Phake and XDebug installed and ready to use. There are `phpunit.xml` and `.travis.yml` files already included in the project. All you have to do is write some tests using WordPress testing framework.

The server also has WP-CLI installed to facilitate WordPress.

## How

1. Get a copy of this repository:

    ```bash
    git clone https://github.com/wvega/vagrant-wordpress.git
    ```

2. Update the name of the base box in the `Vagrantfile`. The box is expected to be based on Fedora. The current version was tested in Fedora 19.
3. Change the name of the blog, admin email address and website url in `vagrant-bootstrap.sh` file.
4. Start your virtual machine:

    ```bash
    vagrant up
    ```

If you are working on a whole WordPress website and you want to keep all files under version control, you may want to remove `wordpress` directory from `.gitignore`.
