package-replace Cookbook
==========================

Replaces an older package with a newer package, where they would conflict if installed side by side.

Some packages such as php55 do not upgrade cleanly to php56 versions of packages due to them
not being marked as replacements in the package management system.

Warnings - Before you use this cookbook
---------------------------------------

Thought should be given to what packages are going to be replaced and their replacement(s).

For example, an upgrade of MySQL/MariaDB/Percona server packages could mean data loss. This is due to needing to run
`mysql_upgrade` after the package has been replaced.

So, take precautions and back up your data immediately prior to upgrading the packages!

Better yet, start from a new server and import the data from a recent database dump, instead of risking an upgrade.

If upgrading a "safer" set of packages, say "php55" to "php56", it's possible that the replacement
will miss some packages that were previously installed but are not any longer.

Ensure you test out an upgrade elsewhere, such as in test-kitchen or a pipeline server, before performing the upgrade on
production.

Do some checks before and after chef runs the upgrade, for instance:

    rpm -qa | grep php | sort -n > before.txt
    # run chef
    rpm -qa | grep php | sort -n > after.txt
    diff before.txt after.txt

It's also possible that the act of replacing a package will disable any associated services, so the usage of this
cookbook (whether by LWRP in your own cookbook, or the default recipe being included in the runlist) should be
fairly high up the runlist order.
Especially before the usual cookbook that installs these services/packages ("recipe[php]" or "recipe[mysql]",
for example) as the cookbooks will ensure the right services get set to start at boot.

How to use this cookbook
------------------------

There are two methods of using this cookbook:

1. The `package_replace_replacement` LWRP can be used from your own cookbooks.
2. Provide the correct configuration to the `default` recipe.

Either approach can make use of two methods:

1. Use of yum-plugin-replace to replace a package where they both share the same base name - strategy `yum_replace`.
2. Use of yum shell to replace a package with another in the same yum transaction - strategy `yum_shell`.

### Replacing a package with yum-plugin-replace

Let's try to replace the current version of php that is installed with PHP 5.6 from Webtatic (where yum-webtatic is in the runlist already):

#### Using the LWRP

```ruby
package_replace_via_plugin 'php' do
  from_packages [
    'php-common',
    'php54-common',
    'php54u-common',
    'php54w-common',
    'php55-common',
    'php55u-common',
    'php55w-common'
  ]
  to_package 'php56w-common'
  strategy 'yum_replace'
  notifications {
    'service[php-fpm]' => 'restart'
  }
  action :install
end
```

#### Using the default recipe

Provide the following configuration and use `package-replace::default`:

```json
{
  "php": {
    "replace_packages": [
      "php-common",
      "php54-common",
      "php54w-common",
      "php54u-common",
      "php55-common",
      "php55w-common",
      "php55u-common"
    ],
    "replace_package_target": "php56w-common"
  },
  "package_replacements": {
    "php": {
      "enabled": true,
      "from": "replace_packages",
      "strategy": "yum_replace",
      "notifications": {
        "service[php-fpm]": "restart"
      },
      "to": "replace_package_target"
    }
  }
}
```

### Replacing a package with yum shell

Let's try to replace the current version of mysql-libs that is installed with MySQL 5.5 from Webtatic (where yum-webtatic is in the runlist already):

#### Using the LWRP

```ruby
package_replace_via_shell 'mysql-libs' do
  from_packages [
    'mysql-libs'
  ]
  to_packages [
    'mysql55w-libs',
    'libmysqlclient16'
  ]
  strategy 'yum_shell'
  notifications {
    'service[mysqld]' => 'restart'
  }
  action :install
end
```

#### Using the default recipe

Provide the following configuration and use `package-replace::default`:

```json
{
  "mysql-libs": {
    "replace_packages": [
      "mysql-libs"
    ],
    "replace_package_targets": [
      "mysql55w-libs",
      "libmysqlclient16"
    ]
  },
  "package_replacements": {
    "mysql-libs": {
      "enabled": true,
      "strategy": "yum_shell",
      "from": "replace_packages",
      "to": "replace_package_targets",
      "notifications": {
        "service[mysqld]": "restart"
      }
    }
  }
}
```

### LWRPs

#### package_replace_via_plugin

Attributes:
<table>
  <thead>
    <tr>
      <th>Attribute</th>
      <th>Description</th>
      <th>Example</th>
      <th>Default</th>
    </tr>
  </thead>

  <tbody>
    <tr>
      <td>type</td>
      <td>Name of the replacement operation</td>
      <td><tt>php</tt></td>
      <td><tt></tt></td>
    </tr>
    <tr>
      <td>from_packages</td>
      <td>Array of package names to replace if present</td>
      <td><tt>['test', 'test2']</tt></td>
      <td><tt>[]</tt></td>
    </tr>
    <tr>
      <td>to_package</td>
      <td>The single package name to replace a matched package with</td>
      <td><tt>test3</tt></td>
      <td><tt></tt></td>
    </tr>
    <tr>
      <td>notifications</td>
      <td>Hash of chef resource IDs to action to take. Multiple entries allowed</td>
      <td><tt>{"service[test]": "restart"}</tt></td>
      <td><tt>{}</tt></td>
    </tr>
  </tbody>
</table>


#### package_replace_via_shell

Attributes:
<table>
  <thead>
    <tr>
      <th>Attribute</th>
      <th>Description</th>
      <th>Example</th>
      <th>Default</th>
    </tr>
  </thead>

  <tbody>
    <tr>
      <td>type</td>
      <td>Name of the replacement operation</td>
      <td><tt>php</tt></td>
      <td><tt></tt></td>
    </tr>
    <tr>
      <td>from_packages</td>
      <td>Array of package names to replace if present</td>
      <td><tt>['test', 'test2']</tt></td>
      <td><tt>[]</tt></td>
    </tr>
    <tr>
      <td>to_packages</td>
      <td>Potentially multiple package names to replace a matched package with</td>
      <td><tt>['test3', 'test4']</tt></td>
      <td><tt>[]</tt></td>
    </tr>
    <tr>
      <td>notifications</td>
      <td>Hash of chef resource IDs to action to take. Multiple entries allowed</td>
      <td><tt>{"service[test]": "restart"}</tt></td>
      <td><tt>{}</tt></td>
    </tr>
  </tbody>
</table>

Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

Testing
-------

We use the following testing tools on this project, which can be installed by running `bundle install`.
These will all run when you perform `bundle exec rake test`, however if you wish to know how to run them individually,
they are listed below.

1. RSpec/ChefSpec for spec style TDD: `bundle exec rspec`
2. Test Kitchen for TDD and testing out individual recipes on a test Virtual Machine: `bundle exec kitchen test`
3. Foodcritic to catch Chef specific style/correctness errors: `bundle exec foodcritic . -f any -C`
4. Rubocop to catch Ruby style "offenses": `bundle exec rubocop`


Supermarket share
-----------------

[stove](http://sethvargo.github.io/stove/) is used to create git tags and
publish the cookbook on supermarket.chef.io.

To tag/publish you need to be a contributor to the cookbook on Supermarket and
run:

```
$ stove login --username <your username> --key ~/.chef/<your username>.pem
$ rake publish
```

It will take the version defined in metadata.rb, create a tag, and push the
cookbook to https://supermarket.chef.io/cookbooks/package-replace


License and Authors
-------------------
- Author:: Kieren Evans
- Author:: Andy Thompson

```text
Copyright:: 2016 Inviqa UK LTD

See LICENSE file
```
