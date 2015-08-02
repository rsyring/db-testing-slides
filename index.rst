.. default-role:: code

===========================================
Database Testing
===========================================

| By: Randy Syring
| Twitter: @RandySyring
| Email: randy.syring@level12.io
| GitHub: https://github.com/rsyring/

Slides & Demo
======================

.. rst-class:: build

- On GitHub (rsyring)...
- Eventually.
- If you really care, feel free to contact me.  :)


Let's Talk
==========

- This presentation is mostly about concepts, not detailed code.
- I like discussion & feedback.
- I will likely have extra time, so please ask questions.
- It's great if I don't know something, so ask!

Background & Assumptions
========================

* Building DB driven web apps for 10 years.
* In Python and w/ emphasis on testing for about 6 years.
* Not operating *"at scale"*.
* Biggest app: 5,275 tests across 207 tables in ~24 mins.
* I prefer to have the DB server involved when testing the DB.
* YMMV :)

Why Database Testing is Hard:
===================================

- Schema setup
- Shared state
- Lack of creativity (a.k.a. creating test data)
- Slow

What can you add?

Assets or Liabilities
=====================

The items just discussed are testing *liabilities*.

I like assets, not expenses or liabilities.  How about you?

Tests as Assets
===============

- Easy to setup: the less manual steps the better.
- Consistent: avoid environment surprises.
- Idempotent (?): avoid cross-test data contamination.
- Data creation made easy.
- Enforce good patterns: my memory is getting worse.
- Fast: quick iterations make testing enjoyable.
- Flexible: can roll w/ the punches when assumptions change (migrations)

Tests as Assets
===============

- **Easy to setup: the less manual steps the better.**
- Consistent: avoid environment surprises.
- Idempotent (?): avoid cross-test data contamination.
- Data creation made easy.
- Enforce good patterns: my memory is getting worse.
- Fast: quick iterations make testing enjoyable.
- Flexible: can roll w/ the punches when assumptions change (migrations)


Easy Setup
==========

Can't emphasize this enough, make it easy for people to run your tests!

Live example - assumptions:

- Ubuntu 14.04
- Python 3.4 (preferably older than 3.4.0)
- You have a PostgreSQL server available, preferably with user/password/db setup according to
  `bookorders.conf:TestProfile`
- You have a recent version of Tox installed at the system or user level.

No Hassle Clone to Testing
==========================

::

    $ git clone https://github.com/rsyring/bookorders example
    $ cd example/
    /example$ tox
    [...snip...]
    py34 runtests: commands[1] | py.test -q --tb native --strict --cov bookorders --cov-report xml --no-cov-on-fail --junit-xml=.pytests.xml bookorders
    ...............
    [...snip...]
    flake8 runtests: commands[0] | flake8 bookorders
    ______________________________________________ summary _______________________________________________
      py34: commands succeeded
      flake8: commands succeeded
      congratulations :)

What Makes This Possible
========================

- We can make some assumptions about the environment.
- We have a convention about the default DB connection, but this is easily configured.
- We use a wheelhouse.
- All tests must be ran w/ Tox.
- This is all closely tied to our CI environment.

If you aren't doing something like this, why?

Tests as Assets
===============

- Easy to setup: the less manual steps the better.
- **Consistent: avoid environment surprises.**
- Idempotent (?): avoid cross-test data contamination.
- Data creation made easy.
- Enforce good patterns: my memory is getting worse.
- Fast: quick iterations make testing enjoyable.
- Flexible: can roll w/ the punches when assumptions change (migrations)


Consistency
===========

- Everyone's tests should pass or fail the same.
- How are you managing your library versions?

Tests as Assets
===============

- Easy to setup: the less manual steps the better.
- Consistent: avoid environment surprises.
- **Idempotent (?): avoid cross-test data contamination.**
- Data creation made easy.
- Enforce good patterns: my memory is getting worse.
- Fast: quick iterations make testing enjoyable.
- Flexible: can roll w/ the punches when assumptions change (migrations)


Idempotent: Test Prep
======================

Avoiding cross-test data contamination:

- Database is recreated every time tests are ran.
- Tests are responsible for making sure DB is in the required state.
- Test prep can be done at the test, class, or module level.

Idempotent: Test Cleanup is OK Too
===================================

- I prefer db setup as part of the test prep phase.
- But, let's consider a scenario involving user records.

Tests as Assets
===============

- Easy to setup: the less manual steps the better.
- Consistent: avoid environment surprises.
- Idempotent (?): avoid cross-test data contamination.
- **Data creation made easy.**
- Enforce good patterns: my memory is getting worse.
- Fast: quick iterations make testing enjoyable.
- Flexible: can roll w/ the punches when assumptions change (migrations)


Data Creation
=============

.. rst-class:: build

- Fixtures or factories?
- Anyone use fixtures?
- I prefer factories.
- Roll your own, it's not hard.
- Use magic to create your data.

Tests as Assets
===============

- Easy to setup: the less manual steps the better.
- Consistent: avoid environment surprises.
- Idempotent (?): avoid cross-test data contamination.
- Data creation made easy.
- **Enforce good patterns: my memory is getting worse.**
- Fast: quick iterations make testing enjoyable.
- Flexible: can roll w/ the punches when assumptions change (migrations)


Enforcing Good Patterns
=======================

- nulls: SA default is NULL
- unique columns & multi-column unique constraints
- foreign key cascades
- relationship cascades
- created and updated timestamp columns
- utc vs non-utc timestamps
- add & count record
- make sure all columns have been tested

Tests as Assets
===============

- Easy to setup: the less manual steps the better.
- Consistent: avoid environment surprises.
- Idempotent (?): avoid cross-test data contamination.
- Data creation made easy.
- Enforce good patterns: my memory is getting worse.
- **Fast: quick iterations make testing enjoyable.**
- Flexible: can roll w/ the punches when assumptions change (migrations)


Speed: As Fast as Reasonable
============================

Don't do premature optimization!  (example)

.. rst-class:: build

- Avoid DB round trips when possible (CSV of user emails)
- Creating testing objects without committing or flushing to the DB.
- Testing the configuration, not the execution (nullability & FK)
- Knowing when to commit (nested objects)
- Be careful of network/vm issues that can slow data connections (dev example).
- Maybe test with in-memory SQLite (watch our for foreign key, data type issues)
- Run only the tests you need, follow the inside-out pattern.
- Parallelize your tests.

Tests as Assets
===============

- Easy to setup: the less manual steps the better.
- Consistent: avoid environment surprises.
- Idempotent (?): avoid cross-test data contamination.
- Data creation made easy.
- Enforce good patterns: my memory is getting worse.
- Fast: quick iterations make testing enjoyable.
- **Flexible: can roll w/ the punches when assumptions change (migrations)**


Flexibility: Migrations
=======================

Migrations break many of the assumptions we have made.  Let's consider a migration that:

- Creates a `user_emails` table and migrates `users.email` to said table
- Removes `users.email`
- Searches users email and replaces "#" with "@"

Migrations: Current Production Schema
=====================================

- By the time you write these tests, your model reflects the new configuration.
- You will need a way to recreate the schema as it existed.
- You may want to isolate your migration tests, they are not long-term assets.

Migration: Testing Workflow
===========================

.. rst-class:: build

- Get the old schema loaded
- Run Phase I of the migration (creating new schema)
- Load data and run tests that verify data migrations (using SQL or Automap)
- Run Phase II of the migration (cleanup old schema)
- Run tests to verify schema cleanup (SQL)
- Run tests to verify migration that didn't depend on old schema (current Entities)

Thanks & Plug
======================

Thanks for attending!


