.. default-role:: code

===========================================
Database Testing
===========================================

| By: Randy Syring
| Twitter: @RandySyring
| Email: randy.syring@level12.io
| Slides: https://github.com/rsyring/bookorders
| Demo: https://github.com/rsyring/db-testing-slides

Let's Talk
==========

- This presentation is mostly about concepts, not detailed code.
- I like discussion & feedback.
- I will likely have extra time, so please ask questions.
- It's great if I don't know something, don't be afraid to ask!

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

Assets or Liabilities?
======================

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

.. code-block:: bash

    $ git clone https://github.com/rsyring/bookorders example
    $ cd example/
    $ tox
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
- We use a wheelhouse (https://pypi.python.org/pypi/Wheelhouse).
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

Database is recreated every time tests are ran::

    # https://github.com/level12/keg/blob/master/keg/db/__init__.py
    class DatabaseManager(object):

        def init_events(self):
            testing_run_start.connect(self.on_testing_start, sender=self.app)

        def on_testing_start(self, app):
            self.db_init_with_clear()

        def db_init_with_clear(self):
            self.db_clear()
            self.prep_empty()
            self.db_init()

.. nextslide::

Tests are responsible for making sure DB is in the required state::

    class TestOrdersCrud(object):

        def setup(self):
            """ py.test will run this before every test
                method in the class """
            Order.delete_all()

        def test_add_order(self):
            OrderCrud.add_order('...')
            assert Order.query.count() == 1

.. nextslide::

Test prep can be done at the test, class, or module level::

    def setup_module(module):
        Publisher.delete_all()

    class TestBookEntity(object):

        @classmethod
        def setup_class(self):
            cls.author = Author.testing_create()

        def setup(self):
            Book.delete_all()

        def test_books_author(self):
            book = Book.testing_create(author=self.author)
            assert book.author is self.author
            assert Book.query.count() == 0

Idempotent: Test Cleanup is OK
===================================

I prefer data setup as part of the test prep phase...but::

    user_id = None
    def setup_module(module):
        global user_id
        user_id = User.testing_create().id

    class TestOrdersCrud(object):
        def test_listing(self):
            Order.testing_create()
            resp = app.get('/orders/list', user_id=user_id)
            assert resp.pyquery('table td').length == 1

    class TestPublishersCrud(object):
        def test_listing(self):
            Publisher.testing_create()
            resp = app.get('/publisher/list', user_id=user_id)
            assert resp.pyquery('table td').length == 1

.. nextslide::

.. code-block:: python

    # setup_method() and other CrudTests are above.

    class TestUsersCrud(object):
        def test_delete_all(self):
            resp = app.get('/users/delete?all=1', user_id=user_id)
            assert User.query.count() == 0

So, what's going to happen now?

.. nextslide::

This test needs to do some cleanup to be a good citizen::

    class TestUsersCrud(object):
        @classmethod
        def class_teardown(cls):
            """ restore assumptions of other tests """
            global user_id
            user_id = User.testing_create().id

        def test_delete_all(self):
            UserCrud.select_all().delete()
            assert User.query.count() == 0


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

.. nextslide::

Fixtures
========

.. code-block:: yaml

    - table: authors
      records:
        - id: 1, first_name: William, last_name: Gibson

    - table: books
      records:
        - id: 1, title: Neuromancer, author_id: 1, published_date: 1984-07-01
        - id: 2, title: Count Zero, author_id: 1, published_date: 1986-03-01
        - id: 3, title: Neuromancer, author_id: 1, published_date: 1988-10-01

    - table: orders
      records:
        - ident: a, book_id: 1, status: pending
        - ident: b, book_id: 2, status: shipped
        - ident: c, book_id: 3, status: delivered

Factories
=========

Isn't this better?

.. code-block:: python

    Order.testing_create(status='pending')
    Order.testing_create(status='shipped')
    Order.testing_create(status='delivered')

Testing Create Method
=====================

We used to hand-code every `testing_create()` method::

    class Order(db.Model):
        @classmethod
        def testing_create(cls, **kwargs):
            ident = kwargs.get('ident') or randchars()
            ots = kwargs.get('order_timestamp') or datetime.now()
            book = kwargs.get('book') or Book.testing_create()
            # ... etc.
            return cls.add(ident, ots, book, ...)


This isn't hard, but magic is better.

.. nextslide::

::

    class SurchargeRate(db.Model, MethodsMixin):
        id = sa.Column(sa.ForeignKey(Action.id, ondelete='cascade'), primary_key=True)
        table = sa.Column(sa.String(2), nullable=False)
        card_plan = sa.Column(sa.String(4), nullable=False)
        charge_type = sa.Column(sa.String(4), nullable=False)
        combine_code = sa.Column(sa.String(10), nullable=False)
        description = sa.Column(sa.String(39), nullable=False)
        # SNIP...four more columns in real life

        # hierarchy relationship
        hierarchy_id = sa.Column(sa.ForeignKey(Hierarchy.id, ondelete='cascade'), nullable=False)
        hierarchy = saorm.relationship(Hierarchy, lazy='joined')

        @classmethod
        def testing_create(cls, **kwargs):
            if 'hierarchy' not in kwargs and 'hierarchy_id' not in kwargs:
                kwargs['hierarchy'] = Hierarchy.testing_create(_commit=False)
            return super().testing_create(**kwargs)

.. nextslide::

See GitHub for `testing_create()` definition.


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

Adding id and timestamp columns using mixins::

    class DefaultColsMixin(object):
        id = sa.Column(sa.Integer, primary_key=True)
        created_utc = sa.Column(ArrowType, nullable=False,
            default=arrow.now, server_default=utcnow())
        updated_utc = sa.Column(ArrowType, nullable=False,
            default=arrow.now, onupdate=arrow.now, server_default=utcnow())

.. nextslide::

Using a base test class (on GitHub)::

    class TestSurchargeRate(EntityBase):
        entity_cls = ents.SurchargeRate
        delete_all_on = 'setup'
        column_checks = [
            ColumnCheck('table'),
            ColumnCheck('card_plan'),
            ColumnCheck('charge_type'),
            ColumnCheck('combine_code'),
            ColumnCheck('description'),
            ColumnCheck('pi_apply_type'),
            ColumnCheck('pi_rate'),
            ColumnCheck('pct_apply_type'),
            ColumnCheck('pct_rate'),
            ColumnCheck('hiearchy_id', fk='actions.id'),
        ]


Patterns to Enforce
===================

- Checking nulls: SA default is NULL
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


